module TaskList.View exposing (view)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import TaskList.Types exposing (..)


view : Model -> Html Msg
view model =
    div []
    [ ul [] (List.map taskView (Array.toList model))
    ]
