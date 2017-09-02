module App.State exposing (init, update, subscriptions)

import Ui.Input

import App.Types exposing (..)
import App.Api as Api
import TaskList

import Utils.Logging as Logging


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
        in
            ( { model
              | newTaskModel  = newTaskModel
              }

            , Cmd.batch
                [ Cmd.map NewTaskMsg newTaskCmd
                , Api.createTask OnCreate description
                ]
            )

    OnCreate (Ok task) ->
        let
            newTaskListModel =
                TaskList.addTask task model.taskListModel
        in
            ( { model | taskListModel = newTaskListModel }
            , Cmd.none
            )

    OnCreate (Err err) ->
        ( model, Logging.error err Cmd.none )

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
