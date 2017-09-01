module App.State exposing (init, update, subscriptions)

import Array
import Ui.Input

import App.Types exposing (..)
import TaskList


-- Init
init : (Model, Cmd Msg)
init =
    let
        ( taskListModel, taskListCmd ) =
            TaskList.init

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
            TaskList.subscriptions model.taskListModel
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
                TaskList.update
                    (TaskList.New model.newTaskModel.value)
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
            (newTaskModel, _) =
                Ui.Input.setValue description model.newTaskModel
        in
            ( { model | newTaskModel = newTaskModel }
            , Cmd.none
            )

    TaskListMsg taskListMsg ->
        let
            ( newTaskListModel, command ) =
                TaskList.update taskListMsg model.taskListModel
        in
            ( { model | taskListModel = newTaskListModel }
            , Cmd.map TaskListMsg command
            )

    NewTaskMsg newTaskMsg ->
        let
            (newTaskModel, cmd) =
                Ui.Input.update newTaskMsg model.newTaskModel
        in
            ( { model | newTaskModel = newTaskModel }
            , Cmd.map NewTaskMsg cmd
            )
