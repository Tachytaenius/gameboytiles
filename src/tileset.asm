INCLUDE "include/constants.inc"

MACRO define_tile
	DEF \1 RB
	EXPORT \1
	INCBIN STRCAT("res/tiles/", \2, ".2bpp")
ENDM

SECTION "Tileset graphics", ROM0

TilesetGraphics::
	RSRESET
	define_tile TILE_EMPTY, "empty"
	define_tile TILE_WALL, "wall"
	define_tile TILE_PLAYER, "player"
	define_tile TILE_FLOOR, "floor"
	define_tile TILE_EMPTY_BLACK, "empty_black"
	define_tile TILE_DOOR, "door"
	define_tile TILE_ICE, "ice"
.end::

DEF NUM_TILES RB 0
