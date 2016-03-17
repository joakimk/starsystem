module Game.Math (..) where

distanceTo (targetX, targetY) player =
  let
    xDiff = targetX - player.x
    yDiff = targetY - player.y
  in
    sqrt (xDiff^2 + yDiff^2)

directionToTheSun player =
  let
    temp = (360 - (180 / pi) * (atan2 player.x player.y)) |> round
  in
    (temp % 360) |> normalizeDirection

normalizeDirection direction =
  if direction > 360 then
     360 - direction
  else if direction < 0 then
     direction + 360
  else
     direction
