port module Data exposing (..)


type alias Credetials =
    { token : Maybe Token
    , refreshToken : Maybe Token
    }


cfg :
    { api_url : String
    }
cfg =
    if False then
        { api_url = "http://localhost:5002/elm-receipts/us-central1/api/"
        }
    else
        { api_url = "https://us-central1-elm-receipts.cloudfunctions.net/api/"
        }


type alias Token =
    String


type alias Type =
    { id : Int
    , label : String
    }


type alias Item =
    { key : String
    , amount : Float
    , typeId : Int
    , date : String
    , description : String
    , invoice : String
    }


types : List Type
types =
    [ { id = 1
      , label = "Lunch"
      }
    , { id = 2
      , label = "Transport"
      }
    , { id = 999
      , label = "Other"
      }
    ]


emptyItem : Item
emptyItem =
    { key = ""
    , amount = 0
    , typeId = 999
    , date = ""
    , description = ""
    , invoice = ""
    }


apiUrl : String -> String
apiUrl str =
    cfg.api_url ++ str



-- PORTS


port sendToken : Credetials -> Cmd msg


port receiveToken : (Credetials -> msg) -> Sub msg


port sendStartCapture : Bool -> Cmd msg


port sendStopCapture : Bool -> Cmd msg


port sendTakePicture : Bool -> Cmd msg


port receiveStartCapture : (Item -> msg) -> Sub msg
