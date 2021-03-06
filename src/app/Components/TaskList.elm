module TaskList exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    , addTask
    )

import Array
import Date
import Html exposing (..)
import Http
import Tuple

import Utils.Api as Api
import TaskEntry exposing (MoveOp(..))
import Utils.Logging as Logging


{---------
 - TYPES -
 ---------}
type alias Model =
    { entries : Array.Array TaskEntry.Model }


type Msg
    = Delete Int
    | Move Int MoveOp

    -- Http msgs
    | OnLoad   (Result Http.Error (Array.Array Api.Task))
    | OnReorder   (Result Http.Error (Array.Array Api.Task))

    -- Component msgs
    | TaskEntryMsg TaskEntry.Model TaskEntry.Msg


{--------
 - VIEW -
 --------}
view : Model -> Html Msg
view model =
    let
        taskLi entry =
            TaskEntry.view entry
                |> Html.map (TaskEntryMsg entry)
        tasks =
            Array.map taskLi model.entries
    in
        div [] [ ul [] (Array.toList tasks) ]


{---------
 - STATE -
 ---------}
init : Date.Date -> (Model, Cmd Msg)
init date =
    ( { entries = Array.empty }
    , Api.getTasks OnLoad date
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        toBasicSub entry =
            Sub.map
                (TaskEntryMsg entry)
                (TaskEntry.subscriptions entry)

        basicSubs =
            (Array.map toBasicSub model.entries)
                |> Array.toList
                |> Sub.batch

        onDeleteSubs =
            (Array.map (TaskEntry.onDelete Delete) model.entries)
                |> Array.toList
                |> Sub.batch

        onMoveSubs =
            (Array.map (TaskEntry.onMove Move) model.entries)
                |> Array.toList
                |> Sub.batch
    in
        Sub.batch
            [ basicSubs
            , onDeleteSubs
            , onMoveSubs
            ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Delete id ->
            ( { model | entries = removeById id model.entries }
            , Cmd.none
            )

        Move id op ->
            let
                newEntries = move id op model.entries
                newTasks = Array.map TaskEntry.toTask newEntries
            in
                ( { model | entries = newEntries }
                , Api.reorderTasks OnReorder newTasks
                )

        -- Http handlers
        OnLoad (Ok tasks) ->
            ( model
                |> setTasks tasks
            , Cmd.none
            )

        OnLoad (Err err) ->
            ( model, Logging.error err Cmd.none )

        OnReorder (Ok tasks) ->
            ( model
                |> setTasks tasks
            , Cmd.none
            )

        OnReorder (Err err) ->
            ( model, Logging.error err Cmd.none)

        -- Child component handlers
        TaskEntryMsg entry msg ->
            let
                ( newEntry, entryCmd ) =
                    TaskEntry.update msg entry
                newEntries =
                    model.entries |> replace entry newEntry
            in
                ( { model | entries = newEntries }
                , Cmd.map (TaskEntryMsg newEntry) entryCmd
                )


addTask : Api.Task -> Model -> Model
addTask task model =
    let
        newEntry = TaskEntry.init task
    in
        { model | entries = Array.push newEntry model.entries }



{---------
 - STATE -
 ---------}
removeById : Int -> Array.Array TaskEntry.Model -> Array.Array TaskEntry.Model
removeById id arr =
    Array.filter (\x -> x.id /= id) arr


setTasks : Array.Array Api.Task -> Model -> Model
setTasks tasks model =
    { model | entries = Array.map TaskEntry.init tasks }


replace : TaskEntry.Model -> TaskEntry.Model -> Array.Array TaskEntry.Model  -> Array.Array TaskEntry.Model
replace old new arr =
    let
        maybeReplace x =
            if x.id == old.id then
                new
            else
                x
    in
        Array.map maybeReplace arr


move : Int -> MoveOp -> Array.Array TaskEntry.Model -> Array.Array TaskEntry.Model
move tid op arr =
    let
        isSeq idx1 idx2 = abs (idx1 - idx2) == 1

        comparison (aIdx, a) (bIdx, b) =
            if not (isSeq aIdx bIdx) then
                -- leave how it is if non-sequential
                LT
            else
                case (a.id == tid, b.id == tid, op) of
                    -- a should be moved 'down'
                    -- a > b
                    (True, _, Down) -> GT

                    -- b should be moved 'up'
                    -- a > b
                    (_, True, Up) -> GT

                    -- otherwise, leave how it is
                    (_, _, _) -> LT

    in
        Array.toIndexedList arr
            |> List.sortWith comparison
            |> List.map Tuple.second
            |> Array.fromList
