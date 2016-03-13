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
  -- handle multiple inputs at the same time
  -- add space dust to show movement
  -- add thruster active animation
  -- useful for planets and sun, maybe in combination with textures http://elm-lang.org/examples/radial-gradient
  -- add turn sluggishness, starting and stopping

  collage w 600 [
    renderBackground (w, h) gameState
  , renderText (w, h) gameState
  , renderShip gameState
  ]


renderBackground (w, h) gameState =
  -- this is laggy
  --croppedImage (round gameState.x, round gameState.y) 600 600 "images/background1.jpg"
  --|> toForm

  collage w 600 [
    square 600
    |> filled black
  , gradient grad1 (circle 100)
    |> move (200 + gameState.x, 85 + gameState.y)
  , renderSpaceDust gameState
  ]
  |> toForm

renderSpaceDust gameState =
  [
    circle 1
    |> filled gray
    |> move (100 + gameState.x, 85 + gameState.y)
  ]
  |> group

grad1 : Gradient
grad1 =
  radial (0,0) 50 (0,10) 90
    [ (  0, rgb  244 242 1)
    , (0.8, rgb  228 199 0)
    , (  1, rgba 228 199 0 0)
    ]

renderText (w, h) gameState =
  Text.fromString (toString (gameState))
    |> Text.height 16
    |> Text.color white
    |> Text.monospace
    |> rightAligned
    |> toForm
    |> moveY (-(600/2) + 25)
    --|> moveX (-(600/2) + 40)

renderShip gameState =
  [ (polygon [ (-25.0, -25.0), (0.0, 0.0), (25.0, -25.0) ])
    |> filled darkBlue
    |> moveY 50
  , square 50
    |> filled blue
  ]
  |> group
  |> rotate (degrees gameState.direction)

update : Input -> GameState -> GameState
update input gameState =
  gameState
  |> applyInputs input
  |> applyMovement input

applyInputs input gameState =
  let
    degreesPerSecond = (360 * input.delta) / 2
  in
    if input.turnDirection == 1 then
      { gameState | direction = gameState.direction - degreesPerSecond}
    else if input.turnDirection == -1 then
      { gameState | direction = gameState.direction + degreesPerSecond}
    else if input.thrustDirection == 1 then
      { gameState |
        vy = gameState.vy - 100 * (gameState.direction |> degrees |> cos) * input.delta
      , vx = gameState.vx + 100 * (gameState.direction |> degrees |> sin) * input.delta
      }
    else
      gameState

applyMovement input gameState =
  { gameState |
    y = gameState.y + gameState.vy * input.delta
  , x = gameState.x + gameState.vx * input.delta
  }

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

-- delta corresponds to the amount of change per second,
-- e.g. if FPS is 1, then delta is 1, if FPS is 2, delta is 0.5.
delta =
  Signal.map inSeconds (fps 60)

port stateChange : Signal GameState
port stateChange =
  gameState

port initialGameState : GameState

main =
  Signal.map2 render Window.dimensions gameState

type alias GameState =
  { x : Float, y : Float, vx : Float, vy : Float, direction: Float }

type alias Input =
  { fire : Bool
  , turnDirection : Int
  , thrustDirection : Int
  , delta : Time
  }
