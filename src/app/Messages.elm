module Messages exposing (..)

import Models exposing (Task, Model)
import Http

type Msg
    = Add
    | EditDescription Int String
    | EditStatus  Int Bool
    | Delete Int
    | StartEdit Int
    | OnAdd (Result Http.Error Task)
    | OnSave (Result Http.Error Task)
    | OnDelete (Result Http.Error ())
    | Load (Result Http.Error (Model))
