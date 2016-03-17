import {Socket} from "phoenix"

let socket = new Socket("/socket", { params: {} })
socket.connect()

let channel = socket.channel("game", {})
channel.join()

// http://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript/2117523#2117523
function generateUUID() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      var r = Math.random() * 16|0;
      var v = (c == "x" ? r : (r & 0x3|0x8));
      return v.toString(16);
  })
}

// Storing gamestate outside of Elm so we can swap out the code and
// still be in the same state in the game
window.gameState = {
  players: [
    {
      id: generateUUID(),
      x: 500, y: 200,
      vx: 0, vy: -70,
      direction: 300,
      engineRunning: false,
      nickname: "Player"
    },

    // NPC :)
    {
      id: generateUUID(),
      x: 320, y: 150,
      vx: 0, vy: -70,
      direction: 300,
      engineRunning: false,
      nickname: "NPC"
    },
  ],
  playerId: null,
  solarState: 0, solarStateDirection: 0,
  orbitalBodies: [
    { x: -500, y: 350, size: 100, gravity: 5 }
  ],
  ping: 0
}

window.gameState.playerId = window.gameState.players[0].id

// App reloading
function loadApp()
{
  var gameElement = document.getElementById("js-game")
  var app = Elm.embed(Elm.Game, gameElement, { initialGameState: window.gameState, ping: 0 })

  app.ports.stateChange.subscribe((state) => {
    window.gameState = state
  })

  window.app = app
}

channel.on("updated_code", (data) => {
  console.log("Reloading Elm app (but keeping previous state)")

  // Remove old app
  app.dispose()

  // Add new app
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.innerHTML = data.source;
  document.body.appendChild(script);

  loadApp()
})

loadApp()

// Server ping check
function ping() {
  channel.push("ping", { timestamp: Date.now() })
}

channel.on("pong", (data) => {
  app.ports.ping.send(Date.now() - data.timestamp)
  setTimeout(ping, 1000)
})

ping()
