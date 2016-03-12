# Starsystem

Playing around with Elm and live code updates by building a game.

The rough idea is to build a spaceship game where you can move around within a star system.

**Status:** Basic hot-code-reload setup done. Not much of a game yet.


# Dev

    mix deps.get

    cd web/elm
    source paths.env
    elm package install -y
    cd ../..

    mix phoenix.server

Then visit <http://localhost:4000>, edit [web/elm/Game.elm](/web/elm/Game.elm) and see the changes.

If you play the game (currently not much of a game, but W and D will move the box),
you can edit the code and see the changes applied without the game resetting.

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
