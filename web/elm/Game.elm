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

  -- todo

  -- Multiplayer
    -- set up "ping" to server, print on screen
      -- get player-id
      -- set nickname
      -- possibly js-only, push ping, id and nickname into Elm?
        -- simple html form to ask for nickname
    -- refactor player, considering multiplay
      -- controll own player-id with local controls?
      -- players [ { x = 1, id = 0 }, ]
    -- publish control inputs
    -- publish initial and periodical x,y,vx,vy,direction updates
    -- subscribe to other players data updates (periodical updates)
    -- subscribe to other players control inputs (smooth changes)

  -- Gameplay: environment
    -- gravity acceleration based on distance/mass?
    -- handle multiple inputs at the same time
    -- add space dust to show movement
    -- add planets
    -- add turn sluggishness, starting and stopping
    -- add direction arrows (next to minis of each thing?)
    -- make the ship look in the direction of flight when no inputs are made
    -- directionToTheSun rounds the numbers because % can't handle floats, this probably introduces some errors
    -- NPCs?

  -- Gameplay: actions
    -- Shooting, racing, missions? :)

  collage 800 800 [
    renderBackground (w, h) gameState
  , renderDirectionIndicators gameState
  , renderOrbitalBodies gameState
  , renderShip gameState
  ]

renderOrbitalBodies gameState =
  (List.map (renderOrbitalBody gameState) gameState.orbitalBodies)
  |> group

renderOrbitalBody gameState orbitalBody =
  let
    color =
      radial (0,0) 50 (0, 10) (orbitalBody.size * 0.95)
        [ (  0, rgb  250 150 20)
        , (0.8, rgb  170 100 100)
        , (  1, rgba 50 100 10 0)
        ]
  in
    gradient color (circle orbitalBody.size)
    |> move (orbitalBody.x + gameState.x, orbitalBody.y + gameState.y)

renderBackground (w, h) gameState =
  let
    color =
      radial (0,0) 50 (0,10) 280
        [ (  0, rgb  244 (180 + (75 |> applySolarStateFrom gameState)) 1)
        , (0.8, rgb  228 200 100)
        , (  1, rgba 128 (100 |> applySolarStateFrom gameState) 100 0)
        ]
  in
    collage w 800 [
      square 800
      |> filled black
    , gradient color (circle 300)
      |> move (gameState.x, gameState.y)
    --, renderSpaceDust gameState
    ]
    |> toForm

applySolarStateFrom gameState number =
  number * gameState.solarState
  |> round

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

-- Update

update : Input -> GameState -> GameState
update input gameState =
  gameState
  |> applyInputs input
  |> applyMovement input
  |> applySolarGravity input
  |> changeSolarState input
  |> applyLookingAtSun input

changeSolarState input gameState =
  if gameState.solarStateDirection == 0 then
    if gameState.solarState > 1 then
      { gameState | solarStateDirection = 1 }
    else
      { gameState |
        solarState = gameState.solarState + 0.5 * input.delta
      }
  else
    if gameState.solarState < 0 then
      { gameState | solarStateDirection = 0 }
    else
      { gameState |
        solarState = gameState.solarState - 0.5 * input.delta
      }

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
        vy = gameState.vy - 20 * (gameState.direction |> degrees |> cos) * input.delta
      , vx = gameState.vx + 20 * (gameState.direction |> degrees |> sin) * input.delta
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
    vy = gameState.vy - 10 * (gameState |> directionToTheSun |> degrees |> cos) * input.delta
  , vx = gameState.vx + 10 * (gameState |> directionToTheSun |> degrees |> sin) * input.delta
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
  { x : Float
  , y : Float
  , vx : Float
  , vy : Float
  , direction: Float
  , engineRunning: Bool
  , solarState : Float
  , solarStateDirection : Int
  , orbitalBodies: List OrbitalBody
  }

type alias OrbitalBody =
  { x : Float
  , y : Float
  , size : Float
  , gravity : Int
  }

type alias Input =
  { fire : Bool
  , turnDirection : Int
  , thrustDirection : Int
  , delta : Time
  }
