module Types exposing (..)

import Array exposing (Array)
import Http

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


-- Message types
type Msg
    = Add
    | EditDescription Int String
    | EditStatus  Int Bool
    | Delete Int
    | StartEdit Int

    -- API tasks
    | OnAdd (Result Http.Error Task)
    | OnSave (Result Http.Error Task)
    | OnDelete (Result Http.Error ())
    | Load (Result Http.Error (Model))
