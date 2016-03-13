module Game where

import Color exposing (..)
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Keyboard exposing (..)
import Time exposing (..)
import Text
import Window

-- Render

render : (Int, Int) -> GameState -> Element
render (w, h) gameState =
  -- later: figure out why height dimension does not seem to work
  -- later: remove duplication of height

  -- todo:
  -- make the ship look in the direction of flight when no inputs are made
  -- add direction arrows
  -- directionToTheSun rounds the numbers because % can't handle floats, this probably introduces some errors
  -- figure out a co-ordinate system, size for sun, gravity, etc based on real numbers
     -- gravity acceleration based on distance
  -- add planets
  -- handle multiple inputs at the same time
  -- add space dust to show movement
  -- add thruster active animation
  -- useful for planets and sun, maybe in combination with textures http://elm-lang.org/examples/radial-gradient
  -- add turn sluggishness, starting and stopping

  collage 600 600 [
    renderBackground (w, h) gameState
  , renderDirectionIndicators gameState
  , renderShip gameState
  ]


renderBackground (w, h) gameState =
  collage w 600 [
    square 600
    |> filled black
  , gradient grad1 (circle 300)
    |> move (gameState.x, gameState.y)
  --, renderSpaceDust gameState
  ]
  |> toForm

renderDirectionIndicators gameState =
  let
    sunDirection = directionToTheSun gameState
    sunDistance = distanceTo (0, 0) gameState
    sunDv = (gameState.vx |> round |> abs) + (gameState.vy |> round |> abs)
    -- better indicator:
    -- where is the intersection with edge of screen?
    -- or: show arrow?
    text = "Sun direction: " ++ (toString (sunDirection |> round)) ++ ", distance: " ++ (sunDistance |> round |> toString) ++ ", relative speed: " ++ (sunDv |> toString)
  in
    if sunDistance > 650 then
      [ renderText (0, 280) text
      , renderText (0, 280 - 16) ("Your direction: " ++ (gameState.direction |> round |> toString))
     ]
     |> group
    else
      -- todo: render nothing
      renderSpaceDust gameState

renderSpaceDust gameState =
  [
    circle 1
    |> filled gray
    |> move (100 + gameState.x, 85 + gameState.y)
  ]
  |> group

renderShip gameState =
  let
    texture = if gameState.engineRunning then "ship_on" else "ship_off"
  in
    image 50 80 ("/images/" ++ texture ++ ".png")
    |> toForm
    |> rotate (degrees gameState.direction)

renderText (x, y) text =
  Text.fromString text
  |> Text.height 16
  |> Text.color white
  |> Text.monospace
  |> rightAligned
  |> toForm
  |> moveX x
  |> moveY y

grad1 : Gradient
grad1 =
  radial (0,0) 50 (0,10) 280
    [ (  0, rgb  244 242 1)
    , (0.8, rgb  228 199 0)
    , (  1, rgba 228 199 0 0)
    ]

-- Update

update : Input -> GameState -> GameState
update input gameState =
  gameState
  |> applyInputs input
  |> applyMovement input
  |> applySolarGravity input
  |> applyLookingAtSun input

applyInputs input gameState =
  let
    degreesPerSecond = (360 * input.delta) / 2
  in
    if input.turnDirection == 1 then
      { gameState | direction = (normalizeDirection gameState.direction - degreesPerSecond)}
    else if input.turnDirection == -1 then
      { gameState | direction = (normalizeDirection gameState.direction + degreesPerSecond)}
    else if input.thrustDirection == 1 then
      { gameState |
        vy = gameState.vy - 100 * (gameState.direction |> degrees |> cos) * input.delta
      , vx = gameState.vx + 100 * (gameState.direction |> degrees |> sin) * input.delta
      , engineRunning = True
      }
    else
      { gameState | engineRunning = False }

applyMovement input gameState =
  { gameState |
    y = gameState.y + gameState.vy * input.delta
  , x = gameState.x + gameState.vx * input.delta
  }

applySolarGravity input gameState =
  { gameState |
    vy = gameState.vy - 50 * (gameState |> directionToTheSun |> degrees |> cos) * input.delta
  , vx = gameState.vx + 50 * (gameState |> directionToTheSun |> degrees |> sin) * input.delta
  }

applyLookingAtSun input gameState =
  let
    newDirection = gameState.direction - ((gameState.direction - (directionToTheSun gameState)) * 0.5 * input.delta)
  in
    if playerIsChangingSpeedOrDirection input then
      gameState
    else
      { gameState |
        direction = (normalizeDirection newDirection)
      }

playerIsChangingSpeedOrDirection input =
  input.turnDirection /= 0 || input.thrustDirection /= 0

directionToTheSun gameState =
  let
    temp = (360 - (180 / pi) * (atan2 gameState.x  gameState.y)) |> round
  in
    (temp % 360) |> normalizeDirection

-- Generic maths

distanceTo (targetX, targetY) gameState =
  let
    xDiff = targetX - gameState.x
    yDiff = targetY - gameState.y
  in
    sqrt (xDiff^2 + yDiff^2)

normalizeDirection direction =
  if direction > 360 then
     360 - direction
  else if direction < 0 then
     direction + 360
  else
     direction

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
  { x : Float, y : Float, vx : Float, vy : Float, direction: Float, engineRunning: Bool }

type alias Input =
  { fire : Bool
  , turnDirection : Int
  , thrustDirection : Int
  , delta : Time
  }
