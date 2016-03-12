module Game where

import Color exposing (..)
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Keyboard exposing (..)

main =
  collage 500 250 [
    square 10
    |> filled color
  ]

color : Color
color =
  rgba 000 150 255 0.8
