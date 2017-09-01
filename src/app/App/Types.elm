module App.Types exposing (..)

import Ui.Input

import TaskList


-- App model
type alias Model =
    { taskListModel  : TaskList.Model
    , newTaskModel   : Ui.Input.Model
    }


-- Message types
type Msg
    = Add String
    | EditNew String
    | TaskListMsg TaskList.Msg
    | NewTaskMsg Ui.Input.Msg
