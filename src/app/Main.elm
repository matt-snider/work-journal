import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http as Http
import Json.Decode as Decode
import Array

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
    | Load (Result Http.Error (Array.Array Task))
    | Change Int String
    | Delete Int


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
updateItem : Int -> String -> Model -> Model
updateItem index newDescription model =
    let
        oldTask = Array.get index model
        updated = case oldTask of
            Just t -> { t | description = newDescription }
            Nothing -> Task Nothing "" False
    in
        Array.set index updated model


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -- Add -> List.append [newTask] model
    Add -> (addItem model, Cmd.none)
    Delete index -> (deleteItem index model, Cmd.none)
    Change index description -> (updateItem index description model, Cmd.none)
    Load (Ok tasks) -> (tasks, Cmd.none)
    Load (Err _) -> (model, Cmd.none)


-- View
view : Model -> Html Msg
view model =
    div []
    [ ul [] (List.map listItem (Array.toIndexedList model))
    , button [ onClick Add ] [ text "Add" ]
    ]

listItem : (Int, Task) -> Html Msg
listItem (index, t) =
    li []
    [ input [placeholder "Enter a task", onInput (Change index), value t.description ] []
    , button [ onClick (Delete index) ] [ text "X" ]
    ]


-- HTTP
getTasks : Cmd Msg
getTasks = Http.send Load
    <| Http.get "http://localhost:3000/tasks" tasksDecoder


tasksDecoder : Decode.Decoder (Array.Array Task)
tasksDecoder = Decode.array taskDecoder


taskDecoder : Decode.Decoder Task
taskDecoder = Decode.map3 Task
    (Decode.at ["id"] (Decode.nullable Decode.int))
    (Decode.at ["description"] Decode.string)
    (Decode.at ["is_complete"] Decode.bool)
