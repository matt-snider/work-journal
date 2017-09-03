module App exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )


import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Ui.Button
import Ui.Container
import Ui.Header

import TaskList
import TaskInput
import Utils.Api as Api
import Utils.Logging as Logging


{---------
 - TYPES -
 ---------}
type alias Model =
    { taskListModel  : TaskList.Model
    , newTaskModel   : TaskInput.Model
    }

type Msg
    -- Basic msgs
    = Add String
    | EditNew String

    -- Http msgs
    | OnCreate (Result Http.Error Api.Task)

    -- Component msgs
    | TaskListMsg TaskList.Msg
    | NewTaskMsg  TaskInput.Msg


{--------
 - VIEW -
 --------}
view : Model -> Html Msg
view model =
    Ui.Container.column
        []
        [ Ui.Header.view
            [ Ui.Header.title
                { action = Nothing
                , target = "_self"
                , link = Nothing
                , text = "Work Journal"
                }
            ]

        , Ui.Container.column
            [ contentStyle ]
            [ TaskList.view model.taskListModel
                |> Html.map TaskListMsg

            , Ui.Container.row
                []
                [ TaskInput.view
                    model.newTaskModel
                    |> Html.map NewTaskMsg

                , Ui.Button.view
                    (Add (TaskInput.getValue model.newTaskModel))
                    { disabled = False
                    , readonly = False
                    , kind = "primary"
                    , size = "medium"
                    , text = "Add"
                    }

                ]
            ]
        ]


contentStyle : Attribute msg
contentStyle = style
    [ ("padding", "15px")
    ]


{---------
 - STATE -
 ---------}
init : (Model, Cmd Msg)
init =
    let
        ( taskListModel, taskListCmd ) =
            TaskList.init

        newTaskModel =
            TaskInput.init ()
                |> TaskInput.withNew True
                |> TaskInput.withPlaceholder "Enter a task..."
    in
        ( { taskListModel = taskListModel
          , newTaskModel = newTaskModel
          }

        , Cmd.batch
            [ Cmd.map TaskListMsg taskListCmd ]
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        taskListSub =
            TaskList.subscriptions model.taskListModel
    in
        Sub.batch
            [ Sub.map TaskListMsg taskListSub
            , TaskInput.onChange EditNew model.newTaskModel
            ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Add description ->
        let
            ( newTaskModel, newTaskCmd ) =
                TaskInput.setValue "" model.newTaskModel
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
                TaskInput.setValue description model.newTaskModel
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
                TaskInput.update newTaskMsg model.newTaskModel
        in
            ( { model | newTaskModel = newTaskModel }
            , Cmd.map NewTaskMsg cmd
            )
