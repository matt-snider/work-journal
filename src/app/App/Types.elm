module App.Types exposing (..)

import TaskList.Types


-- App model
type alias Model =
    { tasks : TaskList.Types.Model }


-- Message types
type Msg
    = TaskListMsg TaskList.Types.Msg
