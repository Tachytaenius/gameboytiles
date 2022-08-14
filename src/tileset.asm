INCLUDE "include/constants.inc"

MACRO define_tile
	DEF \1 RB
	EXPORT \1
	INCBIN \2
ENDM

SECTION "Tileset graphics", ROM0

TilesetGraphics::
	RSRESET
	define_tile TILE_EMPTY, "res/empty.2bpp"
	define_tile TILE_WALL, "res/wall.2bpp"
	define_tile TILE_PLAYER, "res/player.2bpp"
	define_tile TILE_FLOOR, "res/floor.2bpp"
	define_tile TILE_EMPTY_BLACK, "res/empty_black.2bpp"
	define_tile TILE_DOOR, "res/door.2bpp"
	define_tile TILE_ICE, "res/ice.2bpp"
.end::

DEF NUM_TILES RB 0
