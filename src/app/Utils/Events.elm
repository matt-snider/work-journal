module Utils.Events exposing (..)

import Debug
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json


onInputBlur : (String -> msg) -> Attribute msg
onInputBlur tagger =
    on "blur" (Json.map tagger targetValue)


onInputEnter : (String -> msg) -> Attribute msg
onInputEnter tagger =
    let
        isEnter code =
            if code == 13 then
                Json.succeed ""
            else
                Json.fail ""
        decodeEnter =
            Json.andThen isEnter keyCode
    in
        on "keydown"
        <| Json.map2 (\_ value -> Debug.log "tagger value" (tagger value))
            decodeEnter
            targetValue


onEnter : msg -> Attribute msg
onEnter message =
    let
        isEnter code =
            if code == 13 then
                Json.succeed message
            else
                Json.fail "Not enter"
    in
        on "keydown" (Json.andThen isEnter keyCode)
