module Game where

import Keyboard exposing (..)
import Time exposing (..)
import Window

import Game.Types exposing (..)
import Game.Update exposing (update)
import Game.Render exposing (render)

gameState : Signal GameState
gameState =
  Signal.foldp update initialGameState events

events : Signal Event
events =
  (Signal.map NewInput input)
  |> Signal.merge (Signal.map NewOrUpdatedPlayer addOrUpdatePlayer)
  |> Signal.merge (Signal.map UpdatedPing ping)

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

port ping : Signal Int

port addOrUpdatePlayer : Signal Player

main =
  Signal.map2 render Window.dimensions gameState
