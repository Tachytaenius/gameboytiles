INCLUDE "lib/hardware.asm"
INCLUDE "inc/constants.asm"

SECTION "Game Init", ROM0

GameInit::
	; Load tileset
	; Init loading
	ld a, NUM_TILES
	ld [wCountingBuffer1], a
	ld hl, Tileset
	ld de, _VRAM
:
	; Copy one tile
	ld bc, 16
	call CopyBytes
	ld a, [wCountingBuffer1]
	dec a
	jr z, :+ ; Bail
	; Prepare for copying next tile
	ld [wCountingBuffer1], a
	inc hl ; Skip attributes
	jr :-
:
	
	; Make sprite 0 a tringle
	ld hl, wShadowOAM + sizeof_OAM_ATTRS * 0
	ld a, 0 + 16
	ld [hli], a
	ld a, 0 + 8
	ld [hli], a
	ld a, TILE_TRINGLE
	ld [hli], a
	
	ret
