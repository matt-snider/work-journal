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
    , is_complete : Bool
    }

type alias Model = Array.Array Task

model : Model
model = Array.empty


-- Update
type Msg
    = Add
    | EditDescription Int String
    | EditIsComplete  Int Bool
    | Delete Int
    | OnAdd (Result Http.Error (Maybe ApiError))
    | Load (Result Http.Error (Array.Array Task))


deleteItem : Int -> Model -> Model
deleteItem index model =
    let
        start = Array.slice 0 index model
        end   = Array.slice (index + 1) (Array.length model) model
    in
        Array.append start end


addItem : Model -> Model
addItem model =
    let
        newTask = Task Nothing "" False
    in
        Array.push newTask model


-- TODO: handle update failure in Nothing case
updateItem : Int -> Task -> Model -> Model
updateItem index newTask model = Array.set index newTask model


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- Add -> List.append [newTask] model
    Add -> (addItem model, Cmd.none)
    Delete index -> (deleteItem index model, Cmd.none)
    EditDescription index description ->
        let
            oldTask = Array.get index model
            updated = case oldTask of
                Just t -> { t | description = description }
                Nothing -> Task Nothing "" False
        in (updateItem index updated model, saveTask updated)
    EditIsComplete index isComplete ->
        let
            oldTask = Array.get index model
            updated = case oldTask of
                Just t -> { t | is_complete = isComplete }
                Nothing -> Task Nothing "" False
        in (updateItem index updated model, saveTask updated)
    Load (Ok tasks) -> (tasks, Cmd.none)
    Load (Err _) -> (model, Cmd.none)
    OnAdd (Ok _) -> (model, Cmd.none)
    OnAdd (Err err) -> (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)


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
    [ input [type_ "checkbox", onCheck (EditIsComplete index), checked ( t.is_complete)] []
    , input [placeholder "Enter a task", onInput (EditDescription index), value t.description ] []
    , button [ onClick (Delete index) ] [ text "X" ]
    ]


-- HTTP
apiUrl = "http://localhost:3000/tasks"

type alias ApiError = { message : String }

getTasks : Cmd Msg
getTasks = Http.send Load
    <| Http.get apiUrl tasksDecoder


-- Save a task (either new or existing with id)
-- Update this to use PATCH or we get 409 Conflict
saveTask : Task -> Cmd Msg
saveTask task =
    let
        (url, method) = case task.id  of
            Just id ->
                ( apiUrl ++ "?id=eq." ++ toString(id)
                , "PATCH"
                )
            Nothing -> (apiUrl, "POST")
        body = Http.jsonBody (taskEncoder task)
        request = Http.request
            { method = method
            , headers = []
            , url = url
            , body = body
            , expect = Http.expectJson apiErrorDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in
        Http.send OnAdd request



-- JSON encoders/decoders
tasksDecoder : Decode.Decoder (Array.Array Task)
tasksDecoder = Decode.array taskDecoder


taskDecoder : Decode.Decoder Task
taskDecoder = Decode.map3 Task
    (Decode.at ["id"] (Decode.nullable Decode.int))
    (Decode.at ["description"] Decode.string)
    (Decode.at ["is_complete"] Decode.bool)


taskEncoder : Task -> Encode.Value
taskEncoder task =
    let
        idEncoder = case task.id of
            Just id -> Encode.int id
            Nothing -> Encode.null
    in
        Encode.object
        [ ("id", idEncoder)
        , ("description", (Encode.string task.description))
        , ("is_complete", (Encode.bool task.is_complete))
        ]

-- Mismatched decoder
apiErrorDecoder : Decode.Decoder (Maybe ApiError)
apiErrorDecoder = Decode.map
    (Maybe.map ApiError)
    (Decode.maybe (Decode.field "message" Decode.string))
