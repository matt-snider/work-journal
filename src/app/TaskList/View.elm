module TaskList.View exposing (view)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode

import TaskList.Types exposing (..)
import Utils.Events exposing (..)


view : Model -> Html Msg
view model =
    div []
    [ ul [] (List.map taskView (Array.toList model))
    ]


taskView : Task -> Html Msg
taskView task =
    div []
        [ input
            [ type_ "checkbox", onCheck (ToggleComplete task)  ]
            []
        , maybeInput task
        , button
            [ onClick (Delete task) ]
            [ text "X" ]
        ]

-- TODO: show updating indicator for isUpdating
-- TODO: when enter is pressed, blur also thrown
-- currently handling this in DoneEdit update hook
maybeInput : Task -> Html Msg
maybeInput task =
    if task.isEditing then
        div []
            [ input
                [ placeholder "Enter a task"
                , onInputBlur  (DoneEdit task)
                , onInputEnter (DoneEdit task)
                , value task.description
                ]
                []
            , maybeLoadingIndicator task
            ]
    else
        span
            [ onClick (StartEdit task) ]
            [ text task.description ]


maybeLoadingIndicator : Task -> Html Msg
maybeLoadingIndicator task =
    if task.isUpdating then
        img
            [ src "assets/loader.gif" ]
            []
    else
        span [] []
