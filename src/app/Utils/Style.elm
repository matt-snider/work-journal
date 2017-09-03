module Utils.Style exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


flex : String -> Attribute msg
flex x = style [ ("flex", x) ]
