module TaskInput exposing
    ( Model
    , Msg
    , getValue
    , init
    , onChange
    , setValue
    , update
    , view
    , withNew
    , withPlaceholder
    , withValue
    )

import Html exposing (..)
import Platform.Sub
import Ui.InplaceInput
import Ui.Textarea


{---------
 - TYPES -
 ---------}
type alias Model =
    { input : Ui.InplaceInput.Model
    , isNew : Bool
    }


type Msg
    -- Component msgs
    = TextareaMsg     Ui.Textarea.Msg
    | InplaceInputMsg Ui.InplaceInput.Msg


{--------
 - VIEW -
 --------}
-- Switch on isNew to decide whether to display
-- full editing input with save/close or just
-- textarea.
view : Model -> Html Msg
view model =
    if model.isNew then
        Ui.Textarea.view
            model.input.textarea
            |> Html.map TextareaMsg
    else
        Ui.InplaceInput.view
            model.input
            |> Html.map InplaceInputMsg


{---------
 - STATE -
 ---------}
init : () -> Model
init _ =
    { input =
        Ui.InplaceInput.init ()
            |> Ui.InplaceInput.required True
            |> Ui.InplaceInput.ctrlSave True
    , isNew = False
    }


-- Allow caller to subscribe to changes.
-- If isNew, then we are a simple textarea and the caller
-- will want to be notified for every single change. For an
-- existing task, we simply notify when save is pressed.
onChange : (String -> msg) -> Model -> Platform.Sub.Sub msg
onChange msg model =
    if model.isNew then
        Ui.Textarea.onChange msg model.input.textarea
    else
        Ui.InplaceInput.onChange msg model.input


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        -- Main state handlers
        TextareaMsg msg ->
            let
                ( newTextarea, inputCmd ) =
                    Ui.Textarea.update msg model.input.textarea
            in
                ( model |> setTextarea newTextarea
                , Cmd.map TextareaMsg inputCmd
                )

        -- Child component handlers
        InplaceInputMsg msg ->
            let
                ( newInput, inputCmd ) =
                    Ui.InplaceInput.update msg model.input
            in
                ( { model | input = newInput }
                , Cmd.map InplaceInputMsg inputCmd
                )


setValue : String -> Model -> (Model, Cmd Msg)
setValue value model =
    let
        ( newInput, inputCmd ) =
            Ui.InplaceInput.setValue
                value
                model.input
    in
        ( { model | input = newInput }
        , Cmd.map InplaceInputMsg inputCmd
        )


{-----------
 - HELPERS -
 -----------}
withNew : Bool -> Model -> Model
withNew isNew model = { model | isNew = isNew }


withPlaceholder : String -> Model -> Model
withPlaceholder placeholder model =
    { model
    | input =
        Ui.InplaceInput.placeholder
            placeholder
            model.input
    }


withValue : String -> Model -> Model
withValue value model =
    let
        input = model.input
        newInput = { input | value = value }
    in
        { model | input = newInput }


setTextarea : Ui.Textarea.Model -> Model -> Model
setTextarea newTextarea model =
    let
        input = model.input
        newInput = { input | textarea = newTextarea }
    in
        { model | input = newInput }


getValue : Model -> String
getValue model = model.input.value
