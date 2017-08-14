module Main exposing (main)


import State exposing (init, update, subscriptions)
import View exposing (view)
import Html


main =
    Html.program
        { view = view
        , update = update
        , init = init
        , subscriptions = subscriptions
        }
