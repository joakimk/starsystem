import {Socket} from "phoenix"


function loadApp()
{
  var gameElement = document.getElementById("js-game")
  return Elm.embed(Elm.Game, gameElement, {})
}

window.app = loadApp()

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

  window.app = loadApp()
})
