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
        toSubMsg entry =
            Sub.map
                (TaskEntryMsg entry)
                (TaskEntry.subscriptions entry)

        entrySubs =
            (Array.map toSubMsg model.entries)
                |> Array.toList
                |> Sub.batch
    in
        Sub.batch
            [ entrySubs ]


-- Update
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        New description ->
            ( model
            , Api.createTask OnCreate description
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
                -- TODO: probably need to merge this into model?
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


replace : a -> a -> Array.Array a -> Array.Array a
replace old new arr =
    let
        maybeReplace x =
            if x == old then
                new
            else
                x
    in
        Array.map maybeReplace arr
