module TaskList.State exposing (init, subscriptions, update)

import Array
import Http

import App.Api as Api
import TaskEntry
import TaskList.Types exposing (..)
import Utils.Logging as Logging


-- Init
init : (Model, Cmd Msg)
init =
    ( { entries = Array.empty }
    , Api.getTasks OnLoad
    )


-- Subs
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


-- Update
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
                ( updatedEntry, entryCmd ) =
                    TaskEntry.update msg entry
                newEntries =
                    model.entries |> replace entry updatedEntry
            in
                ( { model | entries = newEntries }
                , Cmd.map (TaskEntryMsg entry) entryCmd
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
