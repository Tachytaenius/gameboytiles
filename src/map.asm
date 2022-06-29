INCLUDE "lib/hardware.asm"

SECTION "Map", ROM0

GetTileAddressFromPosAtHLInHL::
	ld a, [hl+]
	ld b, a
	ld a, [hl]
	ld c, a
	; fallthrough
GetTileAddressFromBCAsXYInHL::
	ld hl, _SCRN0
	
	; add (b = x) to hl
	ld d, 0
	ld e, b
	add hl, de
	
	; add (c = y) * SCRN_VX_B to hl
	; ld d, 0
	ld e, c
	ld a, SCRN_VX_B
:
	add hl, de
	dec a
	jr nz, :-
	ret

