import {Socket} from "phoenix"

// Storing gamestate outside of Elm so we can swap out the code and
// still be in the same state in the game
window.gameState = { x: 100, y: 100 }

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
  console.log("Reloading Elm app with the previous state and new code (keep in mind that this breaks inputs)")

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
