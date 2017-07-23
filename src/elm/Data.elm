port module Data exposing (..)


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



-- PORTS


port sendToken : Token -> Cmd msg


port receiveToken : (Token -> msg) -> Sub msg


port sendStartCapture : Bool -> Cmd msg


port sendStopCapture : Bool -> Cmd msg


port sendTakePicture : Bool -> Cmd msg


port receiveStartCapture : (Item -> msg) -> Sub msg
