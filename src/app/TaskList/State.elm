module TaskList.State exposing (init, subscriptions, update)

import Array exposing (Array)

import TaskList.Types exposing (..)
import TaskList.Api as Api


-- Init
init : (Model, Cmd Msg)
init = (Array.empty, Api.getTasks)


-- Subs
subscriptions : Model -> Sub Msg
subscriptions = (\x -> Sub.none)


-- Update
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    New description ->
        ( model
        , Api.saveTask (newTask description)
        )

    StartEdit task ->
        ( replace model { task | isEditing = True }
        , Cmd.none
        )

    DoneEdit task description ->
        ( replace model { task | isUpdating = True }
        , Api.saveTask { task | description = description }
        )

    Delete task ->
        ( replace model { task | isUpdating = True }
        , Api.deleteTask task
        )

    ToggleComplete task isComplete ->
        ( replace model { task | isUpdating = True }
        , Api.saveTask { task | isComplete = True }
        )

    -- Command handlers
    OnAdd (Ok task) ->
        ( Array.push task model
        , Cmd.none
        )

    OnSave (Ok task) ->
        ( replace model task
        , Cmd.none
        )

    OnDelete (Ok task) ->
        ( Array.filter (\x -> x /= task) model
        , Cmd.none
        )

    OnLoad (Ok tasks) ->
        ( tasks
        , Cmd.none
        )

    -- Error handlers
    OnAdd (Err err) ->
        (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)

    OnLoad (Err _) ->
        (model, Cmd.none)

    OnSave (Err err) ->
        (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)

    OnDelete (Err err) ->
        (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)


-- Utils
replace : Array Task -> Task -> Array Task
replace arr obj =
    let
        maybeMerge x =
            if obj.id == x.id then
                obj
            else
                x
    in
        Array.map maybeMerge arr
