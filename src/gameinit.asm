INCLUDE "lib/hardware.asm"
INCLUDE "inc/constants.asm"
INC_TILESET_DATA = 0
INCLUDE "inc/tileset.asm"

SECTION "Game Init", ROM0

GameInit::
	; Load tileset
	ld bc, Tileset.end - Tileset
	ld hl, Tileset
	ld de, _VRAM
	call CopyBytes
	
	; Make sprite 0 a tringle
	ld hl, wShadowOAM + sizeof_OAM_ATTRS * 0
	ld a, 0 + 16
	ld [hli], a
	ld a, 0 + 8
	ld [hli], a
	ld a, TILE_TRINGLE
	ld [hli], a
	
	ret
