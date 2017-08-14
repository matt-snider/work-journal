module Update exposing (update)

import Messages exposing (..)
import Models exposing (Task, Model, newTask)
import Array exposing (Array)
import Debug
import Commands


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Add -> addItem model

    Delete index -> deleteItem index model

    EditDescription index description ->
        let (newModel, task) = updateItem index model (\t -> { t | description = description, isEditing = False})
        in (newModel, Commands.saveTask task)

    EditStatus index isComplete ->
        let (newModel, task) = updateItem index model (\t -> { t | isComplete = isComplete })
        in (newModel, Commands.saveTask task)

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
            Just t  -> Commands.deleteTask t
            Nothing -> Cmd.none
    in (Array.append start end, command)


addItem : Model -> (Model, Cmd Msg)
addItem model = (model, Commands.saveTask newTask)


updateItem : Int -> Model -> (Task -> Task) -> (Model, Task)
updateItem index model updater =
    let updatedTask = Maybe.map updater (Array.get index model)
    in case updatedTask of
        Just t -> (Array.set index t model, t)
        Nothing -> (model, newTask)


