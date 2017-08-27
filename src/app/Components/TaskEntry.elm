module TaskEntry exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Ui.IconButton
import Ui.Icons
import Ui.Input
import Ui.Container
import Ui.Checkbox

import App.Api as Api
import Utils.Events exposing (onInputEnter)
import Utils.Logging as Logging


{---------
 - TYPES -
 ---------}
type alias Model =
    { task      : Api.Task
    , input     : Ui.Input.Model
    , checkbox  : Ui.Checkbox.Model
    , editing   : Bool
    , updating  : Bool
    }

type Msg
    -- Basic msgs
    = StartEdit
    | StopEdit
    | Delete
    | Change String
    | Toggle Bool

    -- Http msgs
    | OnSave   (Result Http.Error Api.Task)
    | OnDelete (Result Http.Error Api.Task)

    -- Component msgs
    | Input    Ui.Input.Msg
    | Checkbox Ui.Checkbox.Msg


{--------
 - VIEW -
 --------}
view : Model -> Html Msg
view model =
    Ui.Container.column
        [ ]
        [ Ui.Container.row
            []
            [ Ui.Checkbox.view
                model.checkbox
                |> Html.map Checkbox

            , taskInput model

            , Ui.IconButton.view
                Delete
                { glyph = Ui.Icons.close []
                , disabled = False
                , readonly = False
                , text = "Delete"
                , kind = "primary"
                , side = "right"
                , size = "small"
                }

            , maybeLoadingIndicator model
            ]

        , Ui.Container.row
            [ style
                [ ("margin-left", "25px") ]
            ]
            [ ul [] (List.map note (Array.toList model.task.notes)) ]
        ]


-- Task is only an input when isEditing = True
-- which can be toggled by clicking
taskInput : Model -> Html Msg
taskInput model =
    if model.editing then
        span [ ]
            [ Ui.Input.view
                model.input
                |> Html.map Input
            ]
    else
        span []
            [ span
                [ onClick StartEdit ]
                [ text model.task.description ]
            ]

-- Notes are just li's
note : Api.Note -> Html Msg
note n = li [] [ text n.content ]

-- Displays loading indicator when updating
maybeLoadingIndicator : Model -> Html Msg
maybeLoadingIndicator model =
    if model.updating then
        img
            [ src "assets/loader.gif" ]
            []
    else
        span [] []


{---------
 - STATE -
 ---------}
init : Api.Task -> Model
init task =
    let
        input = Ui.Input.init ()
        checkbox = Ui.Checkbox.init ()
    in
        { task = task
        , editing  = False
        , updating = False
        , input =
            { input | value = task.description }
        , checkbox =
            { checkbox | value = task.completed }
        }

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ui.Input.onChange Change model.input
        , Ui.Checkbox.onChange Toggle model.checkbox
        ]


setCompleted : Bool -> Api.Task -> Api.Task
setCompleted value task =
    { task | completed = value }


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        -- Main state handlers
        StartEdit ->
            Debug.log "TaskEntry.StartEdit"
            ( { model | editing = True } , Cmd.none )


        StopEdit ->
            Debug.log "TaskEntry.StopEdit"
            ( { model | editing = False } , Cmd.none )

        Delete ->
            Debug.log "TaskEntry.Delete"
            ( { model | updating = True }
            , Api.deleteTask OnDelete model.task
            )

        Toggle value ->
            let
                task =
                    model.task
                    |> setCompleted (Debug.log "toggle value" value)
            in
                Debug.log "TaskEntry.Toggle"
                ( { model | updating = True }
                , Api.updateTask OnSave task
                )

        Change value ->
            let
                ( input, inputCmd ) =
                    Ui.Input.setValue value model.input
            in
                Debug.log "TaskEntry.Change"
                ( { model | input = input }
                , Cmd.map Input inputCmd
                )

        -- Http handlers
        OnSave (Ok task) ->
            ( { model
              | updating = False
              , task = task
              }
            , Cmd.none
            )

        OnSave (Err err) ->
            ( model, Logging.error err Cmd.none )

        OnDelete _ ->
            ( { model | updating = False }
            , Cmd.none
            )

        -- Child component handlers
        Input msg ->
            let
                ( updatedInput, inputCmd ) =
                    Ui.Input.update msg model.input
            in
                Debug.log "TaskEntry.Input"
                ( { model | input = updatedInput }
                , Cmd.map Input inputCmd
                )

        Checkbox msg ->
            let
                ( updatedCheckbox, checkboxCmd ) =
                    Ui.Checkbox.update msg model.checkbox
            in
                Debug.log "TaskEntry.Checkbox"
                ( { model | checkbox = updatedCheckbox }
                , Cmd.map Checkbox checkboxCmd
                )
