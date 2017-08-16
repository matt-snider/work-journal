module App.Types exposing (..)

import TaskList.Types


-- App model
type alias Model =
    { taskListModel      : TaskList.Types.Model
    , newTaskDescription : String
    }


-- Message types
type Msg
    =  Add String
    | EditNew String
    | TaskListMsg TaskList.Types.Msg
