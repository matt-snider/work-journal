module Utils.Events exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode


onInputBlur : (String -> msg) -> Attribute msg
onInputBlur tagger =
    on "blur" (Decode.map tagger targetValue)
