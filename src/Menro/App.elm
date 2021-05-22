-- Menro is a toy instrument application.
-- Copyright (C) 2021  Shota Fuji
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.


port module Menro.App exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Menro.FrequencyRange as FrequencyRange exposing (FrequencyRange)
import Menro.WaveType as WaveType exposing (WaveType)



-- MAIN


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


port updateSoundState : Encode.Value -> Cmd msg


port pointerUpOutsideOfTheApp : (() -> msg) -> Sub msg



-- MODEL


type InteractionState
    = Idle
    | Touching


type alias SoundState =
    { id : String
    , level : Float -- Audio level, 0.0 to 1.0
    , freq : Float -- Frequency in Hz
    , waveType : WaveType
    }


type Dialog
    = Visible
    | Hidden


type AxisMode
    = XLevelYFreq -- X = Level (asc), Y = Freq (asc)
    | XFreqYLevel -- X = Freq (asc), Y = Level (asc)


type alias Model =
    { state : InteractionState
    , sounds : List SoundState
    , optionsDialog : Dialog
    , frequencyRange : FrequencyRange
    , waveType : WaveType
    , repositoryUrl : Maybe String
    , debug : Bool
    , axisMode : AxisMode
    }


decodeRepositoryUrlFlag : Decode.Value -> Maybe String
decodeRepositoryUrlFlag value =
    value
        |> Decode.decodeValue (Decode.field "repositoryUrl" Decode.string)
        |> Result.toMaybe


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    ( { state = Idle
      , sounds = []
      , optionsDialog = Hidden
      , frequencyRange = FrequencyRange.Basic
      , waveType = WaveType.Sine
      , repositoryUrl = decodeRepositoryUrlFlag flags
      , debug = False
      , axisMode = XLevelYFreq
      }
    , Cmd.none
    )



-- UPDATE


encodeSoundState : SoundState -> Encode.Value
encodeSoundState source =
    Encode.object [ ( "id", Encode.string source.id ), ( "freq", Encode.float source.freq ), ( "level", Encode.float source.level ), ( "waveType", source.waveType |> WaveType.toString |> Encode.string ) ]


type alias SoundSource =
    { id : String
    , freq : Float -- 0.0 ~ 1.0
    , level : Float -- 0.0 ~ 1.0
    }


toSoundState : FrequencyRange -> WaveType -> SoundSource -> SoundState
toSoundState range wave source =
    { id = source.id
    , level = source.level
    , freq = FrequencyRange.getFrequency range source.freq
    , waveType = wave
    }


type Msg
    = Noop
    | UpdateTouchForce Float
    | SetSound (List SoundSource)
    | ShowOptions
    | HideOptions
    | SetFrequencyRange FrequencyRange
    | SetWaveType WaveType
    | ToggleDebugMode
    | SetAxisMode AxisMode


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        UpdateTouchForce force ->
            ( { model
                | state =
                    if force > 0.0 then
                        Touching

                    else
                        Idle
              }
            , Cmd.none
            )

        SetSound sounds ->
            let
                states =
                    sounds
                        |> List.map (toSoundState model.frequencyRange model.waveType)
            in
            ( { model | sounds = states }, updateSoundState (Encode.list encodeSoundState states) )

        SetFrequencyRange range ->
            ( { model | frequencyRange = range }, Cmd.none )

        SetWaveType t ->
            ( { model | waveType = t }, Cmd.none )

        ShowOptions ->
            ( { model | optionsDialog = Visible, sounds = [] }, Cmd.none )

        HideOptions ->
            ( { model | optionsDialog = Hidden }, Cmd.none )

        ToggleDebugMode ->
            ( { model | debug = not model.debug }, Cmd.none )

        SetAxisMode mode ->
            ( { model | axisMode = mode }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    pointerUpOutsideOfTheApp (\_ -> SetSound [])



-- VIEW


mouseId : String
mouseId =
    "mouse"


mousePositionDecoder : Decode.Decoder ( Int, Int )
mousePositionDecoder =
    Decode.map2 (\x -> \y -> ( x, y ))
        (Decode.field "offsetX" Decode.int)
        (Decode.field "offsetY" Decode.int)


eventTargetSizeDecoder : Decode.Decoder ( Int, Int )
eventTargetSizeDecoder =
    Decode.map2 (\width -> \height -> ( width, height ))
        (Decode.at [ "currentTarget", "clientWidth" ] Decode.int)
        (Decode.at [ "currentTarget", "clientHeight" ] Decode.int)


type ButtonState
    = Pressed
    | NotPressed


buttonStateDecoder : Decode.Decoder ButtonState
buttonStateDecoder =
    Decode.map
        (\state ->
            if state == 0 then
                NotPressed

            else
                Pressed
        )
        (Decode.field "buttons" Decode.int)


between : comparable -> comparable -> comparable -> comparable
between min max v =
    Basics.max min (Basics.min max v)


mouseEventDecoder : AxisMode -> Decode.Decoder Msg
mouseEventDecoder axisMode =
    Decode.map3
        (\( x, y ) ->
            \( w, h ) ->
                \buttonState ->
                    let
                        x2 =
                            toFloat x
                                / toFloat w
                                |> between 0.0 1.0

                        y2 =
                            toFloat y
                                / toFloat h
                                |> between 0.0 1.0

                        ( level, freq ) =
                            case axisMode of
                                XLevelYFreq ->
                                    ( x2, 1 - y2 )

                                XFreqYLevel ->
                                    ( 1 - y2, x2 )
                    in
                    if buttonState == NotPressed || level == 0 then
                        SetSound []

                    else
                        SetSound
                            [ { id = mouseId
                              , level = level
                              , freq = freq
                              }
                            ]
        )
        mousePositionDecoder
        eventTargetSizeDecoder
        buttonStateDecoder


type alias TouchObject =
    { id : String
    , clientX : Int
    , clientY : Int
    }


touchObjectDecoder : Decode.Decoder TouchObject
touchObjectDecoder =
    Decode.map3 TouchObject
        (Decode.map String.fromInt (Decode.field "identifier" Decode.int))
        (Decode.map round (Decode.field "clientX" Decode.float))
        (Decode.map round (Decode.field "clientY" Decode.float))


elementClientPositionDecoder : Decode.Decoder ( Float, Float )
elementClientPositionDecoder =
    Decode.map2 (\left -> \top -> ( left, top ))
        (Decode.at [ "currentTarget", "offsetLeft" ] Decode.float)
        (Decode.at [ "currentTarget", "offsetTop" ] Decode.float)


{-| <https://github.com/mpizenberg/elm-pointer-events/blob/master/src/Internal/Decode.elm#L26>
-}
arrayLikeDecoder : Decode.Decoder a -> Decode.Decoder (List a)
arrayLikeDecoder decoder =
    Decode.field "length" Decode.int
        |> Decode.andThen
            (\length ->
                List.range 0 (length - 1)
                    |> List.map (\i -> Decode.field (String.fromInt i) decoder)
                    |> List.foldr (Decode.map2 (::)) (Decode.succeed [])
            )


touchEventDecoder : AxisMode -> Decode.Decoder Msg
touchEventDecoder axisMode =
    Decode.field "touches" (arrayLikeDecoder touchObjectDecoder)
        |> Decode.map3
            (\( x, y ) ->
                \( w, h ) ->
                    List.map
                        (\touch ->
                            let
                                x2 =
                                    (toFloat touch.clientX - x)
                                        / toFloat w
                                        |> between 0.0 1.0

                                y2 =
                                    (toFloat touch.clientY - y)
                                        / toFloat h
                                        |> between 0.0 1.0

                                ( level, freq ) =
                                    case axisMode of
                                        XLevelYFreq ->
                                            ( x2, 1 - y2 )

                                        XFreqYLevel ->
                                            ( 1 - y2, x2 )
                            in
                            { id = touch.id, level = level, freq = freq }
                        )
            )
            elementClientPositionDecoder
            eventTargetSizeDecoder
        |> Decode.map SetSound


touchHandlers : AxisMode -> List (Attribute Msg)
touchHandlers axisMode =
    [ Events.on "mousemove" (mouseEventDecoder axisMode)
    , Events.on "mousedown" (mouseEventDecoder axisMode)
    , Events.on "mouseup" (mouseEventDecoder axisMode)
    , Events.preventDefaultOn "touchstart" (Decode.map (\msg -> ( msg, True )) (touchEventDecoder axisMode))
    , Events.preventDefaultOn "touchmove" (Decode.map (\msg -> ( msg, True )) (touchEventDecoder axisMode))
    , Events.preventDefaultOn "touchend" (Decode.map (\msg -> ( msg, True )) (touchEventDecoder axisMode))
    ]


touchArea : Model -> Html Msg
touchArea model =
    List.repeat (5 * 5) ()
        |> List.map (\_ -> div [ class "app-toucharea-cell" ] [])
        |> div
            (List.concat
                [ [ class "app-toucharea"
                  , if model.state == Touching then
                        style "background-color" "red"

                    else
                        class ""
                  ]
                , touchHandlers model.axisMode
                ]
            )


type Axis
    = Level
    | Frequency


axisClass : AxisMode -> Axis -> Attribute msg
axisClass mode axis =
    case ( mode, axis ) of
        ( XLevelYFreq, Level ) ->
            class "app-axis-x"

        ( XFreqYLevel, Level ) ->
            class "app-axis-y"

        ( XLevelYFreq, Frequency ) ->
            class "app-axis-y"

        ( XFreqYLevel, Frequency ) ->
            class "app-axis-x"


view : Model -> Html Msg
view model =
    div []
        [ div [ class "app-toucharea-wrapper" ]
            [ touchArea model
            , p [ axisClass model.axisMode Level ] [ text "Volume (0%~100%) ->" ]
            , p [ axisClass model.axisMode Frequency ] [ text ("Frequency (" ++ (model.frequencyRange |> FrequencyRange.frequencyMin |> String.fromFloat) ++ "Hz~" ++ (FrequencyRange.frequencyLimit model.frequencyRange |> String.fromFloat) ++ "Hz) ->") ]
            ]
        , button
            [ class "app-options-button"
            , Events.onClick ShowOptions
            ]
            [ text "Options"
            ]
        , if model.optionsDialog == Visible then
            div []
                [ div [ class "app-modal app-options-items", Events.stopPropagationOn "click" (Decode.succeed ( Noop, True )) ]
                    [ div [ class "app-field" ]
                        [ label [ for "freq_range", class "app-label" ] [ text "Frequency range" ]
                        , FrequencyRange.selectBox
                            [ class "app-selectbox"
                            , FrequencyRange.onSelect
                                (\r ->
                                    r
                                        |> Maybe.map SetFrequencyRange
                                        |> Maybe.withDefault Noop
                                )
                            ]
                            model.frequencyRange
                        ]
                    , div [ class "app-field" ]
                        [ label [ for "wave_type", class "app-label" ] [ text "Wave type" ]
                        , WaveType.selectBox
                            [ class "app-selectbox"
                            , WaveType.onSelect (\r -> r |> Maybe.map SetWaveType |> Maybe.withDefault Noop)
                            ]
                            model.waveType
                        ]
                    , div [ class "app-field" ]
                        [ label [ for "axis_mode", class "app-label" ] [ text "Swap axis" ]
                        , input
                            [ id "axis_mode"
                            , type_ "checkbox"
                            , checked (model.axisMode == XFreqYLevel)
                            , Events.onCheck
                                (\checked ->
                                    SetAxisMode
                                        (if checked then
                                            XLevelYFreq

                                         else
                                            XFreqYLevel
                                        )
                                )
                            ]
                            []
                        ]
                    , div [ class "app-field" ]
                        [ label [ for "debug_mode", class "app-label" ] [ text "Debug mode" ]
                        , input [ id "debug_mode", type_ "checkbox", checked model.debug, Events.onCheck (\_ -> ToggleDebugMode) ] []
                        ]
                    , case model.repositoryUrl of
                        Just repositoryUrl ->
                            a [ href repositoryUrl, target "_blank", class "app-link" ] [ text "Source code" ]

                        Nothing ->
                            node "noscript" [] []
                    , a [ href "oss-license.txt", target "_blank", class "app-link" ] [ text "OSS Licenses" ]
                    , button [ class "app-button", Events.onClick HideOptions ] [ text "Close" ]
                    ]
                , div
                    [ class "app-modal-backdrop"
                    , Events.onClick HideOptions
                    ]
                    []
                ]

          else
            node "noscript" [] []
        , if model.debug then
            ul [ class "app-debug" ]
                (List.map
                    (\sound ->
                        li []
                            [ dl []
                                [ dd [] [ text ("Frequency(Hz) = " ++ (sound.freq |> String.fromFloat)) ]
                                , dt [] [ text ("Level(%) = " ++ (sound.level |> (*) 100 |> round |> String.fromInt)) ]
                                ]
                            ]
                    )
                    model.sounds
                )

          else
            node "noscript" [] []
        ]
