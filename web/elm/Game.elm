module Game where

import Color exposing (..)
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Keyboard exposing (..)
import Time exposing (..)
import Text
import Window

-- Render and update

render : (Int, Int) -> GameState -> Element
render (w, h) gameState =
  -- later: figure out why height dimension does not seem to work
  -- later: remove duplication of height

  -- todo:
  -- add rotation and
  -- add thruster active animation
  -- add add basic background stars

  collage w 500 [
    renderBackground
  , renderText (w, h) gameState
  , renderShip gameState
  ]

renderBackground =
  square 500
  |> filled black

renderText (w, h) gameState =
  Text.fromString (toString h)
    |> Text.height 25
    |> Text.color white
    |> leftAligned
    |> toForm
    |> moveY (-(500/2) + 25)
    |> moveX (-(500/2) + 25)

renderShip gameState =
  [ (polygon [ (-25.0, -25.0), (0.0, 0.0), (25.0, -25.0) ])
    |> filled darkBlue
    |> moveX gameState.x
    |> moveY (gameState.y + 50)
  , square 50
    |> filled blue
    |> moveX gameState.x
    |> moveY gameState.y
  ]
  |> group

update : Input -> GameState -> GameState
update input gameState =
  if input.turnDirection == 1 then
    { gameState | x = gameState.x + 5 }
  else if input.thrustDirection == 1 then
    { gameState | y = gameState.y + 5 }
  else
    gameState

-- Support code

gameState : Signal GameState
gameState =
  Signal.foldp update initialGameState input

input : Signal Input
input =
  Signal.sampleOn delta <|
    Signal.map4 Input
      Keyboard.space -- # fire
      (Signal.map .x Keyboard.wasd) -- turn direction
      (Signal.map .y Keyboard.wasd) -- thrust direction
      delta

delta =
  Signal.map inSeconds (fps 35)

port stateChange : Signal GameState
port stateChange =
  gameState

port initialGameState : GameState

main =
  Signal.map2 render Window.dimensions gameState

type alias GameState =
  { x : Float, y : Float, direction: Float }

type alias Input =
  { fire : Bool
  , turnDirection : Int
  , thrustDirection : Int
  , delta : Time
  }
