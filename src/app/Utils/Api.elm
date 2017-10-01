module Utils.Api exposing
    ( Task
    , getTasks
    , createTask
    , updateTask
    , deleteTask
    )

import Array
import Date
import Http
import Json.Decode as Decode
import Json.Encode as Encode

import Utils.Json exposing (decodeDate)


{---------
 - TYPES -
 ---------}
type alias Task =
    { id          : Int
    , description : String
    , completed   : Bool
    , ordering    : Int
    , date        : Date.Date
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
getTasks : (Result Http.Error (Array.Array Task) -> msg) -> Date.Date -> Cmd msg
getTasks cb date =
    let
        url = apiUrl ++ "?day=eq." ++ (dateToString date)
    in
        Http.send cb
            <| Http.get url tasksDecoder

-- Create a task
createTask : (Result Http.Error Task -> msg) -> String -> Date.Date -> Cmd msg
createTask cb value date =
    let
        request = Http.request
            { method = "POST"
            , headers =
                [ Http.header "Prefer" "return=representation"
                , Http.header "Accept" "application/vnd.pgrst.object+json"
                ]
            , url = apiUrl
            , body = Http.jsonBody (newTaskEncoder value date)
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
taskDecoder = Decode.map6 Task
    (Decode.at ["id"] Decode.int)
    (Decode.at ["description"] Decode.string)
    (Decode.at ["is_complete"] Decode.bool)
    (Decode.at ["ordering"] Decode.int)
    (Decode.at ["day"] decodeDate)
    (Decode.at ["notes"] (Decode.array Decode.string))

-- Encode task
taskEncoder : Task -> Encode.Value
taskEncoder task =
    Encode.object
        [ ("id", Encode.int task.id)
        , ("description", (Encode.string task.description))
        , ("is_complete", (Encode.bool task.completed))
        , ("ordering",    (Encode.int task.ordering))
        , ("day", Encode.string (dateToString task.date))
        , ("notes", (Encode.array (Array.map Encode.string task.notes)))
        ]


-- Encode a new task (just the description)
newTaskEncoder : String -> Date.Date -> Encode.Value
newTaskEncoder description date =
    Encode.object
        [ ("description", Encode.string description)
        , ("is_complete", Encode.bool False)
        , ("day", Encode.string (dateToString date))
        , ("notes", Encode.array Array.empty)
        ]


dateToString : Date.Date -> String
dateToString date =
    let
        month = toString (Date.month date)
        day   = toString (Date.day date)
        year  = toString (Date.year date)
    in
        month ++ " " ++ day ++ " " ++ year
