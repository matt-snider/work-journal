module App.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ui.Header

import App.Types exposing (..)
import TaskList.View


-- TODO: Add should happen onInputBlur or enter
view : Model -> Html Msg
view model =
    let
        taskListView =
            TaskList.View.view model.taskListModel
            |> Html.map TaskListMsg
    in
        div []
        [ Ui.Header.view
            [ Ui.Header.title
                { action = Nothing
                , target = "_self"
                , link = Nothing
                , text = "Work Journal"
                }
            ]

        , taskListView

        , input
            [ placeholder "Enter a task"
            , onInput EditNew
            , value model.newTaskDescription
            ]
            []

        , button
            [ onClick (Add model.newTaskDescription) ]
            [ text "Add" ]
        ]
