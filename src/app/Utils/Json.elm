module Utils.Json exposing (..)

import Date
import Json.Decode as Decode

decodeDate : Decode.Decoder Date.Date
decodeDate =
    let
        convert dateString =
            case Date.fromString dateString of
                Ok date -> Decode.succeed date
                Err err -> Decode.fail err
    in
        Decode.string
            |> Decode.andThen convert
