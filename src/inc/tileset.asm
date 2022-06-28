INCLUDE "inc/macros.asm"

; Credit to Rangi

if !DEF(INC_TILESET_DATA)
	fail "Must define INC_TILESET_DATA as 0 (no) or 1 (yes)!"
endc

MACRO def_tile
	if INC_TILESET_DATA
		\2:
		INCBIN \3
	else
		Enum \1
	endc
ENDM

if INC_TILESET_DATA
	SECTION "Tileset", ROM0
	Tileset::
else
	SetEnum
endc

	def_tile TILE_EMPTY, .empty, "gfx/empty.2bpp"
	def_tile TILE_TRINGLE, .tringle, "gfx/tringle.2bpp"

if INC_TILESET_DATA
	.end::
endc

PURGE INC_TILESET_DATA, def_tile