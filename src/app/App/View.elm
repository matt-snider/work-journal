module App.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

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
        [ h1 [] [ text "Work Journal" ]
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
