module Main exposing (main)

import App
import Html


main =
    Html.program
        { view = App.view
        , update = App.update
        , init = App.init
        , subscriptions = App.subscriptions
        }
