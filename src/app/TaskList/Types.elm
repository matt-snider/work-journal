module TaskList.Types exposing (..)

import Array
import Http

import TaskEntry


-- TaskList model
type alias Model =
    { tasks : Array.Array TaskEntry.Model }


-- Create new tasks with convenient defaults
-- newTask : String -> Task
-- newTask description =
--     { id          = Nothing
--     , description = description
--     , isComplete  = False
--     , notes       = Array.empty
--     , isEditing   = False
--     , isUpdating  = False
--     }


-- TaskList specific messages
type Msg
    = New String
    -- Http msgs
    -- | OnAdd  (Result Error Task)
    -- | OnSave  (Result Error Task)
    -- | OnDelete  (Result Error Task)
    | OnLoad (Result Http.Error (Array.Array TaskEntry.Task))
