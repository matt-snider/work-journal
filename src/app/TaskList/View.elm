module TaskList.View exposing (view)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ui.Checkbox
import Ui.Container
import Ui.IconButton
import Ui.Icons
import Ui.Input

import TaskList.Types exposing (..)
import Utils.Events exposing (..)


view : Model -> Html Msg
view model =
    div []
    [ ul [] (List.map taskView (Array.toList model))
    ]


taskView : Task -> Html Msg
taskView task =
    Ui.Container.column
        [ ]
        [ Ui.Container.row
            []
            [ Ui.Checkbox.view
                { disabled = False
                , readonly = False
                , value = task.isComplete
                , uid = ""
                }
                |> Html.map TaskCheckbox

            , maybeInput task

            , Ui.IconButton.view
                (Delete task)
                { glyph = Ui.Icons.close []
                , disabled = False
                , readonly = False
                , text = "Delete"
                , kind = "primary"
                , side = "right"
                , size = "small"
                }

            , maybeLoadingIndicator task

            ]

        , Ui.Container.row
            [ style
                [ ("margin-left", "25px") ]
            ]
            [ ul [] (List.map note (Array.toList task.notes)) ]
        ]


-- TODO: when enter is pressed, blur also thrown
-- currently handling this in DoneEdit update hook
maybeInput : Task -> Html Msg
maybeInput task =
    let
        children =
            if task.isEditing then
                [ Ui.Input.view
                    { placeholder = ""
                    , showClearIcon = False
                    , disabled = False
                    , readonly = False
                    , value = task.description
                    , kind = "text"
                    , uid = ""
                    }
                    |> Html.map TaskInput
                ]
            else
                [ span
                    [ onClick (StartEdit task) ]
                    [ text task.description ]
                ]
    in
        span
            [ style
                [ ("width", "80%") ]
            ]
            children



maybeLoadingIndicator : Task -> Html Msg
maybeLoadingIndicator task =
    if task.isUpdating then
        img
            [ src "assets/loader.gif" ]
            []
    else
        span [] []

note : Note -> Html Msg
note n = li [] [ text n.content ]
