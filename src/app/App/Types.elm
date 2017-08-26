module App.Types exposing (..)

import TaskList.Types
import Ui.Input


-- App model
type alias Model =
    { taskListModel      : TaskList.Types.Model
    , newTaskModel       : Ui.Input.Model
    }


-- Message types
type Msg
    = Add String
    | EditNew String
    | TaskListMsg TaskList.Types.Msg
    | NewTaskMsg Ui.Input.Msg
