module TaskList.Types exposing (..)

import Array exposing (Array)
import Http exposing (Error)
import Ui.Input
import Ui.Checkbox


-- TaskList model
type alias Model = Array Task


-- Task model
-- TODO: try and get rid of Maybe Int
-- with a separate editing model perhaps
-- TODO: using completed, editing and updating instead
type alias Task =
    { id          : Maybe Int
    , description : String
    , isComplete : Bool
    , notes      : Array Note
    , isEditing  : Bool
    , isUpdating : Bool
    }


type alias Note =
    { id       : Maybe Int
    , content  : String
    }


-- Create new tasks with convenient defaults
newTask : String -> Task
newTask description =
    { id          = Nothing
    , description = description
    , isComplete  = False
    , notes       = Array.empty
    , isEditing   = False
    , isUpdating  = False
    }


-- TaskList specific messages
type Msg
    = New String
    | StartEdit Task
    | DoneEdit Task String
    | ToggleComplete Task Bool
    | Delete Task

    -- Http msgs
    | OnAdd  (Result Error Task)
    | OnSave  (Result Error Task)
    | OnDelete  (Result Error Task)
    | OnLoad (Result Error (Array Task))

    | TaskInput Ui.Input.Msg
    | TaskCheckbox Ui.Checkbox.Msg
