module TaskList.View exposing (view)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import TaskEntry
import TaskList.Types exposing (..)


view : Model -> Html Msg
view model =
    let
        toTask entry =
            TaskEntry.view entry
                |> Html.map (TaskEntryMsg entry)
        tasks = Array.map toTask model.entries
    in
        div [] [ ul [] (Array.toList tasks) ]
