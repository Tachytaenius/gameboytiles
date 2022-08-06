INCLUDE "lib/hardware.inc"
INCLUDE "include/constants.inc"

SECTION "Map", ROM0

GetTilePropertiesAtBCAsXY::
	; assumes you are already in the map's bank
	; destroys bc, de, and hl
	ld a, [wCurMapAddress]
	ld l, a
	ld a, [wCurMapAddress + 1]
	ld h, a
	ld de, SCRN_X_B * SCRN_Y_B
	add hl, de
	jr GetTileTypeAtBCAsXY.skipReadingMapAddress

GetTileTypeAtBCAsXY::
	; assumes you are already in the map's bank
	; destroys bc, de, and hl
	ld a, [wCurMapAddress]
	ld l, a
	ld a, [wCurMapAddress + 1]
	ld h, a
.skipReadingMapAddress
	; add (b = x) to hl
	ld d, 0
	ld e, b
	add hl, de
	
	; add (c = y) * SCRN_X_B to hl
	; ld d, 0
	ld e, c
	ld a, SCRN_X_B
:
	add hl, de
	dec a
	jr nz, :-
	
	ld a, [hl]
	ret

LoadMapAtHLBankA::
	ld [wCurMapBank], a
	rst SwapBank ; is not backed up
	ld a, l
	ld [wCurMapAddress], a
	ld a, h
	ld [wCurMapAddress + 1], a
	
	ld bc, _SCRN0
	ld d, SCRN_Y_B ; number of times to loop
	
.rowLoop
	ld a, [hl+]
	ld [bc], a
	inc bc
	
	ld a, c
	and %00011111 ; get x component
	cp SCRN_X_B
	jr nz, .rowLoop
	
.nextRow
	dec d
	jr z, .finishLoadingTileTypes
	
	ld a, c
	add SCRN_VX_B - SCRN_X_B
	ld c, a
	ld a, b
	adc 0
	ld b, a
	
	jr .rowLoop

.finishLoadingTileTypes
	; skip over tile properties
	ld bc, SCRN_X_B * SCRN_Y_B
	add hl, bc
	
	; save warps address
	ld a, l
	ld [wCurMapWarpsAddress], a
	ld a, h
	ld [wCurMapWarpsAddress + 1], a
	
	ret

SECTION "Map Information", WRAM0

wCurMapBank::
	ds 1

wCurMapAddress::
	ds 2

wCurMapWarpsAddress::
	ds 2
