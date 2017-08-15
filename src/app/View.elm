module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import TaskList.View
import Types exposing (..)


view : Model -> Html Msg
view model =
    div []
    [ h1 [] [ text "Work Journal" ]
    , TaskList.View.view model.tasks
    ]
    |> Html.map TaskListMsg
