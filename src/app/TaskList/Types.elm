module TaskList.Types exposing (..)

import Array exposing (Array)
import Http exposing (Error)


-- TaskList model
type alias Model = Array Task


-- Task model
-- TODO: try and get rid of Maybe Int
-- with a separate editing model perhaps
type alias Task =
    { id          : Maybe Int
    , description : String
    , isComplete : Bool
    , isEditing  : Bool
    }


-- Create new tasks with convenient defaults
newTask : Task
newTask = Task Nothing "" False True


-- TaskList specific messages
-- TODO: figure out which belong here
-- and which at top-level
type Msg
    = Add
    | EditDescription Int String
    | EditStatus  Int Bool
    | Delete Int
    | StartEdit Int

    -- API tasks
    | OnAdd (Result Error Task)
    | OnSave (Result Error Task)
    | OnDelete (Result Error ())
    | Load (Result Error (Array Task))
