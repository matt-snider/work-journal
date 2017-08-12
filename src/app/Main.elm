import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List
import Array


main =
    Html.beginnerProgram { model = model, view = view, update = update }


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


update : Msg -> Model -> Model
update msg model =
  case msg of
    -- Add -> List.append [newTask] model
    Add -> addItem model
    Delete index -> deleteItem index model
    Change index description -> updateItem index description model


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
    [ input [placeholder t.description, onInput (Change index)] []
    , button [ onClick (Delete index) ] [ text "X" ]
    ]
