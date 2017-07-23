module ListPage exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Data exposing (Item)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)


type alias Model =
    { items : List Item
    , error : Maybe String
    }


model : Model
model =
    { items = []
    , error = Nothing
    }


type Msg
    = ListResponse (Result Http.Error (List Item))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ListResponse (Err error) ->
            ( model, Cmd.none )

        ListResponse (Ok list) ->
            ( { model | items = list }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ ul [] (List.map listItemView model.items)
        ]


listItemView : Item -> Html Msg
listItemView item =
    li []
        [ div [ class "list-item" ] [ text item.date ]
        , div [] [ text <| typeIdToText item.typeId ]
        , div [] [ text ("amount:" ++ toString (item.amount)) ]
        ]


typeIdToText : Int -> String
typeIdToText typeId =
    let
        filteredList =
            List.filter (\i -> i.id == typeId) Data.types

        first =
            List.head filteredList
    in
        case first of
            Just i ->
                i.label

            Nothing ->
                "No Type"


listRequest : Data.Token -> Cmd Msg
listRequest token =
    let
        req =
            Http.request
                { method = "GET"
                , body = Http.emptyBody
                , url = "http://localhost:5002/elm-receipts/us-central1/api/receipts/"
                , expect = Http.expectJson listDecoder
                , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send ListResponse req


listDecoder : Decode.Decoder (List Item)
listDecoder =
    Decode.list itemDecoder


itemDecoder : Decode.Decoder Item
itemDecoder =
    decode Item
        |> Json.Decode.Pipeline.required "key" Decode.string
        |> Json.Decode.Pipeline.required "amount" Decode.float
        |> Json.Decode.Pipeline.required "typeId" Decode.int
        |> Json.Decode.Pipeline.required "date" Decode.string
        |> Json.Decode.Pipeline.required "description" Decode.string
        |> Json.Decode.Pipeline.required "invoice" Decode.string
