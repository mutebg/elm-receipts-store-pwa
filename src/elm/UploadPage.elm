module UploadPage exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Data exposing (Item)
import Http
import Json.Encode as Encode
import ListPage exposing (itemDecoder)
import Time
import Process
import Task


type Status
    = None
    | IsCapturing
    | IsUploading
    | IsSaving
    | ShowMessage String
    | ShowError String


messageDelay =
    5000


type alias Model =
    { item : Item
    , status : Status
    }


model : Model
model =
    { item = Data.emptyItem
    , status = None
    }


type Msg
    = UploadFormChangeInput String String
    | StartSave
    | UploadResponse (Result Http.Error Item)
    | StartCapture
    | TakePicture
    | StopCapture Item
    | CancelCapture
    | ClearStatus


update : Msg -> Model -> Maybe Data.Token -> ( Model, Cmd Msg )
update msg model token =
    case msg of
        StartCapture ->
            ( { model | status = IsCapturing }, Data.sendStartCapture True )

        TakePicture ->
            ( { model | status = IsUploading }, Data.sendTakePicture True )

        CancelCapture ->
            ( { model | status = None }, Data.sendStopCapture True )

        StopCapture newItem ->
            ( { model | item = newItem, status = None }, Cmd.none )

        StartSave ->
            let
                msg =
                    case token of
                        Just token ->
                            uploadRequest model.item token

                        _ ->
                            Cmd.none
            in
                ( { model | status = IsSaving }, msg )

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
            ( { model | status = ShowMessage "Success", item = Data.emptyItem }, delay messageDelay ClearStatus )

        UploadResponse (Err error) ->
            let
                errMsg =
                    case error of
                        Http.BadStatus resp ->
                            resp.body

                        _ ->
                            "Error. Try again"
            in
                ( { model | status = ShowError errMsg }, delay messageDelay ClearStatus )

        ClearStatus ->
            ( { model | status = None }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        currentDisplay =
            if model.status == IsCapturing then
                "block"
            else
                "none"

        message =
            case model.status of
                None ->
                    text ""

                IsCapturing ->
                    text ""

                IsUploading ->
                    div [ class "alert alert--info" ] [ text "Image processing..." ]

                IsSaving ->
                    div [ class "alert alert--info" ] [ text "Saving..." ]

                ShowMessage msg ->
                    div [ class "alert alert--success" ] [ text msg ]

                ShowError msg ->
                    div [ class "alert alert--error" ] [ text msg ]
    in
        div []
            [ message
            , Html.form [ class "login-form", onSubmit StartSave ]
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
            , div
                [ style [ ( "display", currentDisplay ) ] ]
                [ video [ id "video", class "camera-video" ] []
                , canvas [ id "canvas", class "canvas" ] []
                , button [ class "camera-capture", onClick TakePicture ] []
                , button [ class "camera-stop", onClick CancelCapture ] []
                ]
            ]


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


delay : Time.Time -> msg -> Cmd msg
delay time msg =
    Process.sleep time
        |> Task.andThen (always <| Task.succeed msg)
        |> Task.perform identity
