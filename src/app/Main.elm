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
    = Add
    | Delete Int

newTask : Task
newTask = Task Nothing "" False

update : Msg -> Model -> Model
update msg model =
  case msg of
    -- Add -> List.append [newTask] model
    Add -> model ++ [newTask]
    Delete index -> (List.take (index - 1) model) ++ (List.drop index model)


-- View
view : Model -> Html Msg
view model =
    div []
    [ ul [] (List.map listItem (List.indexedMap (,) model))
    , button [ onClick Add ] [ text "Add" ]
    ]

listItem : (Int, Task) -> Html Msg
listItem (index, t) =
    li []
    [ text t.description
    , button [ onClick (Delete index) ] [ text "X" ]
    ]
