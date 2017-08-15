module App.State exposing (init, update, subscriptions)

import Array
import Debug

import TaskList.State
import App.Types exposing (..)


-- Init
init : (Model, Cmd Msg)
init =
    let
        ( taskListModel, taskListCmd ) =
            TaskList.State.init

        commands = Cmd.batch
            [ Cmd.map TaskListMsg taskListCmd ]

        model =
            { tasks = taskListModel
            }
    in
        (model , commands)


-- Subs
subscriptions : Model -> Sub Msg
subscriptions model =
    let
        taskListSub =
            TaskList.State.subscriptions model.tasks
    in
        Sub.batch
            [ Sub.map TaskListMsg taskListSub ]


-- Update
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    TaskListMsg taskListMsg ->
        let
            ( newModel, command ) =
                TaskList.State.update taskListMsg model.tasks
        in
            ( { model | tasks = newModel }, Cmd.map TaskListMsg command )
