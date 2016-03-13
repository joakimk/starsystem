import {Socket} from "phoenix"

// Storing gamestate outside of Elm so we can swap out the code and
// still be in the same state in the game
window.gameState = {
  x: 350, y: 350,
  vx: 100, vy: -100,
  direction: 300,
  engineRunning: false,
  solarState: 0, solarStateDirection: 0,
}

function loadApp()
{
  var gameElement = document.getElementById("js-game")
  var app = Elm.embed(Elm.Game, gameElement, { initialGameState: window.gameState })

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
