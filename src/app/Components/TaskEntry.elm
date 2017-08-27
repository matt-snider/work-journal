module TaskEntry exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , onDelete
    , update
    , view
    )

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onEnter)
import Http
import Ui.Container
import Ui.Checkbox
import Ui.Helpers.Emitter as Emitter
import Ui.IconButton
import Ui.Icons
import Ui.Input
import Ui.InplaceInput


import App.Api as Api
import Utils.Logging as Logging


{---------
 - TYPES -
 ---------}
type alias Model =
    { id        : Int
    , input     : Ui.InplaceInput.Model
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
    | Input    Ui.InplaceInput.Msg
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

            , Ui.InplaceInput.view
                model.input
                |> Html.map Input

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
            [ ul [] (List.map note []) ]
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
        input =
            Ui.InplaceInput.init ()
                |> Ui.InplaceInput.required True
                |> Ui.InplaceInput.ctrlSave True

        checkbox =
            Ui.Checkbox.init ()
    in
        { id = task.id
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
        [ Ui.InplaceInput.onChange Change model.input
        , Ui.Checkbox.onChange Toggle model.checkbox
        ]

deleteChannel : Model -> String
deleteChannel model =
        "deleteChannel" ++ toString(model.id)

onDelete : (Int -> msg) -> Model -> Sub msg
onDelete msg model =
    Emitter.listenInt
        (deleteChannel model) msg

setCompleted : Bool -> Model -> Model
setCompleted value model =
    let
        checkbox = model.checkbox
        newCheckbox = { checkbox | value = value}
    in
        { model | checkbox = newCheckbox }

toTask : Model -> Api.Task
toTask model =
    { id = model.id
    , description = model.input.value
    , completed   = model.checkbox.value
    , notes       = Array.empty
    }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        -- Main state handlers
        Change value ->
            ( { model
              | editing = False
              , updating = True
              }
            , Api.updateTask OnSave (toTask model)
            )

        Toggle value ->
            let
                newModel =
                    model |> setCompleted value
            in
                ( { model | updating = True }
                , Api.updateTask OnSave (toTask model)
                )

        Delete ->
            ( { model | updating = True }
            , Cmd.batch
                [ Api.deleteTask OnDelete (toTask model)
                , Emitter.sendInt (deleteChannel model) model.id
                ]
            )

        -- Http handlers
        OnSave (Ok task) ->
            let
                newModel = init task
            in
                ( newModel, Cmd.none )

        OnSave (Err err) ->
            ( model, Logging.error err Cmd.none )

        OnDelete _ ->
            ( { model | updating = False }
            , Cmd.none
            )

        -- Child component handlers
        Input msg ->
            let
                ( newInput, inputCmd ) =
                    Ui.InplaceInput.update msg model.input
            in
                ( { model | input = newInput }
                , Cmd.map Input inputCmd
                )

        Checkbox msg ->
            let
                ( updatedCheckbox, checkboxCmd ) =
                    Ui.Checkbox.update msg model.checkbox
            in
                ( { model | checkbox = updatedCheckbox }
                , Cmd.map Checkbox checkboxCmd
                )
