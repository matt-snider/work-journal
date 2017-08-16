module Utils.Events exposing (..)

import Debug
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode


onInputBlur : (String -> msg) -> Attribute msg
onInputBlur tagger =
    on "blur" (Decode.map tagger targetValue)


onInputEnter : (String -> msg) -> Attribute msg
onInputEnter tagger =
    let
        isEnter code =
            if code == 13 then
                Decode.succeed ""
            else
                Decode.fail ""
        decodeEnter =
            Decode.andThen isEnter keyCode
    in
        on "keydown"
        <| Decode.map2 (\_ value -> Debug.log "tagger value" (tagger value))
            decodeEnter
            targetValue
