module Route.Foobar exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import BackendTask.File as File
import Effect
import ErrorPage
import FatalError
import Form
import Form.Field
import Form.FieldView
import Form.Handler
import Form.Validation
import Head
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Pages.Form
import Pages.Script
import PagesMsg
import RouteBuilder
import Server.Request
import Server.Response
import Shared
import UrlPath
import View


type alias Model =
    {}


type Msg
    = NoOp


type alias RouteParams =
    {}


route : RouteBuilder.StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.serverRender { data = data, action = action, head = head }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


init :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect.Effect Msg )
init app shared =
    ( {}, Effect.none )


update :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect.Effect Msg )
update app shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )


subscriptions : RouteParams -> UrlPath.UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none


type alias Data =
    {}


type alias ActionData =
    { errors : Form.ServerResponse String }


data :
    RouteParams
    -> Server.Request.Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response Data ErrorPage.ErrorPage)
data routeParams request =
    File.rawFile "file-that-does-not-exist"
        |> BackendTask.onError
            (\{ fatal } ->
                -- The .body string inside of `fatal` contain ANSI escape codes.
                -- Log it out, but not with `Debug.log`, as it apparently does some kind of 'filter
                -- out illegal characters' preprocessing that obscures the issue.
                [ ( "onError fatal", Encode.string (Debug.toString fatal) )
                , ( "--", Encode.string "When deployed, the *exact* same fatal.body string is given to ErrorPage, wrapped in ErrorPage.InternalError" )
                ]
                    |> Encode.object
                    |> Encode.encode 4
                    |> Pages.Script.log
                    |> BackendTask.andThen
                        (\_ ->
                            BackendTask.fail (FatalError.fromString "boom")
                        )
            )
        |> BackendTask.andThen
            (\_ ->
                BackendTask.succeed (Server.Response.render {})
            )


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head app =
    []


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View.View (PagesMsg.PagesMsg Msg)
view app shared model =
    { title = "Foobar"
    , body =
        [ Html.h2 [] [ Html.text "Form" ]
        , Pages.Form.renderHtml
            []
            (Form.withServerResponse
                (Maybe.map .errors app.action)
                (Form.options "form")
            )
            app
            form
        ]
    }


action :
    RouteParams
    -> Server.Request.Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action routeParams request =
    Maybe.withDefault
        (BackendTask.fail (FatalError.fromString "Expected form post"))
        (Maybe.map
            (\formData ->
                case formData of
                    ( response_1_0_1_2_0_0, parsedForm_1_1_0_1_2_0_0 ) ->
                        case parsedForm_1_1_0_1_2_0_0 of
                            Form.Valid validatedForm ->
                                case validatedForm of
                                    Action parsed ->
                                        BackendTask.map
                                            (\_ ->
                                                Server.Response.render
                                                    { errors =
                                                        response_1_0_1_2_0_0
                                                    }
                                            )
                                            (Pages.Script.log
                                                (Encode.encode
                                                    2
                                                    (Encode.object
                                                        [ ( "Sprocket"
                                                          , Encode.string
                                                                parsed.sprocket
                                                          )
                                                        ]
                                                    )
                                                )
                                            )

                            Form.Invalid parsed error ->
                                BackendTask.map
                                    (\_ ->
                                        Server.Response.render
                                            { errors = response_1_0_1_2_0_0 }
                                    )
                                    (Pages.Script.log
                                        "Form validations did not succeed!"
                                    )
            )
            (Server.Request.formData formHandlers request)
        )


errorsView :
    Form.Errors String
    -> Form.Validation.Field String parsed kind
    -> Html.Html (PagesMsg.PagesMsg Msg)
errorsView errors field =
    if List.isEmpty (Form.errorsForField field errors) then
        Html.div [] []

    else
        Html.div
            []
            [ Html.ul
                []
                (List.map
                    (\error ->
                        Html.li
                            [ Html.Attributes.style "color" "red" ]
                            [ Html.text error ]
                    )
                    (Form.errorsForField field errors)
                )
            ]


form : Form.HtmlForm String ParsedForm input (PagesMsg.PagesMsg Msg)
form =
    (\sprocket ->
        { combine =
            ParsedForm
                |> Form.Validation.succeed
                |> Form.Validation.andMap sprocket
        , view =
            \formState ->
                let
                    fieldView label field =
                        Html.div
                            []
                            [ Html.label
                                []
                                [ Html.text (label ++ " ")
                                , Form.FieldView.input [] field
                                , errorsView formState.errors field
                                ]
                            ]
                in
                [ fieldView "Sprocket" sprocket
                , if formState.submitting then
                    Html.button
                        [ Html.Attributes.disabled True ]
                        [ Html.text "Submitting..." ]

                  else
                    Html.button [] [ Html.text "Submit" ]
                ]
        }
    )
        |> Form.form
        |> Form.hiddenKind ( "kind", "regular" ) "Expected kind."
        |> Form.field
            "Sprocket"
            (Form.Field.text |> Form.Field.required "Required")


type Action
    = Action ParsedForm


formHandlers : Form.Handler.Handler String Action
formHandlers =
    Form.Handler.init Action form


type alias ParsedForm =
    { sprocket : String }
