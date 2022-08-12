INCLUDE "include/constants.inc"

MACRO DefineTile
	DEF \1 RB
	EXPORT \1
	INCBIN \2
ENDM

SECTION "Tileset graphics", ROM0

TilesetGraphics::
	RSRESET
	DefineTile TILE_EMPTY, "res/empty.2bpp"
	DefineTile TILE_WALL, "res/wall.2bpp"
	DefineTile TILE_PLAYER, "res/player.2bpp"
	DefineTile TILE_FLOOR, "res/floor.2bpp"
.end::

DEF NUM_TILES RB 0
