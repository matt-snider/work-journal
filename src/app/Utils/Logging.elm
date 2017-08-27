module Utils.Logging exposing (..)

import Http

error : Http.Error -> a -> a
error err result =
    Debug.log ("Error: " ++ toString err) result
