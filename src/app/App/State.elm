module App.State exposing (init, update, subscriptions)

import Array
import Debug

import TaskList.State
import TaskList.Types
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
            { taskListModel = taskListModel
            , isAddingNew   = False
            }
    in
        ( model
        , commands
        )


-- Subs
subscriptions : Model -> Sub Msg
subscriptions model =
    let
        taskListSub =
            TaskList.State.subscriptions model.taskListModel
    in
        Sub.batch
            [ Sub.map TaskListMsg taskListSub ]


-- Update
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    New ->
        ( { model | isAddingNew = True}
        , Cmd.none
        )

    Add description ->
        -- Pass off to handler below
        update (TaskListMsg (TaskList.Types.New description)) model

    TaskListMsg taskListMsg ->
        let
            ( newTaskListModel, command ) =
                TaskList.State.update taskListMsg model.taskListModel
        in
            ( { model | taskListModel = newTaskListModel }
            , Cmd.map TaskListMsg command
            )
