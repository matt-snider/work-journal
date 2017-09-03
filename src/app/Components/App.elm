module App exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )


import Date
import Ext.Date as ExtDate
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Time
import Ui.Button
import Ui.Container
import Ui.DatePicker
import Ui.Header

import TaskList
import TaskInput
import Utils.Api as Api
import Utils.Logging as Logging
import Utils.Style as Style


{---------
 - TYPES -
 ---------}
type alias Model =
    { taskList     : TaskList.Model
    , newTaskInput : TaskInput.Model
    , datepicker   : Ui.DatePicker.Model
    }

type Msg
    -- Basic msgs
    = Add String
    | EditNew String
    | DateChanged Time.Time
    | Today

    -- Http msgs
    | OnCreate (Result Http.Error Api.Task)

    -- Component msgs
    | DatePickerMsg Ui.DatePicker.Msg
    | NewTaskInputMsg  TaskInput.Msg
    | TaskListMsg TaskList.Msg


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
            [ div []
                [ Ui.DatePicker.view "en_us" model.datepicker
                    |> Html.map DatePickerMsg

                , Ui.Button.view
                    Today
                    (Ui.Button.model "Today" "warning" "medium")
                ]

            , TaskList.view model.taskList
                |> Html.map TaskListMsg

            , Ui.Container.row
                []
                [ div [ Style.flex "70" ]
                    [ TaskInput.view
                        model.newTaskInput
                        |> Html.map NewTaskInputMsg
                    ]

                , Ui.Button.view
                    (Add (TaskInput.getValue model.newTaskInput))
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
        ( taskList, taskListCmd ) =
            TaskList.init (ExtDate.now ())

        newTaskInput =
            TaskInput.init ()
                |> TaskInput.withNew True
                |> TaskInput.withPlaceholder "Enter a task..."

        datepicker =
            Ui.DatePicker.init ()
                |> Ui.DatePicker.closeOnSelect True
    in
        ( { taskList = taskList
          , newTaskInput  = newTaskInput
          , datepicker = datepicker
          }

        , Cmd.batch
            [ Cmd.map TaskListMsg taskListCmd ]
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        taskListSub =
            TaskList.subscriptions model.taskList
    in
        Sub.batch
            [ Sub.map TaskListMsg taskListSub
            , TaskInput.onChange EditNew model.newTaskInput
            , Ui.DatePicker.onChange DateChanged model.datepicker
            ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Add description ->
        let
            ( updatedNewTaskInput, newTaskInputCmd ) =
                TaskInput.setValue "" model.newTaskInput

            currentDate = model.datepicker.calendar.value
        in
            ( { model
              | newTaskInput = updatedNewTaskInput
              }

            , Cmd.batch
                [ Cmd.map NewTaskInputMsg newTaskInputCmd
                , Api.createTask OnCreate
                    description
                    currentDate
                ]
            )

    DateChanged time ->
        let
            date = Date.fromTime time

            ( updatedTaskList, taskListCmd ) =
                TaskList.init date
        in
            ( { model | taskList = updatedTaskList }
            , Cmd.map TaskListMsg taskListCmd
            )

    Today ->
        let
            today =  ExtDate.now ()

            updatedDatepicker =
                Ui.DatePicker.setValue today model.datepicker

            ( updatedTaskList, taskListCmd ) =
                TaskList.init today
        in
            ( { model
              | taskList   = updatedTaskList
              , datepicker = updatedDatepicker
              }
            , Cmd.map TaskListMsg taskListCmd
            )


    OnCreate (Ok task) ->
        let
            updatedTaskList =
                TaskList.addTask task model.taskList
        in
            ( { model | taskList = updatedTaskList }
            , Cmd.none
            )

    OnCreate (Err err) ->
        ( model, Logging.error err Cmd.none )

    EditNew description ->
        let
            ( updatedNewTaskInput, cmd ) =
                TaskInput.setValue description model.newTaskInput
        in
            ( { model | newTaskInput = updatedNewTaskInput }
            , Cmd.none
            )

    DatePickerMsg msg ->
        let
            ( updatedDatepicker, datepickerCmd ) =
                Ui.DatePicker.update msg model.datepicker
        in
            ( { model | datepicker = updatedDatepicker }
            , Cmd.map DatePickerMsg datepickerCmd
            )


    NewTaskInputMsg msg ->
        let
            ( updatedNewTaskInput, cmd ) =
                TaskInput.update msg model.newTaskInput
        in
            ( { model | newTaskInput = updatedNewTaskInput }
            , Cmd.map NewTaskInputMsg cmd
            )

    TaskListMsg msg ->
        let
            ( updatedTaskList, cmd ) =
                TaskList.update msg model.taskList
        in
            ( { model | taskList = updatedTaskList }
            , Cmd.map TaskListMsg cmd
            )
