module App.Types exposing (..)

import Http
import Ui.Input

import App.Api as Api
import TaskList


-- App model
type alias Model =
    { taskListModel  : TaskList.Model
    , newTaskModel   : Ui.Input.Model
    }

type Msg
    -- Basic msgs
    = Add String
    | EditNew String

    -- Http msgs
    | OnCreate (Result Http.Error Api.Task)

    -- Component msgs
    | TaskListMsg TaskList.Msg
    | NewTaskMsg Ui.Input.Msg
