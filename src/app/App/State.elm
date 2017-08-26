module App.State exposing (init, update, subscriptions)

import Array
import Debug
import Ui.Input

import TaskList.State
import TaskList.Types
import App.Types exposing (..)


-- Init
init : (Model, Cmd Msg)
init =
    let
        ( taskListModel, taskListCmd ) =
            TaskList.State.init

        newTaskModel =
            Ui.Input.init ()
                |> Ui.Input.placeholder "Enter a task..."
    in
        ( { taskListModel = taskListModel
          , newTaskModel = newTaskModel
          }

        , Cmd.batch
            [ Cmd.map TaskListMsg taskListCmd ]
        )


-- Subs
subscriptions : Model -> Sub Msg
subscriptions model =
    let
        taskListSub =
            TaskList.State.subscriptions model.taskListModel
    in
        Sub.batch
            [ Sub.map TaskListMsg taskListSub
            , Ui.Input.onChange EditNew model.newTaskModel
            ]



-- Update
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Add description ->
        let
            ( newTaskModel, newTaskCmd ) =
                Ui.Input.setValue "" model.newTaskModel

            ( taskListModel, taskListCmd ) =
                TaskList.State.update
                    (TaskList.Types.New model.newTaskModel.value)
                    model.taskListModel
        in
            ( { model
              | newTaskModel  = newTaskModel
              , taskListModel = taskListModel
              }

            , Cmd.batch
                [ Cmd.map NewTaskMsg newTaskCmd
                , Cmd.map TaskListMsg taskListCmd
                ]
            )

    EditNew description ->
        let
            (newTaskModel, _) = Ui.Input.setValue description model.newTaskModel
        in
            ( { model | newTaskModel = newTaskModel }
            , Cmd.none
            )

    TaskListMsg taskListMsg ->
        let
            ( newTaskListModel, command ) =
                TaskList.State.update (Debug.log "taskListMsg" taskListMsg) model.taskListModel
        in
            ( { model | taskListModel = newTaskListModel }
            , Cmd.map TaskListMsg command
            )

    NewTaskMsg newTaskMsg ->
        let
            (newTaskModel, cmd) =
                Ui.Input.update (Debug.log "newTaskMsg" newTaskMsg) model.newTaskModel
        in
            ( { model | newTaskModel = newTaskModel }
            , Cmd.map NewTaskMsg cmd
            )
