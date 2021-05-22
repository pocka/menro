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


module Menro.WaveType exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Json.Decode as Decode


type WaveType
    = Sine
    | Square
    | Sawtooth


toString : WaveType -> String
toString t =
    case t of
        Sine ->
            "sine"

        Square ->
            "square"

        Sawtooth ->
            "sawtooth"


fromString : String -> Maybe WaveType
fromString s =
    case s of
        "sine" ->
            Just Sine

        "square" ->
            Just Square

        "sawtooth" ->
            Just Sawtooth

        _ ->
            Nothing


onSelect : (Maybe WaveType -> msg) -> Attribute msg
onSelect f =
    on "change" (Decode.map (\s -> fromString s |> f) (Decode.at [ "currentTarget", "value" ] Decode.string))


selectBox : List (Attribute msg) -> WaveType -> Html msg
selectBox attrs range =
    select (value (toString range) :: attrs)
        [ option [ value (toString Sine), selected (range == Sine) ] [ text "Sine wave" ]
        , option [ value (toString Square), selected (range == Square) ] [ text "Square wave" ]
        , option [ value (toString Sawtooth), selected (range == Sawtooth) ] [ text "Sawtooth wave" ]
        ]
