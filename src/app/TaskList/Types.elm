module TaskList.Types exposing (..)

import Array
import Http

import App.Api as Api
import TaskEntry


-- TaskList model
type alias Model =
    { entries : Array.Array TaskEntry.Model
    }


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


type Msg
    = New String
    | Delete Int

    -- Http msgs
    | OnCreate (Result Http.Error Api.Task)
    | OnLoad   (Result Http.Error (Array.Array Api.Task))

    -- Component msgs
    | TaskEntryMsg TaskEntry.Model TaskEntry.Msg
