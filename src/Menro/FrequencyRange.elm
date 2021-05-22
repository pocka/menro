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


module Menro.FrequencyRange exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Json.Decode as Decode


type FrequencyRange
    = Basic
    | Wide
    | Octave
    | Piano


a0 : Float
a0 =
    27.5


c3 : Float
c3 =
    130.81


c4 : Float
c4 =
    261.63


c8 : Float
c8 =
    4186.01


basicMax : Float
basicMax =
    1000


wideMax : Float
wideMax =
    4000


getFrequency : FrequencyRange -> Float -> Float
getFrequency range source =
    case range of
        Basic ->
            source * basicMax

        Wide ->
            source * wideMax

        Octave ->
            (c4 - c3) * source + c3

        Piano ->
            (c8 - a0) * source + a0


frequencyMin : FrequencyRange -> Float
frequencyMin range =
    case range of
        Basic ->
            0

        Wide ->
            0

        Octave ->
            c3

        Piano ->
            a0


frequencyLimit : FrequencyRange -> Float
frequencyLimit range =
    case range of
        Basic ->
            basicMax

        Wide ->
            wideMax

        Octave ->
            c4

        Piano ->
            c8


toLabelString : FrequencyRange -> String
toLabelString range =
    case range of
        Basic ->
            "Basic (0Hz ~ " ++ String.fromFloat basicMax ++ "Hz)"

        Wide ->
            "Wide (0Hz ~ " ++ String.fromFloat wideMax ++ "Hz)"

        Octave ->
            "Octave (C3:C4, " ++ String.fromFloat c3 ++ "Hz ~ " ++ String.fromFloat c4 ++ "Hz)"

        Piano ->
            "Piano (A0:C8, " ++ String.fromFloat a0 ++ "Hz ~ " ++ String.fromFloat c8 ++ "Hz)"


toString : FrequencyRange -> String
toString range =
    case range of
        Basic ->
            "basic"

        Wide ->
            "wide"

        Octave ->
            "octave"

        Piano ->
            "piano"


fromString : String -> Maybe FrequencyRange
fromString str =
    case str of
        "basic" ->
            Just Basic

        "wide" ->
            Just Wide

        "octave" ->
            Just Octave

        "piano" ->
            Just Piano

        _ ->
            Nothing


onSelect : (Maybe FrequencyRange -> msg) -> Attribute msg
onSelect f =
    on "change" (Decode.map (\s -> fromString s |> f) (Decode.at [ "currentTarget", "value" ] Decode.string))


selectBox : List (Attribute msg) -> FrequencyRange -> Html msg
selectBox attrs range =
    select (value (toString range) :: attrs)
        [ option [ value (toString Basic), selected (range == Basic) ] [ text (toLabelString Basic) ]
        , option [ value (toString Wide), selected (range == Wide) ] [ text (toLabelString Wide) ]
        , option [ value (toString Octave), selected (range == Octave) ] [ text (toLabelString Octave) ]
        , option [ value (toString Piano), selected (range == Piano) ] [ text (toLabelString Piano) ]
        ]
