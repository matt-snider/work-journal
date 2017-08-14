import Html
import Array

import Update exposing (update)
import View exposing (view)
import Commands


main =
    Html.program
        { view = view
        , update = update
        , init = (Array.empty, Commands.getTasks)
        , subscriptions = (\x -> Sub.none)
        }
