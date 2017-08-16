module TaskList.View exposing (view)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode

import TaskList.Types exposing (..)
import Utils.Events exposing (onInputBlur)


view : Model -> Html Msg
view model =
    div []
    [ ul [] (List.map taskView (Array.toList model))
    ]


taskView : Task -> Html Msg
taskView task =
    div []
        [ input [ type_ "checkbox", onCheck (ToggleComplete task)  ]  []
        , maybeInput task
        , button [ onClick (Delete task) ] [ text "X" ]
        ]

-- TODO: react to enter as well
-- TODO: show updating indicator for isUpdating
maybeInput : Task -> Html Msg
maybeInput task =
    if task.isEditing == True then
        input [ placeholder "Enter a task", onInputBlur (DoneEdit task), value task.description ] []
    else
        span [ onClick (StartEdit task) ] [ text task.description ]
