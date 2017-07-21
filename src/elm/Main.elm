port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)


-- APP


main : Program Never Model Msg
main =
    Html.program { init = init, view = view, update = update, subscriptions = subscriptions }



-- MODEL


type alias Token =
    String


type alias Item =
    { postId : Int
    , id : Int
    , name : String
    , body : String
    }



-- { date : String
-- , amount : Float
-- , invoice : String
-- , description : String
-- }


type alias LoginPageModel =
    { username : String
    , password : String
    , token : Maybe Token
    , error : Maybe String
    }


type alias UploadPageModel =
    { item : Item
    , isCapturing : Bool
    , error : Maybe String
    }


type alias ListPageModel =
    { items : List Item
    , error : Maybe String
    }


type alias SettingsPageModel =
    { item : Item
    , error : Maybe String
    }


type alias Model =
    { page : Page
    , loginPage : LoginPageModel
    , uploadPage : UploadPageModel
    , settingsPage : SettingsPageModel
    , listPage : ListPageModel
    }


type alias Type =
    { id : Int
    , label : String
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


init : ( Model, Cmd Msg )
init =
    ( model, Cmd.none )


model : Model
model =
    { page = LoginPage
    , loginPage =
        { username = ""
        , password = ""
        , token = Nothing
        , error = Nothing
        }
    , uploadPage =
        { item = emptyItem
        , isCapturing = False
        , error = Nothing
        }
    , settingsPage =
        { item = emptyItem
        , error = Nothing
        }
    , listPage =
        { items = []
        , error = Nothing
        }
    }


emptyItem : Item
emptyItem =
    { postId = 0
    , id = 0
    , name = ""
    , body = ""
    }


type Page
    = NotFound
    | UploadPage
    | ListPage
    | LoginPage
    | SettingsPage



-- SUBSCRIBTION


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveStartCapture StopCapture
        , receiveToken ReceiveToken
        ]



-- UPDATE


type Msg
    = NoOp
    | SetPage Page
    | SetPageUpload
    | SetPageLit
    | StartCapture
    | StopCapture String
    | LoginFormUsernameInput String
    | LoginFormPasswordInput String
    | LoginFormSubmit
    | LoginResponse (Result Http.Error Token)
    | ReceiveToken Token
    | ListResponse (Result Http.Error (List Item))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        oldLoginPage =
            model.loginPage
    in
        case msg of
            NoOp ->
                ( model, Cmd.none )

            SetPage newPage ->
                ( { model | page = newPage }, Cmd.none )

            SetPageUpload ->
                ( { model | page = UploadPage, uploadPage = updateCaptureStatus True model.uploadPage }, sendStartCapture True )

            SetPageLit ->
                let
                    msg =
                        case model.loginPage.token of
                            Just token ->
                                listRequest token

                            _ ->
                                Cmd.none
                in
                    ( { model | page = ListPage }, msg )

            StartCapture ->
                ( { model | uploadPage = updateCaptureStatus True model.uploadPage }, sendStartCapture True )

            StopCapture k ->
                ( { model | uploadPage = updateCaptureStatus False model.uploadPage }, Cmd.none )

            LoginFormUsernameInput usernameInput ->
                let
                    newLoginPage =
                        { oldLoginPage | username = usernameInput }
                in
                    ( { model | loginPage = newLoginPage }, Cmd.none )

            LoginFormPasswordInput passwordInput ->
                let
                    newLoginPage =
                        { oldLoginPage | password = passwordInput }
                in
                    ( { model | loginPage = newLoginPage }, Cmd.none )

            LoginFormSubmit ->
                ( model, loginRequest model.loginPage.username model.loginPage.password )

            LoginResponse (Ok token) ->
                let
                    currentLoginPage =
                        model.loginPage

                    newLoginPage =
                        { currentLoginPage | error = Nothing, token = Just token }
                in
                    ( { model | page = UploadPage, loginPage = newLoginPage }, sendToken token )

            LoginResponse (Err error) ->
                let
                    currentLoginPage =
                        model.loginPage

                    newLoginPage =
                        { currentLoginPage | error = Just "wrong username or password", token = Nothing }
                in
                    ( { model | loginPage = newLoginPage }, Cmd.none )

            ReceiveToken token ->
                let
                    currentLoginPage =
                        model.loginPage

                    newLoginPage =
                        { currentLoginPage | error = Nothing, token = Just token }
                in
                    ( { model | page = UploadPage, loginPage = newLoginPage }, Cmd.none )

            ListResponse (Err error) ->
                ( model, Cmd.none )

            ListResponse (Ok list) ->
                let
                    oldPage =
                        model.listPage

                    newPage =
                        { oldPage | items = list }
                in
                    ( { model | listPage = newPage }, Cmd.none )



-- PORTS


port sendToken : Token -> Cmd msg


port receiveToken : (Token -> msg) -> Sub msg


port sendSettings : Item -> Cmd msg


port receiveSettings : (Item -> msg) -> Sub msg


port sendStartCapture : Bool -> Cmd msg


port receiveStartCapture : (String -> msg) -> Sub msg



-- VIEW
-- Html is defined as: elem [ attribs ][ children ]
-- CSS can be applied via class names or inline style attrib


view : Model -> Html Msg
view model =
    div []
        [ div []
            [ button [ onClick (SetPage LoginPage) ] [ text "login" ]
            , button [ onClick SetPageLit ] [ text "List" ]
            , button [ onClick SetPageUpload ] [ text "upload" ]
            , button [ onClick (SetPage SettingsPage) ] [ text "settings" ]
            ]
        , case model.page of
            LoginPage ->
                loginPageView model.loginPage

            SettingsPage ->
                settingsPageView model.settingsPage

            UploadPage ->
                uploadPageView model.uploadPage

            ListPage ->
                listPageView model.listPage

            _ ->
                div [] [ text "no page" ]
        ]


loginPageView : LoginPageModel -> Html Msg
loginPageView model =
    Html.form [ class "login-form", onSubmit LoginFormSubmit ]
        [ div []
            [ text
                (case model.error of
                    Nothing ->
                        ""

                    Just msg ->
                        msg
                )
            ]
        , fieldset []
            [ legend [] [ text "Login" ]
            , div []
                [ label [] [ text ("User Name" ++ model.username) ]
                , input
                    [ type_ "text"
                    , value model.username
                    , onInput LoginFormUsernameInput
                    ]
                    []
                ]
            , div []
                [ label [] [ text "Password" ]
                , input
                    [ type_ "password"
                    , value model.password
                    , onInput LoginFormPasswordInput
                    ]
                    []
                ]
            , div []
                [ label [] []
                , button [ type_ "submit" ] [ text "Login" ]
                ]
            ]
        ]


uploadPageView : UploadPageModel -> Html Msg
uploadPageView model =
    div []
        [ Html.form [ class "login-form", onSubmit NoOp ]
            [ fieldset []
                [ legend [] [ text "Upload form" ]
                , div []
                    [ button [ onClick StartCapture ] [ text "retake" ]
                    ]
                , div []
                    [ label [] [ text "file" ]
                    , input
                        [ type_ "file"
                        ]
                        []
                    ]
                , div []
                    [ label [] [ text "date" ]
                    , input
                        [ type_ "date"
                        ]
                        []
                    ]
                , div []
                    [ label [] [ text "type" ]
                    , select []
                        (typeToSelectOptions
                            types
                            999
                        )
                    ]
                , div []
                    [ label [] [ text "Amount" ]
                    , input
                        [ type_ "number"
                        ]
                        []
                    ]
                , div []
                    [ label [] [ text "Description" ]
                    , input
                        [ type_ "text"
                        ]
                        []
                    ]
                , div []
                    [ label [] []
                    , button [ type_ "submit" ] [ text "Save" ]
                    ]
                ]
            ]
        , if model.isCapturing then
            capturePageView
          else
            text ""
        ]


settingsPageView : SettingsPageModel -> Html Msg
settingsPageView model =
    div []
        [ text "settings page"
        ]


listPageView : ListPageModel -> Html Msg
listPageView model =
    div []
        [ text "Fake list"
        , ul [] (List.map (\item -> li [] [ text item.name ]) model.items)
        ]


capturePageView : Html Msg
capturePageView =
    div []
        [ video [ id "video", class "camera-video" ] []
        , canvas [ id "canvas", class "canvas" ] []
        , button [ id "capture", class "camera-capture" ] []
        ]


updateCaptureStatus : Bool -> UploadPageModel -> UploadPageModel
updateCaptureStatus status page =
    { page | isCapturing = status }


typeToSelectOptions : List Type -> Int -> List (Html Msg)
typeToSelectOptions types selectedID =
    List.map (\item -> option [ value <| toString item.id, selected (selectedID == item.id) ] [ text item.label ]) types



-- HTTTP


loginRequest : String -> String -> Cmd Msg
loginRequest user password =
    let
        req =
            Http.request
                { method = "POST"
                , body = loginEncoder user password |> Http.jsonBody
                , url = "https://reqres.in/api/login/"
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
            ]
    in
        Encode.object params


loginDecoder : Decode.Decoder Token
loginDecoder =
    Decode.at [ "token" ] Decode.string


listRequest : Token -> Cmd Msg
listRequest token =
    let
        req =
            Http.request
                { method = "GET"
                , body = Http.emptyBody
                , url = "https://jsonplaceholder.typicode.com/comments"
                , expect = Http.expectJson listDecoder
                , headers = []
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.send ListResponse req


listDecoder : Decode.Decoder (List Item)
listDecoder =
    Decode.list listItemDecoder


listItemDecoder : Decode.Decoder Item
listItemDecoder =
    decode Item
        |> Json.Decode.Pipeline.required "postId" Decode.int
        |> Json.Decode.Pipeline.required "id" Decode.int
        |> Json.Decode.Pipeline.required "name" Decode.string
        |> Json.Decode.Pipeline.required "body" Decode.string
