module App.Types exposing (..)

import TaskList.Types


-- App model
type alias Model =
    { taskListModel : TaskList.Types.Model
    , isAddingNew   : Bool
    }


-- Message types
type Msg
    = New
    | Add String
    | TaskListMsg TaskList.Types.Msg
