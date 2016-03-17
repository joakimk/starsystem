module Game.Render (render) where

import Color exposing (..)
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Text

import Game.Types exposing (..)
import Game.Math exposing (directionToTheSun, distanceTo)
import Game.Player exposing (localPlayer)

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
      -- simple html form to ask for nickname add as query param?

    -- basic
      -- remove players that hasn't been seen in a set time
      -- publish x,y,vx,vy,direction updates periodically
      -- subscribe to other players data updates
      -- updates on control inputs for smoother updates

    -- better?
      -- publish control inputs
      -- subscribe to other players control inputs (smooth changes)

  -- Gameplay: environment
    -- navigation idea: show a list of destinations, highlight the selected, orient the ship towards the selected, and possibly add directional arrow
    -- gravity acceleration based on distance/mass?
    -- handle multiple inputs at the same time
    -- add space dust to show movement
    -- add planets
      -- use textures, orient them to have the bright side facing the sun?
      -- use gradients like the sun to provide an atmosphere effect
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
    renderedShip = [
        image 50 80 ("/images/" ++ texture ++ ".png")
        |> toForm
        |> rotate (degrees player.direction)
      , Text.fromString player.nickname
        |> Text.height 11
        |> Text.color white
        |> Text.monospace
        |> rightAligned
        |> toForm
        |> move (0.0, 50.0)
      ]
      |> group
  in
    if viewPointPlayer == player then
       renderedShip
    else
      -- NOTE: untested logic, no multiplayer support yet
      renderedShip
      |> move (viewPointPlayer.x - player.x, viewPointPlayer.y - player.y)

renderText (x, y) text =
  Text.fromString text
  |> Text.height 16
  |> Text.color white
  |> Text.monospace
  |> rightAligned
  |> toForm
  |> moveX x
  |> moveY y

