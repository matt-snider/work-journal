module Main exposing (main)

import App.State exposing (init, update, subscriptions)
import App.View exposing (view)
import Html


main =
    Html.program
        { view = view
        , update = update
        , init = init
        , subscriptions = subscriptions
        }
