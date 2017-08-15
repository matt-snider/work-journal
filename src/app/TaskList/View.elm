module TaskList.View exposing (view)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode

import TaskList.Types exposing (..)


view : Model -> Html Msg
view model =
    div []
    [ ul [] (List.map listItem (Array.toIndexedList model))
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

