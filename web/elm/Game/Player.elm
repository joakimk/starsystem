module Game.Player (..) where

-- Finds a player. For now we assume they are always there.
findPlayer gameState id =
  List.filter (\player -> player.id == id) gameState.players
  |> List.head
  |> Maybe.withDefault { x = 0, y = 0, vx = 0, vy = 0, direction = 0, engineRunning = False, id = "not-found", nickname = "", lastSeenTime = 0 }

playerIsChangingSpeedOrDirection input =
  input.turnDirection /= 0 || input.thrustDirection /= 0

localPlayer gameState =
  findPlayer gameState gameState.playerId
