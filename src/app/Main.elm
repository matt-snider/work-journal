import Html exposing (Html, button, div, li, text, ul)
import Html.Events exposing (onClick)
import List

main =
    Html.beginnerProgram { model = model, view = view, update = update }

-- Model
type alias Task =
    { id          : Maybe Int
    , description : String
    , is_complete : Bool
    }
type alias Model = List Task

model : Model
model = []

-- Update
type Msg
    = Add Task
    | Delete Task

update : Msg -> Model -> Model
update msg model =
  case msg of
    Add    t -> List.append [t] model
    Delete t -> List.filter (\x -> x /= t) model


-- View
view : Model -> Html Msg
view model =
    div []
    [ ul [] (List.map listItem model)
    , button [ onClick (Add newTask) ] [ text "Add" ]
    ]

newTask : Task
newTask = Task Nothing "new" False

listItem : Task -> Html msg
listItem t =
    li [] [ text t.description ]
