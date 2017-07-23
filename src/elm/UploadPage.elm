module UploadPage exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Data exposing (Item)
import Http
import Json.Encode as Encode
import ListPage exposing (itemDecoder)


type alias Model =
    { item : Item
    , isCapturing : Bool
    , isLoading : Bool
    , error : Maybe String
    }


model : Model
model =
    { item = Data.emptyItem
    , isCapturing = False
    , isLoading = False
    , error = Nothing
    }


type Msg
    = UploadFormChangeInput String String
    | StartUpload
    | UploadResponse (Result Http.Error Item)
    | StartCapture
    | TakePicture
    | StopCapture Item
    | CancelCapture


update : Msg -> Model -> Maybe Data.Token -> ( Model, Cmd Msg )
update msg model token =
    case msg of
        StartCapture ->
            ( updateCaptureStatus True model, Data.sendStartCapture True )

        TakePicture ->
            let
                newModel =
                    model
                        |> updateCaptureStatus False
                        |> updateUploadLoading True
            in
                ( newModel, Data.sendTakePicture True )

        CancelCapture ->
            ( updateCaptureStatus False model, Data.sendStopCapture True )

        StopCapture item ->
            let
                newModel =
                    model
                        |> updateCaptureStatus False
                        |> updateCaptureItem item
                        |> updateUploadLoading False
            in
                ( newModel, Cmd.none )

        StartUpload ->
            let
                msg =
                    case token of
                        Just token ->
                            uploadRequest model.item token

                        _ ->
                            Cmd.none
            in
                ( model, msg )

        UploadFormChangeInput inputName inputValue ->
            let
                oldItem =
                    model.item

                newItem =
                    case inputName of
                        "amount" ->
                            { oldItem | amount = Result.withDefault 0 (String.toFloat inputValue) }

                        "date" ->
                            { oldItem | date = inputValue }

                        "typeId" ->
                            { oldItem | typeId = 1 }

                        "description" ->
                            { oldItem | description = inputValue }

                        _ ->
                            oldItem
            in
                ( { model | item = newItem }, Cmd.none )

        UploadResponse (Ok item) ->
            ( model, Cmd.none )

        UploadResponse (Err error) ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        currentDisplay =
            if model.isCapturing then
                "block"
            else
                "none"
    in
        div []
            [ if model.isLoading then
                div [] [ text "is loading..." ]
              else
                text ""
            , Html.form [ class "login-form", onSubmit StartUpload ]
                [ fieldset []
                    [ legend [] [ text "Upload form" ]
                    , div []
                        [ button [ onClick StartCapture, type_ "button" ] [ text "retake" ]
                        ]
                    , div []
                        [ img [ src model.item.invoice ] []
                        ]
                    , div []
                        [ label [] [ text "date" ]
                        , input
                            [ type_ "date"
                            , value model.item.date
                            , onInput (UploadFormChangeInput "date")
                            ]
                            []
                        ]
                    , div []
                        [ label [] [ text "type" ]
                        , select
                            [ onInput (UploadFormChangeInput "type")
                            ]
                            (typeToSelectOptions
                                Data.types
                                model.item.typeId
                            )
                        ]
                    , div []
                        [ label [] [ text "Amount" ]
                        , input
                            [ type_ "number"
                            , step "0.01"
                            , value (toString model.item.amount)
                            , onInput (UploadFormChangeInput "amount")
                            ]
                            []
                        ]
                    , div []
                        [ label [] [ text "Description" ]
                        , input
                            [ type_ "text"
                            , value model.item.description
                            , onInput (UploadFormChangeInput "description")
                            ]
                            []
                        ]
                    , div []
                        [ label [] []
                        , button [ type_ "submit" ] [ text "Save" ]
                        ]
                    ]
                ]
            , div
                [ style [ ( "display", currentDisplay ) ] ]
                [ video [ id "video", class "camera-video" ] []
                , canvas [ id "canvas", class "canvas" ] []
                , button [ class "camera-capture", onClick TakePicture ] []
                , button [ class "camera-stop", onClick CancelCapture ] []
                ]
            ]


updateCaptureStatus : Bool -> Model -> Model
updateCaptureStatus status page =
    { page | isCapturing = status }


updateUploadLoading : Bool -> Model -> Model
updateUploadLoading status page =
    { page | isLoading = status }


updateCaptureItem : Item -> Model -> Model
updateCaptureItem newItem page =
    { page | item = newItem }


typeToSelectOptions : List Data.Type -> Int -> List (Html Msg)
typeToSelectOptions types selectedID =
    List.map (\item -> option [ value <| toString item.id, selected (selectedID == item.id) ] [ text item.label ]) types


uploadRequest : Item -> Data.Token -> Cmd Msg
uploadRequest item token =
    let
        req =
            Http.request
                { method = "POST"
                , body = uploadEncoder item |> Http.jsonBody
                , url = Data.apiUrl "receipts/"
                , expect = Http.expectJson itemDecoder
                , headers = [ Http.header "Authorization" ("Bearer " ++ token) ]
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send UploadResponse req


uploadEncoder : Item -> Encode.Value
uploadEncoder item =
    let
        params =
            [ ( "amount", Encode.float item.amount )
            , ( "typeId", Encode.int item.typeId )
            , ( "date", Encode.string item.date )
            , ( "description", Encode.string item.description )
            , ( "invoice", Encode.string item.invoice )
            ]
    in
        Encode.object params


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Data.receiveStartCapture StopCapture
        ]
