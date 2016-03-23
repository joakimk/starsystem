module Game.Update (..) where

import Game.Types exposing (..)
import Game.Math exposing (directionToTheSun, normalizeDirection, distanceTo)
import Game.Player exposing (findPlayer, localPlayer, playerIsChangingSpeedOrDirection)

-- Update

update : Event -> GameState -> GameState
update event gameState =
  case event of
    NewInput input ->
      gameState
      |> removeInactivePlayers
      |> updateLocal input
      |> updateAllPlayers input

    NewOrUpdatedPlayer rawPlayer ->
      let
        player = { rawPlayer | lastSeenTime = gameState.timestamp }
      in
        if gameState.players == [] then
          { gameState | players = [ player ], playerId = player.id }
        else if player.id == gameState.playerId then
          gameState -- don't update for local player updates
        else if (findPlayer gameState player.id).id == player.id then
          updatePlayer player.id gameState (\oldPlayer ->
            -- smooth out updates a bit: don't update if the local
            -- calculation is close to what we received
            if distanceTo (oldPlayer.x, oldPlayer.y) player > 50 then
              { player | x = oldPlayer.x, y = oldPlayer.y }
            else
              oldPlayer
          )
          |> onlyGameState
        else
          { gameState | players = (List.concat [ gameState.players, [ player ] ]) }

    UpdatedPing ping ->
      { gameState | ping = ping }

    UpdatedTime timestamp ->
      { gameState | timestamp = timestamp }

removeInactivePlayers : GameState -> GameState
removeInactivePlayers gameState =
  let
    timeout = 5000 -- ms (not exact, depends on UpdatedTime interval)
    remainingPlayers = List.filter (\player ->
        player.id == gameState.playerId ||
        player.lastSeenTime == 0 ||
        (gameState.timestamp - player.lastSeenTime) < timeout
      )
      gameState.players
  in
    { gameState | players = remainingPlayers }

updateAllPlayers input gameState =
  List.foldr updateGlobal (gameState, input) gameState.players
  |> onlyGameState

updateLocal input gameState =
  gameState
  |> changeSolarState input
  |> updateOrbitalBodies input
  |> updateLocalPlayer input
  |> onlyGameState

updateGlobal player (gameState, input) =
  (gameState, player)
  |> updatePlayerPhysics input
  |> onlyGameState
  |> addInput input

addInput input gameState =
  (gameState, input)

updatePlayerPhysics input (gameState, player) =
  (gameState, player)
  |> updateSolarGravity input
  |> updateLookingAtSun input
  |> updateMovement input

updateLocalPlayer input gameState =
  (gameState, (localPlayer gameState))
  |> updateInputs input

onlyGameState (gameState, player) =
  gameState

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

updateOrbitalBodies: Input -> GameState -> GameState
updateOrbitalBodies input gameState =
  let
    orbitalBodies = List.map (updateOrbitalBody input.delta) gameState.orbitalBodies
  in
    { gameState | orbitalBodies = orbitalBodies }

updateOrbitalBody : Float -> OrbitalBody -> OrbitalBody
updateOrbitalBody delta orbitalBody =
  { orbitalBody |
    vx = orbitalBody.vx + 10 * (orbitalBody |> directionToTheSun |> degrees |> sin) * delta
  , vy = orbitalBody.vy + 10 * (orbitalBody |> directionToTheSun |> degrees |> cos) * delta
  , x = orbitalBody.x + (delta * orbitalBody.vx)
  , y = orbitalBody.y - (delta * orbitalBody.vy)
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

updateSolarGravity : Input -> (GameState, Player) -> (GameState, Player)
updateSolarGravity input (gameState, player) =
  (gameState, player) |> updateVelocity (
    player.vx + 10 * (player |> directionToTheSun |> degrees |> sin) * input.delta
  , player.vy - 10 * (player |> directionToTheSun |> degrees |> cos) * input.delta
  )

updateLookingAtSun input (gameState, player) =
  let
    newDirection = player.direction - ((player.direction - (directionToTheSun player)) * 0.5 * input.delta)
  in
    if player.id == (localPlayer gameState).id && playerIsChangingSpeedOrDirection input then
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
