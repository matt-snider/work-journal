module TaskEntry exposing
    ( Model
    , Msg
    , MoveOp(..)
    , init
    , subscriptions
    , onDelete
    , onMove
    , toTask
    , update
    , view
    )

import Array
import Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Ui.ButtonGroup
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
    , date      : Date.Date
    , updating  : Bool
    , ordering  : Int
    , notes     : Array.Array String
    , input     : TaskInput.Model
    , checkbox  : Ui.Checkbox.Model
    , actions   : Ui.ButtonGroup.Model Msg
    }

type Msg
    -- Basic msgs
    = Delete
    | Change String
    | Toggle Bool
    | MoveUp
    | MoveDown

    -- Http msgs
    | OnSave   (Result Http.Error Api.Task)
    | OnDelete (Result Http.Error Api.Task)

    -- Component msgs
    | Input    TaskInput.Msg
    | Checkbox Ui.Checkbox.Msg


type MoveOp = Up | Down


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

            , div [ Style.flex "70" ]
                [ TaskInput.view
                    model.input
                    |> Html.map Input
                ]

            , div [ Style.flex "20" ]
                [ Ui.ButtonGroup.view
                    model.actions

                , Ui.IconButton.view
                    Delete
                    { glyph = Ui.Icons.close []
                    , disabled = False
                    , readonly = False
                    , text = "Delete"
                    , kind = "danger"
                    , side = "right"
                    , size = "medium"
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

        actions =
            Ui.ButtonGroup.model
                [ ("↑", MoveUp)
                , ("↓", MoveDown)
                ]

    in
        { id = task.id
        , updating = False
        , notes = task.notes
        , input = input
        , ordering = task.ordering
        , date  = task.date
        , actions = { actions | kind = "secondary" }
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


moveChannel : Model ->  MoveOp -> String
moveChannel model op =
        "moveChannel" ++ toString(model.id) ++ toString(op)


onDelete : (Int -> msg) -> Model -> Sub msg
onDelete msg model =
    Emitter.listenInt
        (deleteChannel model) msg


-- Called with id and change
onMove : (Int -> MoveOp -> msg) -> Model -> Sub msg
onMove msg model =
    Sub.batch
        [ Emitter.listenNaked
            (moveChannel model Up) (msg model.id Up)
        , Emitter.listenNaked
            (moveChannel model Down) (msg model.id Down)
        ]


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
        , ordering    = model.ordering
        , date        = model.date
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

        MoveUp ->
            ( model
            , Emitter.sendNaked (moveChannel model Up)
            )

        MoveDown ->
            ( model
            , Emitter.sendNaked (moveChannel model Down)
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
