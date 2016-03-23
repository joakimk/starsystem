module Game.Types (..) where

import Time exposing (..)

type Event = NewInput Input | NewOrUpdatedPlayer Player | UpdatedPing Int | UpdatedTime Time

type alias GameState =
  {
    players : List Player
  , solarState : Float
  , solarStateDirection : Int
  , orbitalBodies : List OrbitalBody
  , ping : Int
  , playerId : String
  , timestamp : Time
  }

type alias Player =
  { x : Float
  , y : Float
  , vx : Float
  , vy : Float
  , direction : Float
  , engineRunning : Bool
  , id : String
  , nickname : String
  , lastSeenTime : Time
  }

type alias OrbitalBody =
  { x : Float
  , y : Float
  , vx : Float
  , vy : Float
  , size : Float
  , gravity : Int
  }

type alias Input =
  { fire : Bool
  , turnDirection : Int
  , thrustDirection : Int
  , delta : Time
  }
