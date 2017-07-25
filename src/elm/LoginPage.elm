module LoginPage exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Data exposing (Credetials)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)


type alias Model =
    { username : String
    , password : String
    , error : Maybe String
    , cred : Credetials
    }


model : Model
model =
    { username = ""
    , password = ""
    , error = Nothing
    , cred =
        { token = Nothing
        , refreshToken = Nothing
        }
    }


type Msg
    = LoginFormChangeInput String String
    | LoginFormSubmit
    | LoginResponse (Result Http.Error Credetials)
    | ReceiveToken Credetials


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoginFormChangeInput inputName inputValue ->
            let
                newModel =
                    case inputName of
                        "password" ->
                            { model | password = inputValue }

                        "username" ->
                            { model | username = inputValue }

                        _ ->
                            model
            in
                ( newModel, Cmd.none )

        LoginFormSubmit ->
            ( model, loginRequest model.username model.password )

        LoginResponse (Ok newCred) ->
            ( { model | error = Nothing, cred = newCred }, Data.sendToken newCred )

        LoginResponse (Err error) ->
            let
                errMsg =
                    case error of
                        Http.BadStatus resp ->
                            Result.withDefault "Login Error!" (Decode.decodeString (Decode.at [ "error", "message" ] Decode.string) resp.body)

                        _ ->
                            "Login Error!"

                newCred =
                    { token = Nothing
                    , refreshToken = Nothing
                    }
            in
                ( { model | error = Just errMsg, cred = newCred }, Cmd.none )

        ReceiveToken newCred ->
            ( { model | error = Nothing, cred = newCred }, Cmd.none )


view : Model -> Html Msg
view model =
    Html.form [ class "login", onSubmit LoginFormSubmit ]
        [ div []
            [ text
                (case model.error of
                    Nothing ->
                        ""

                    Just msg ->
                        msg
                )
            ]
        , div []
            [ label [] [ text "User Name" ]
            , input
                [ type_ "text"
                , value model.username
                , onInput (LoginFormChangeInput "username")
                ]
                []
            ]
        , div []
            [ label [] [ text "Password" ]
            , input
                [ type_ "password"
                , value model.password
                , onInput (LoginFormChangeInput "password")
                ]
                []
            ]
        , div []
            [ label [] []
            , button [ type_ "submit" ] [ text "Login" ]
            ]
        ]


loginRequest : String -> String -> Cmd Msg
loginRequest user password =
    let
        req =
            Http.request
                { method = "POST"
                , body = loginEncoder user password |> Http.jsonBody
                , url = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyAcFNMw-GikdJ019_Uvg8gVGcoR1TRVJfY"
                , expect = Http.expectJson loginDecoder
                , headers = []
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send LoginResponse req


loginEncoder : String -> String -> Encode.Value
loginEncoder username password =
    let
        params =
            [ ( "email", Encode.string username )
            , ( "password", Encode.string password )
            , ( "returnSecureToken", Encode.bool True )
            ]
    in
        Encode.object params



-- loginDecoder : Decode.Decoder Token
-- loginDecoder =
--     Decode.at [ "idToken" ] Decode.string


loginDecoder : Decode.Decoder Credetials
loginDecoder =
    decode Credetials
        |> Json.Decode.Pipeline.required "idToken" (Decode.nullable Decode.string)
        |> Json.Decode.Pipeline.required "refreshToken" (Decode.nullable Decode.string)


errorDecoder : Decode.Decoder String
errorDecoder =
    Decode.at [ "error", "message" ] Decode.string


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Data.receiveToken ReceiveToken
        ]
