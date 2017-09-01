module TaskList exposing
    ( Model
    , Msg (New)
    , init
    , subscriptions
    , update
    , view
    )

import Array
import Html exposing (..)
import Http

import App.Api as Api
import TaskEntry
import Utils.Logging as Logging


{---------
 - TYPES -
 ---------}
type alias Model =
    { entries : Array.Array TaskEntry.Model }


type Msg
    = New String
    | Delete Int

    -- Http msgs
    | OnCreate (Result Http.Error Api.Task)
    | OnLoad   (Result Http.Error (Array.Array Api.Task))

    -- Component msgs
    | TaskEntryMsg TaskEntry.Model TaskEntry.Msg


{--------
 - VIEW -
 --------}
view : Model -> Html Msg
view model =
    let
        taskLi entry =
            TaskEntry.view entry
                |> Html.map (TaskEntryMsg entry)
        tasks =
            Array.map taskLi model.entries
    in
        div [] [ ul [] (Array.toList tasks) ]


{---------
 - STATE -
 ---------}
init : (Model, Cmd Msg)
init =
    ( { entries = Array.empty }
    , Api.getTasks OnLoad
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        toBasicSub entry =
            Sub.map
                (TaskEntryMsg entry)
                (TaskEntry.subscriptions entry)

        basicSubs =
            (Array.map toBasicSub model.entries)
                |> Array.toList
                |> Sub.batch

        onDeleteSubs =
            (Array.map (TaskEntry.onDelete Delete) model.entries)
                |> Array.toList
                |> Sub.batch
    in
        Sub.batch
            [ basicSubs
            , onDeleteSubs
            ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        New description ->
            ( model
            , Api.createTask OnCreate description
            )

        Delete id ->
            ( { model | entries = removeById id model.entries }
            , Cmd.none
            )

        -- Http handlers
        OnLoad (Ok tasks) ->
            ( model
                |> setTasks tasks
            , Cmd.none
            )

        OnLoad (Err err) ->
            ( model, Logging.error err Cmd.none )

        OnCreate (Ok task) ->
            ( model
                |> addTask task
            , Cmd.none
            )

        OnCreate (Err err) ->
            ( model, Logging.error err Cmd.none )


        -- Child component handlers
        TaskEntryMsg entry msg ->
            let
                ( newEntry, entryCmd ) =
                    TaskEntry.update msg entry
                newEntries =
                    model.entries |> replace entry newEntry
            in
                ( { model | entries = newEntries }
                , Cmd.map (TaskEntryMsg newEntry) entryCmd
                )


-- Utils
setTasks : Array.Array Api.Task -> Model -> Model
setTasks tasks model =
    { model | entries = Array.map TaskEntry.init tasks }


addTask : Api.Task -> Model -> Model
addTask task model =
    let
        newEntry = TaskEntry.init task
    in
        { model | entries = Array.push newEntry model.entries }


replace : TaskEntry.Model -> TaskEntry.Model -> Array.Array TaskEntry.Model  -> Array.Array TaskEntry.Model
replace old new arr =
    let
        maybeReplace x =
            if x.id == old.id then
                new
            else
                x
    in
        Array.map maybeReplace arr


removeById : Int -> Array.Array TaskEntry.Model -> Array.Array TaskEntry.Model
removeById id arr =
    Array.filter (\x -> x.id /= id) arr
