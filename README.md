# Starsystem

Playing around with Elm and live code updates by building a game.

The rough idea is to build a spaceship game where you can move around within a star system.

When/if there is ever enough game there I hope to add multiplayer through the phoenix server.

**Status:** Basic hot-code-reload setup done. Some basics in place.

# Screenshot

![](https://dl.dropboxusercontent.com/u/136929/screen_shot_2016-03-13_at_16.56.40.png)

# Dev

    mix deps.get

    cd web/elm
    source paths.env
    elm package install -y
    cd ../..

    mix phoenix.server

Then visit <http://localhost:4000>, edit [web/elm/Game.elm](/web/elm/Game.elm) and see the changes.

If you play the game (currently not much of a game, but A and D will rotate the ship),
you can edit the code and see the changes applied without the game resetting.

# Commands used to deploy to heroku

Deployed at <https://starsystemgame.herokuapp.com/>

    heroku apps:create starsystemgame --region eu
    heroku buildpacks:set https://github.com/gjaldon/phoenix-static-buildpack
    heroku buildpacks:add --index 1 https://github.com/HashNuke/heroku-buildpack-elixir
    heroku config:set SECRET_KEY_BASE=$(elixir -e "IO.puts :crypto.strong_rand_bytes(64) |> Base.encode64")
    git push heroku

# Credits

Ship graphics by "JM.Atencia", from <http://opengameart.org/content/rocket>.

# License

Copyright (c) 2016 [Joakim Kolsjö](https://twitter.com/joakimk)

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
