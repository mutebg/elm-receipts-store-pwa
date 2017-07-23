port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import LoginPage as PLogin exposing (..)
import ListPage as PList exposing (..)
import UploadPage as PUpload exposing (..)
import Data exposing (..)


-- APP


main : Program Never Model Msg
main =
    Html.program { init = init, view = view, update = update, subscriptions = subscriptions }


type alias Model =
    { page : Page
    , loginPage : PLogin.Model
    , uploadPage : PUpload.Model
    , listPage : PList.Model
    }


init : ( Model, Cmd Msg )
init =
    ( model, Cmd.none )


model : Model
model =
    { page = LoginPage
    , loginPage = PLogin.model
    , uploadPage = PUpload.model
    , listPage = PList.model
    }


type Page
    = NotFound
    | UploadPage
    | ListPage
    | LoginPage



-- SUBSCRIBTION


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        loginSub =
            PLogin.subscriptions model.loginPage

        uploadSub =
            PUpload.subscriptions model.uploadPage
    in
        Sub.batch
            [ Sub.map LoginPageMsg loginSub
            , Sub.map UploadPageMsg uploadSub
            ]



-- UPDATE


type Msg
    = SetPage Page
    | LoginPageMsg PLogin.Msg
    | UploadPageMsg PUpload.Msg
    | ListPageMsg PList.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetPage newPage ->
            let
                cmd =
                    case newPage of
                        ListPage ->
                            case model.loginPage.token of
                                Just token ->
                                    Cmd.map ListPageMsg (PList.listRequest token)

                                _ ->
                                    Cmd.none

                        _ ->
                            Cmd.none
            in
                ( { model | page = newPage }, cmd )

        LoginPageMsg msg ->
            let
                ( newModel, cmd ) =
                    PLogin.update msg model.loginPage

                newPage =
                    case msg of
                        ReceiveToken t ->
                            UploadPage

                        LoginResponse (Ok t) ->
                            UploadPage

                        _ ->
                            model.page
            in
                ( { model | loginPage = newModel, page = newPage }
                , Cmd.map LoginPageMsg cmd
                )

        UploadPageMsg msg ->
            let
                ( newModel, cmd ) =
                    PUpload.update msg model.uploadPage model.loginPage.token
            in
                ( { model | uploadPage = newModel }
                , Cmd.map UploadPageMsg cmd
                )

        ListPageMsg msg ->
            let
                ( newModel, cmd ) =
                    PList.update msg model.listPage
            in
                ( { model | listPage = newModel }
                , Cmd.map ListPageMsg cmd
                )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [ class "nav" ]
            [ button [ onClick (SetPage LoginPage) ] [ text "login" ]
            , button [ onClick (SetPage ListPage) ] [ text "List" ]
            , button [ onClick (SetPage UploadPage) ] [ text "upload" ]
            ]
        , case model.page of
            LoginPage ->
                Html.map LoginPageMsg
                    (PLogin.view model.loginPage)

            UploadPage ->
                Html.map UploadPageMsg
                    (PUpload.view model.uploadPage)

            ListPage ->
                Html.map ListPageMsg
                    (PList.view model.listPage)

            _ ->
                div [] [ text "no page" ]
        ]
