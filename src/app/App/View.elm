module App.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ui.Header
import Ui.Input
import Ui.Button

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

        , Ui.Input.view
            model.newTaskModel
            |> Html.map NewTaskMsg

        , Ui.Button.view
            (Add model.newTaskModel.value)
            { disabled = False
            , readonly = False
            , kind = "primary"
            , size = "medium"
            , text = "Add"
            }
        ]
