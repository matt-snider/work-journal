import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http as Http
import Json.Decode as Decode
import Json.Encode as Encode
import Array
import Debug

main =
    Html.program
        { view = view
        , update = update
        , init = (model, getTasks)
        , subscriptions = (\x -> Sub.none)
        }


-- Model
type alias Task =
    { id          : Maybe Int
    , description : String
    , isComplete : Bool
    , isEditing  : Bool
    }

newTask : Task
newTask = Task Nothing "" False True

makeTask : Maybe Int -> String -> Bool -> Task
makeTask a b c = Task a b c False

type alias Model = Array.Array Task

model : Model
model = Array.empty


-- Update
type Msg
    = Add
    | EditDescription Int String
    | EditStatus  Int Bool
    | Delete Int
    | StartEdit Int
    | OnAdd (Result Http.Error Task)
    | OnSave (Result Http.Error Task)
    | OnDelete (Result Http.Error ())
    | Load (Result Http.Error (Array.Array Task))


deleteItem : Int -> Model -> (Model, Cmd Msg)
deleteItem index model =
    let
        start    = Array.slice 0 index model
        end      = Array.slice (index + 1) (Array.length model) model
        toDelete = Array.get index model
        command  = case toDelete of
            Just t  -> deleteTask t
            Nothing -> Cmd.none
    in (Array.append start end, command)


addItem : Model -> (Model, Cmd Msg)
addItem model = (model, saveTask newTask)


updateItem : Int -> Model -> (Task -> Task) -> (Model, Task)
updateItem index model updater =
    let updatedTask = Maybe.map updater (Array.get index model)
    in case updatedTask of
        Just t -> (Array.set index t model, t)
        Nothing -> (model, newTask)



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Add -> addItem model

    Delete index -> deleteItem index model

    EditDescription index description ->
        let (newModel, task) = updateItem index model (\t -> { t | description = description, isEditing = False})
        in (newModel, saveTask task)

    EditStatus index isComplete ->
        let (newModel, task) = updateItem index model (\t -> { t | isComplete = isComplete })
        in (newModel, saveTask task)

    StartEdit index ->
        let (newModel, task) = updateItem index model (\t -> { t | isEditing = True })
        in (newModel, Cmd.none)

    Load (Ok tasks) -> (tasks, Cmd.none)
    Load (Err _) -> (model, Cmd.none)
    OnAdd (Ok t) -> (Array.push {t | isEditing = True} model, Cmd.none)
    OnAdd (Err err) -> (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)
    OnSave (Ok _) -> (model, Cmd.none)
    OnSave (Err err) -> (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)
    OnDelete (Ok _) -> (model, Cmd.none)
    OnDelete (Err err) -> (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)


-- View
view : Model -> Html Msg
view model =
    div []
    [ h1 [] [ text "Work Journal" ]
    , ul [] (List.map listItem (Array.toIndexedList model))
    , button [ onClick Add ] [ text "Add" ]
    ]


listItem : (Int, Task) -> Html Msg
listItem (index, t) =
    li []
    [ input [type_ "checkbox", onCheck (EditStatus index), checked t.isComplete ] []
    , maybeInput t index
    , button [ onClick (Delete index) ] [ text "X" ]
    ]


onInputBlur : (String -> msg) -> Attribute msg
onInputBlur tagger =
    on "blur" (Decode.map tagger targetValue)


maybeInput : Task -> Int -> Html Msg
maybeInput task index =
    if task.isEditing == True then
        input [ placeholder "Enter a task", onInputBlur (EditDescription index), value task.description ] []
    else
        span [ onClick (StartEdit index) ] [ text task.description ]


-- HTTP
apiUrl = "http://localhost:3000/tasks"

type alias ApiError = { message : String }

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
tasksDecoder : Decode.Decoder (Array.Array Task)
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
