INCLUDE "lib/hardware.asm"
INCLUDE "inc/constants.asm"

SECTION "Game Init", ROM0

GameInit::
	; Load tileset
	ld bc, TilesetGraphicsEnd - TilesetGraphics
	ld hl, TilesetGraphics
	ld de, _VRAM
	call CopyBytes
	
	; Load map
	ld hl, ExampleMap
	call LoadMapAtHL
	
	; Make sprite 0 a tringle
	ld hl, wShadowOAM + sizeof_OAM_ATTRS * 0
	ld a, 0 + 16
	ld [hl+], a
	ld a, 0 + 8
	ld [hl+], a
	ld a, TILE_TRINGLE
	ld [hl+], a
	
	ld a, 1
	ld [wPlayerPos.x], a
	ld [wPlayerPos.y], a
	
	ret
