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
    { taskListModel  : TaskList.Model
    , newTaskModel   : TaskInput.Model
    , calendarModel  : Ui.DatePicker.Model
    }

type Msg
    -- Basic msgs
    = Add String
    | EditNew String
    | DateChanged Time.Time

    -- Http msgs
    | OnCreate (Result Http.Error Api.Task)

    -- Component msgs
    | DatePickerMsg Ui.DatePicker.Msg
    | NewTaskMsg  TaskInput.Msg
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
                [ Ui.DatePicker.view "en_us" model.calendarModel
                    |> Html.map DatePickerMsg
                ]

            , TaskList.view model.taskListModel
                |> Html.map TaskListMsg

            , Ui.Container.row
                []
                [ div [ Style.flex "70" ]
                    [ TaskInput.view
                        model.newTaskModel
                        |> Html.map NewTaskMsg
                    ]

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
            TaskList.init (ExtDate.now ())

        newTaskModel =
            TaskInput.init ()
                |> TaskInput.withNew True
                |> TaskInput.withPlaceholder "Enter a task..."

        calendarModel =
            Ui.DatePicker.init ()
                |> Ui.DatePicker.closeOnSelect True
    in
        ( { taskListModel = taskListModel
          , newTaskModel = newTaskModel
          , calendarModel = calendarModel
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
            , Ui.DatePicker.onChange DateChanged model.calendarModel
            ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Add description ->
        let
            ( newTaskModel, newTaskCmd ) =
                TaskInput.setValue "" model.newTaskModel

            currentDate = model.calendarModel.calendar.value
        in
            ( { model
              | newTaskModel  = newTaskModel
              }

            , Cmd.batch
                [ Cmd.map NewTaskMsg newTaskCmd
                , Api.createTask OnCreate
                    description
                    currentDate
                ]
            )

    DateChanged time ->
        let
            date = Date.fromTime time

            ( newListModel, listCmd ) =
                TaskList.init date
        in
            ( { model | taskListModel = newListModel }
            , Cmd.map TaskListMsg listCmd
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

    DatePickerMsg msg ->
        let
            ( newDatePickerModel, datePickerCmd ) =
                Ui.DatePicker.update msg model.calendarModel
        in
            ( { model | calendarModel = newDatePickerModel }
            , Cmd.map DatePickerMsg datePickerCmd
            )


    NewTaskMsg newTaskMsg ->
        let
            (newTaskModel, cmd) =
                TaskInput.update newTaskMsg model.newTaskModel
        in
            ( { model | newTaskModel = newTaskModel }
            , Cmd.map NewTaskMsg cmd
            )

    TaskListMsg taskListMsg ->
        let
            ( newTaskListModel, command ) =
                TaskList.update taskListMsg model.taskListModel
        in
            ( { model | taskListModel = newTaskListModel }
            , Cmd.map TaskListMsg command
            )
