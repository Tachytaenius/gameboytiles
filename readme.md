# Game Boy Tiles Demo

Build using cygwin or WSL or some other POSIX environment if you are using Windows, Windows is not supported

Requires RGBDS, Python 3, Lua, and Tiled (Tiled needs to be added to your PATH)

On actual Linux, Tiled requires an X server to run. If the Tiled command is not working, install and run headless X server such as Xvfb, in which case you would run `xvfb-run make`.

## making maps

The tiled project is in src/res/tiled, please edit Tiled data with the project open

### defining warps

In the Tiled project, use the Warp custom property type in a map's custom properties (map -> map properties), named "warp1" to "warp15" to define the map's at-most-15 warp destinations. Destination map name doesn't need the x (for ROMX) prefix.

### The layers

You can adjust the opacity of each layer as needed for easier editing
- "Warps" uses the Warps tileset and defines which warp destination (or none) a tile references
- "Types" is the displayed tiles and uses the Tileset tileset
- "Collision" is the collision map and uses the Boolean tileset, true (black) (1) for solid collision
- "Slipperiness" uses the Boolean tileset to define whether you can stop moving and change direction on a tile.
