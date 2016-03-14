import {Socket} from "phoenix"

// Storing gamestate outside of Elm so we can swap out the code and
// still be in the same state in the game
window.gameState = {
  x: 400, y: 100,
  vx: 0, vy: -70,
  direction: 300,
  engineRunning: false,
  solarState: 0, solarStateDirection: 0,
  orbitalBodies: [
    { x: -500, y: 350, size: 100, gravity: 5 }
  ],
  ping: 0
}

function loadApp()
{
  var gameElement = document.getElementById("js-game")
  var app = Elm.embed(Elm.Game, gameElement, { initialGameState: window.gameState, ping: 0 })

  app.ports.stateChange.subscribe((state) => {
    window.gameState = state
  })

  window.app = app
}

let socket = new Socket("/socket", { params: {} })
socket.connect()

let channel = socket.channel("game", {})
channel.join()

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

// Get server ping
function ping() {
  channel.push("ping", { timestamp: Date.now() })
}

channel.on("pong", (data) => {
  app.ports.ping.send(Date.now() - data.timestamp)
  setTimeout(ping, 1000)
})

ping()

