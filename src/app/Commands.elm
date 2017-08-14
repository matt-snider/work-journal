module Commands exposing (..)

import Messages exposing (..)
import Models exposing (Task, Model)
import Json.Decode as Decode
import Json.Encode as Encode
import Array exposing (Array)
import Http

apiUrl = "http://localhost:3000/tasks"


getTasks : Cmd Msg
getTasks = Http.send Load
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
        request id = Http.request
            { method = "DELETE"
            , headers = []
            , url = apiUrl ++ "?id=eq." ++ toString (id)
            , body = Http.emptyBody
            , expect = Http.expectStringResponse (\x -> Ok ())
            , timeout = Nothing
            , withCredentials = False
            }
    in case task.id of
            Just id -> Http.send OnDelete (request id)
            Nothing -> Cmd.none

-- JSON encoders/decoders
tasksDecoder : Decode.Decoder (Array Task)
tasksDecoder = Decode.array taskDecoder


taskDecoder : Decode.Decoder Task
taskDecoder = Decode.map3 makeTask
    (Decode.at ["id"] (Decode.nullable Decode.int))
    (Decode.at ["description"] Decode.string)
    (Decode.at ["is_complete"] Decode.bool)


taskEncoder : Task -> Encode.Value
taskEncoder task =
    let
        start = case task.id of
            Just id -> [ ("id", Encode.int id) ]
            Nothing -> []
        end =
            [ ("description", (Encode.string task.description))
            , ("is_complete", (Encode.bool task.isComplete))
            ]
    in Encode.object (start ++ end)

-- Build a task without providing isEditing
makeTask : Maybe Int -> String -> Bool -> Task
makeTask a b c = Task a b c False
