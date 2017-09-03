module Utils.Api exposing
    ( Task
    , getTasks
    , createTask
    , updateTask
    , deleteTask
    )

import Array
import Http
import Json.Decode as Decode
import Json.Encode as Encode


{---------
 - TYPES -
 ---------}
type alias Task =
    { id          : Int
    , description : String
    , completed   : Bool
    , notes       : Array.Array String
    }


{-----------
 - Methods -
 -----------}
-- Notes regarding PostgREST backend:
--   - the headers Prefer & Accept ensure that the service
--     gives us back the inserted object, and that it unpacks
--     single element arrays.

-- TODO: this should come from a config file or env
apiUrl = "http://localhost:3000/tasks"

-- Get all tasks
getTasks : (Result Http.Error (Array.Array Task) -> msg) -> Cmd msg
getTasks cb =
    Http.send cb
        <| Http.get apiUrl tasksDecoder

-- Create a task
createTask : (Result Http.Error Task -> msg) -> String -> Cmd msg
createTask cb value =
    let
        request = Http.request
            { method = "POST"
            , headers =
                [ Http.header "Prefer" "return=representation"
                , Http.header "Accept" "application/vnd.pgrst.object+json"
                ]
            , url = apiUrl
            , body = Http.jsonBody (newTaskEncoder value)
            , expect = Http.expectJson taskDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in Http.send cb request

-- Update a task
updateTask : (Result Http.Error Task -> msg) -> Task -> Cmd msg
updateTask cb task =
    let
        request = Http.request
            { method = "PATCH"
            , headers =
                [ Http.header "Prefer" "return=representation"
                , Http.header "Accept" "application/vnd.pgrst.object+json"
                ]
            , url = apiUrl ++ "?id=eq." ++ toString(task.id)
            , body = Http.jsonBody (taskEncoder task)
            , expect = Http.expectJson taskDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in Http.send cb request

-- Delete a task
deleteTask : (Result Http.Error Task -> msg) -> Task -> Cmd msg
deleteTask cb task =
    let
        request = Http.request
            { method = "DELETE"
            , headers = []
            , url = apiUrl ++ "?id=eq." ++ toString (task.id)
            , body = Http.emptyBody
            , expect = Http.expectStringResponse (\x -> Ok task)
            , timeout = Nothing
            , withCredentials = False
            }
    in Http.send cb request


{--------
 - JSON -
 --------}
-- Decode multiple tasks
tasksDecoder : Decode.Decoder (Array.Array Task)
tasksDecoder = Decode.array taskDecoder

-- Decode single task
taskDecoder : Decode.Decoder Task
taskDecoder = Decode.map4 Task
    (Decode.at ["id"] Decode.int)
    (Decode.at ["description"] Decode.string)
    (Decode.at ["is_complete"] Decode.bool)
    (Decode.at ["notes"] (Decode.array Decode.string))

-- Encode task
taskEncoder : Task -> Encode.Value
taskEncoder task =
    Encode.object
        [ ("id", Encode.int task.id)
        , ("description", (Encode.string task.description))
        , ("is_complete", (Encode.bool task.completed))
        , ("notes", (Encode.array (Array.map Encode.string task.notes)))
        ]

-- Encode a new task (just the description)
newTaskEncoder : String -> Encode.Value
newTaskEncoder description =
    Encode.object
        [ ("description", (Encode.string description))
        , ("is_complete", (Encode.bool False))
        , ("notes", (Encode.array Array.empty))
        ]
