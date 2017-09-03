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
import Http
import Ui.Container
import Ui.Checkbox
import Ui.Helpers.Emitter as Emitter
import Ui.IconButton
import Ui.Icons


import TaskInput
import Utils.Api as Api
import Utils.Logging as Logging
import Utils.Style as Style


{---------
 - TYPES -
 ---------}
type alias Model =
    { id        : Int
    , updating  : Bool
    , notes     : Array.Array String
    , input     : TaskInput.Model
    , checkbox  : Ui.Checkbox.Model
    }

type Msg
    -- Basic msgs
    = Delete
    | Change String
    | Toggle Bool

    -- Http msgs
    | OnSave   (Result Http.Error Api.Task)
    | OnDelete (Result Http.Error Api.Task)

    -- Component msgs
    | Input    TaskInput.Msg
    | Checkbox Ui.Checkbox.Msg


{--------
 - VIEW -
 --------}
view : Model -> Html Msg
view model =
    let
        containerStyle =
            style [ ("margin-bottom", "15px") ]
    in
    Ui.Container.column
        [ containerStyle ]
        [ Ui.Container.row
            []
            [ div [ ]
                [ Ui.Checkbox.view
                    model.checkbox
                    |> Html.map Checkbox
                ]

            , div [ Style.flex "80" ]
                [ TaskInput.view
                    model.input
                    |> Html.map Input
                ]

            , div [ Style.flex "10" ]
                [ Ui.IconButton.view
                    Delete
                    { glyph = Ui.Icons.close []
                    , disabled = False
                    , readonly = False
                    , text = "Delete"
                    , kind = "primary"
                    , side = "right"
                    , size = "small"
                    }
                ]

            , maybeLoadingIndicator model
            ]
        ]

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
        textContent =
            task.description
                ++ Array.foldr
                    (\x y -> "\n- " ++ x ++ y)
                    ""
                    task.notes

        input =
            TaskInput.init ()
                |> TaskInput.withNew False
                |> TaskInput.withValue textContent

        checkbox =
            Ui.Checkbox.init ()
                |> Ui.Checkbox.setValue task.completed

    in
        { id = task.id
        , updating = False
        , notes = task.notes
        , input = input
        , checkbox = checkbox
        }

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ TaskInput.onChange Change model.input
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
    let
        clean s =
            case String.uncons s of
                Just ('-', ss) -> clean ss
                Just _ -> String.trim s
                Nothing -> ""

        parts =
            String.split "\n"
                (TaskInput.getValue model.input)
                |> List.map clean
                |> List.filter (not << String.isEmpty)

        description =
            case List.head parts of
                Just d  -> d
                Nothing -> Debug.crash "TODO: handler errors in toTask"

        notes =
            List.drop 1 parts
    in
        { id = model.id
        , description = description
        , completed   = model.checkbox.value
        , notes       = Array.fromList notes
        }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        -- Main state handlers
        Change value ->
            ( { model | updating = True }
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
                    TaskInput.update msg model.input
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
