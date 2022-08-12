INCLUDE "lib/hardware.inc"
INCLUDE "include/constants.inc"

SECTION "Map", ROM0

; Returns the property at given x y coordinates in the current map, or a default if out of bounds
; Assumes the map's bank is loaded
; @param b The x coordinate
; @param c The y coordinate
; @return a The requested property
; @destroy af hl de
GetTilePropertiesAtBCAsXY::
	; First, we check if we are in bounds
	ld a, b
	cp SCRN_X_B
	jr nc, .outside
	
	ld a, c
	cp SCRN_Y_B
	jr nc, .outside
	
	ld hl, wCurMapAddress
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld de, SCRN_X_B * SCRN_Y_B
	add hl, de

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

.outside
	ld a, OUT_OF_BOUNDS_TILE_PROPERTIES
	ret

; Loads the requested map
; @param a The requested map's bank
; @param hl The requested map's address
; @destroy af hl bc de
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
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, .rowLoop
	
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
