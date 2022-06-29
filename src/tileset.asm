INCLUDE "inc/macros.asm"
INCLUDE "inc/constants.asm"

MACRO def_tile
\2:
INCBIN \3
	db \4
	Enum \1
	EXPORT \1
ENDM

SECTION "Tileset", ROM0

	SetEnum

Tileset::
	def_tile TILE_EMPTY, .empty, "gfx/empty.2bpp", TILEATTR_NONSOLID
	def_tile TILE_WALL, .wall, "gfx/wall.2bpp", TILEATTR_SOLID
	def_tile TILE_TRINGLE, .tringle, "gfx/tringle.2bpp", TILEATTR_NONSOLID
.end::

	Enum NUM_TILES
EXPORT NUM_TILES
