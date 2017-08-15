module TaskList.State exposing (init, subscriptions, update)

import Array

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
    Add -> addItem model

    Delete index -> deleteItem index model

    EditDescription index description ->
        let (newModel, task) = updateItem index model (\t -> { t | description = description, isEditing = False})
        in (newModel, Api.saveTask task)

    EditStatus index isComplete ->
        let (newModel, task) = updateItem index model (\t -> { t | isComplete = isComplete })
        in (newModel, Api.saveTask task)

    StartEdit index ->
        let (newModel, task) = updateItem index model (\t -> { t | isEditing = True })
        in (newModel, Cmd.none)

    Load (Ok tasks) -> (tasks, Cmd.none)
    Load (Err _) -> (model, Cmd.none)
    OnAdd (Ok t) -> (Array.push {t | isEditing = True} model, Cmd.none)
    OnAdd (Err err) -> (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)
    OnSave (Ok _) -> (model, Cmd.none)
    OnSave (Err err) -> (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)
    OnDelete (Ok _) -> (model, Cmd.none)
    OnDelete (Err err) -> (model, Debug.log ("Error: " ++ toString (err)) Cmd.none)


-- Helpers
deleteItem : Int -> Model -> (Model, Cmd Msg)
deleteItem index model =
    let
        start    = Array.slice 0 index model
        end      = Array.slice (index + 1) (Array.length model) model
        toDelete = Array.get index model
        command  = case toDelete of
            Just t  -> Api.deleteTask t
            Nothing -> Cmd.none
    in (Array.append start end, command)


addItem : Model -> (Model, Cmd Msg)
addItem model = (model, Api.saveTask newTask)


updateItem : Int -> Model -> (Task -> Task) -> (Model, Task)
updateItem index model updater =
    let updatedTask = Maybe.map updater (Array.get index model)
    in case updatedTask of
        Just t -> (Array.set index t model, t)
        Nothing -> (model, newTask)





