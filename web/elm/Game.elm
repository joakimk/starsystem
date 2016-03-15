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
  -- this could be any player we want to view the world as
  let
    viewPointPlayer = (localPlayer gameState)
  in
  -- later: figure out why height dimension does not seem to work
  -- later: remove duplication of height

  -- todo

  -- Multiplayer
    -- add presence (possibly through ping)
      -- client.playerId
      -- client.nickname
      -- simple html form to ask for nickname add as query param?
    -- refactor player, considering multiplay
      -- controll own player-id with local controls?
      -- players [ { x = 1, id = 0 }, ]
      -- make viewpoint use something like gameState.followedPlayerId? (so you could potentially look at other players point-of-view)
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
    renderBackground (w, h) (gameState, viewPointPlayer)
  , renderPing gameState
  , renderOrbitalBodies (gameState, viewPointPlayer)
  , renderDirectionIndicators viewPointPlayer
  , renderShips viewPointPlayer gameState
  ]

renderShips viewPointPlayer gameState =
  List.map (renderShip viewPointPlayer) gameState.players
  |> group

renderOrbitalBodies (gameState, player) =
  (List.map (renderOrbitalBody player) gameState.orbitalBodies)
  |> group

renderOrbitalBody : Player -> OrbitalBody -> Form
renderOrbitalBody player orbitalBody =
  let
    color =
      radial (0,0) 50 (0, 10) (orbitalBody.size * 0.95)
        [ (  0, rgb  250 150 20)
        , (0.8, rgb  170 100 100)
        , (  1, rgba 50 100 10 0)
        ]
  in
    gradient color (circle orbitalBody.size)
    |> move (orbitalBody.x + player.x, orbitalBody.y + player.y)

renderBackground (w, h) (gameState, player) =
  let
    color =
      radial (0,0) 50 (0,10) 280
        [ (  0, rgb  244 (180 + (75 |> updateSolarStateFrom gameState)) 1)
        , (0.8, rgb  228 200 100)
        , (  1, rgba 128 (100 |> updateSolarStateFrom gameState) 100 0)
        ]
  in
    collage w 800 [
      square 800
      |> filled black
    , gradient color (circle 300)
      |> move (player.x, player.y)
    --, renderSpaceDust gameState
    ]
    |> toForm

renderPing gameState =
  renderText (330, 380) ("ping: " ++ (toString gameState.ping))

updateSolarStateFrom gameState number =
  number * gameState.solarState
  |> round

renderDirectionIndicators : Player -> Form
renderDirectionIndicators player =
  let
    sunDirection = directionToTheSun player
    sunDistance = distanceTo (0, 0) player
    sunDv = (player.vx |> round |> abs) + (player.vy |> round |> abs)
    -- better indicator:
    -- where is the intersection with edge of screen?
    -- or: show arrow?
    text = "Sun direction: " ++ (toString (sunDirection |> round)) ++ ", distance: " ++ (sunDistance |> round |> toString) ++ ", relative speed: " ++ (sunDv |> toString)
  in
    if sunDistance > 650 then
      [ renderText (0, 280) text
      , renderText (0, 280 - 16) ("Your direction: " ++ (player.direction |> round |> toString))
     ]
     |> group
    else
      -- todo: render nothing
      renderSpaceDust player

renderSpaceDust : Player -> Form
renderSpaceDust player =
  [
    circle 1
    |> filled gray
    |> move (100 + player.x, 85 + player.y)
  ]
  |> group

renderShip viewPointPlayer player =
  let
    texture = if player.engineRunning then "ship_on" else "ship_off"
    renderedShip = image 50 80 ("/images/" ++ texture ++ ".png")
      |> toForm
      |> rotate (degrees player.direction)
  in
    if viewPointPlayer == player then
       renderedShip
    else
      -- NOTE: untested logic, no multiplayer support yet
      renderedShip
      |> move (player.x - viewPointPlayer.x, player.y - viewPointPlayer.y)


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
  let newGameState = gameState |> updateWorld input
  in
    (newGameState, (localPlayer gameState))
    |> updatePlayerPhysics input
    |> updateLocalPlayer input
    |> onlyGameState

updateWorld input gameState =
  gameState
  |> updatePing input
  |> changeSolarState input

updatePlayerPhysics input (gameState, player) =
  (gameState, player)
  |> updateSolarGravity input
  |> updateLookingAtSun input
  |> updateMovement input

updateLocalPlayer input (gameState, player) =
  (gameState, player)
  |> updateInputs input

onlyGameState (gameState, player) =
  gameState

updatePing input gameState =
  { gameState | ping = input.ping }

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

updateInputs input (gameState, player) =
  let
    degreesPerSecond = (360 * input.delta) / 2
  in
    if input.turnDirection == 1 then
      (gameState, player)
      |> updateDirection (normalizeDirection player.direction - degreesPerSecond)
    else if input.turnDirection == -1 then
      (gameState, player)
      |> updateDirection (normalizeDirection player.direction + degreesPerSecond)
    else if input.thrustDirection == 1 then
      (gameState, player)
      |> updateEngineRunning True
      |> updateVelocity (
        player.vx + 20 * (player.direction |> degrees |> sin) * input.delta
      , player.vy - 20 * (player.direction |> degrees |> cos) * input.delta
      )
    else
      (gameState, player)
      |> updateEngineRunning False

updateMovement input (gameState, player) =
  (gameState, player) |> updatePosition (
    player.x + player.vx * input.delta
  , player.y + player.vy * input.delta
  )

updateSolarGravity input (gameState, player) =
  (gameState, player) |> updateVelocity (
    player.vx + 10 * (player |> directionToTheSun |> degrees |> sin) * input.delta
  , player.vy - 10 * (player |> directionToTheSun |> degrees |> cos) * input.delta
  )

updateLookingAtSun input (gameState, player) =
  let
    newDirection = player.direction - ((player.direction - (directionToTheSun player)) * 0.5 * input.delta)
  in
    if playerIsChangingSpeedOrDirection input then
      (gameState, player)
    else
      (gameState, player) |> updateDirection (normalizeDirection newDirection)

-- As elm lacks tools to update nested data structures without using complex lambdas,
-- and we only need to update a few fields, here are some helpers.
-- Also, these take player so we can later calculate multiple local or remote players.
updateDirection direction (gameState, player) =
  updatePlayer player.id gameState (\player -> { player | direction = direction })

updateVelocity (vx, vy) (gameState, player) =
  updatePlayer player.id gameState (\player -> { player | vx = vx, vy = vy })

updatePosition (x, y) (gameState, player) =
  updatePlayer player.id gameState (\player -> { player | x = x, y = y })

updateEngineRunning engineRunning (gameState, player) =
  updatePlayer player.id gameState (\player -> { player | engineRunning = engineRunning })

updatePlayer id gameState callback =
  let
    updater player =
      if player.id == id then
         (callback player)
      else
         player
  in
    ({ gameState | players = (List.map updater gameState.players) }, (findPlayer gameState id))

-- Finds a player. For now we assume they are always there.
findPlayer gameState id =
  List.filter (\player -> player.id == id) gameState.players
  |> List.head
  |> Maybe.withDefault { x = 0, y = 0, vx = 0, vy = 0, direction = 0, engineRunning = False, id = -1 }

playerIsChangingSpeedOrDirection input =
  input.turnDirection /= 0 || input.thrustDirection /= 0

directionToTheSun player =
  let
    temp = (360 - (180 / pi) * (atan2 player.x player.y)) |> round
  in
    (temp % 360) |> normalizeDirection

-- Generic maths

distanceTo (targetX, targetY) player =
  let
    xDiff = targetX - player.x
    yDiff = targetY - player.y
  in
    sqrt (xDiff^2 + yDiff^2)

normalizeDirection direction =
  if direction > 360 then
     360 - direction
  else if direction < 0 then
     direction + 360
  else
     direction

localPlayer gameState =
  findPlayer gameState gameState.playerId

-- Support code

gameState : Signal GameState
gameState =
  Signal.foldp update initialGameState input

input : Signal Input
input =
  Signal.sampleOn delta <|
    Signal.map5 Input
      Keyboard.space -- # fire
      (Signal.map .x Keyboard.wasd) -- turn direction
      (Signal.map .y Keyboard.wasd) -- thrust direction
      ping
      delta

-- delta corresponds to the amount of change per second,
-- e.g. if FPS is 1, then delta is 1, if FPS is 2, delta is 0.5.
delta =
  Signal.map inSeconds (fps 60)

port stateChange : Signal GameState
port stateChange =
  gameState

port initialGameState : GameState

port ping : Signal Int

main =
  Signal.map2 render Window.dimensions gameState

type alias GameState =
  {
    players : List Player
  , solarState : Float
  , solarStateDirection : Int
  , orbitalBodies : List OrbitalBody
  , ping : Int
  , playerId : Int
  }

type alias Player =
  { x : Float
  , y : Float
  , vx : Float
  , vy : Float
  , direction : Float
  , engineRunning : Bool
  , id : Int
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
  , ping : Int
  , delta : Time
  }
