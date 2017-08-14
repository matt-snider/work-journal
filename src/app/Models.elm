module Models exposing (..)

import Array exposing (Array)


-- App model
-- currently just a list of tasks
type alias Model = Array Task


-- Task model
type alias Task =
    { id          : Maybe Int
    , description : String
    , isComplete : Bool
    , isEditing  : Bool
    }

-- Create new tasks with convenient defaults
newTask : Task
newTask = Task Nothing "" False True
