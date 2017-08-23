module TaskList.Api exposing (..)

import Array
import Http
import Json.Decode as Decode
import Json.Encode as Encode

import TaskList.Types exposing (..)


-- This should come from a config file or env
apiUrl = "http://localhost:3000/tasks"

-- Get all tasks
getTasks : Cmd Msg
getTasks = Http.send OnLoad
    <| Http.get apiUrl tasksDecoder


-- Save a task (either new or existing with id)
-- The headers Prefer & Accept ensure that the service
-- gives us back the inserted object, and that it unpacks
-- single element arrays.
saveTask : Task -> Cmd Msg
saveTask task =
    let
        (url, method, msg) = case task.id  of
            Just id ->
                ( apiUrl ++ "?id=eq." ++ toString(id)
                , "PATCH"
                , OnSave
                )
            Nothing -> (apiUrl, "POST", OnAdd)
        body = Http.jsonBody (taskEncoder task)
        request = Http.request
            { method = method
            , headers =
                [ Http.header "Prefer" "return=representation"
                , Http.header "Accept" "application/vnd.pgrst.object+json"
                ]
            , url = url
            , body = body
            , expect = Http.expectJson taskDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in Http.send msg request


deleteTask : Task -> Cmd Msg
deleteTask task =
    let
        request tid = Http.request
            { method = "DELETE"
            , headers = []
            , url = apiUrl ++ "?id=eq." ++ toString (tid)
            , body = Http.emptyBody
            , expect = Http.expectStringResponse (\x -> Ok task)
            , timeout = Nothing
            , withCredentials = False
            }
    in case task.id of
            Just tid -> Http.send OnDelete (request tid)
            Nothing -> Cmd.none

-- JSON encoders/decoders
tasksDecoder : Decode.Decoder (Array.Array Task)
tasksDecoder = Decode.array taskDecoder


taskDecoder : Decode.Decoder Task
taskDecoder = Decode.map4 makeTask
    (Decode.at ["id"] Decode.int)
    (Decode.at ["description"] Decode.string)
    (Decode.at ["is_complete"] Decode.bool)
    (Decode.at ["notes"] (Decode.array noteDecoder))


taskEncoder : Task -> Encode.Value
taskEncoder task =
    let
        start = case task.id of
            Just id -> [ ("id", Encode.int id) ]
            Nothing -> []
        end =
            [ ("description", (Encode.string task.description))
            , ("is_complete", (Encode.bool task.isComplete))
            , ("notes", (Encode.array (Array.map noteEncoder task.notes)))
            ]
    in Encode.object (start ++ end)


noteDecoder : Decode.Decoder Note
noteDecoder = Decode.map2 makeNote
    (Decode.at ["id"] Decode.int)
    (Decode.at ["content"] Decode.string)


noteEncoder : Note -> Encode.Value
noteEncoder note =
    let
        start = case note.id of
            Just id -> [ ("id", Encode.int id) ]
            Nothing -> []
        end =
            [ ("content", (Encode.string note.content))]
    in Encode.object (start ++ end)


-- Build a task without providing isEditing
makeTask : Int -> String -> Bool -> Array.Array Note -> Task
makeTask tid description isComplete notes =
    { id          = Just tid
    , description = description
    , isComplete  = isComplete
    , notes       = notes
    , isEditing   = False
    , isUpdating  = False
    }


makeNote : Int -> String -> Note
makeNote nid content =
    { id      = Just nid
    , content = content
    }
