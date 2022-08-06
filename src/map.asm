INCLUDE "lib/hardware.inc"
INCLUDE "include/constants.inc"

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

ClearMap::
	ld bc, _SCRN0
	ld d, SCRN_X_B ; number of times to loop
	
.rowLoop
	ld a, TILE_WALL
	ld [bc], a
	inc bc
	
	ld a, c
	and %00011111 ; get x component
	cp SCRN_X_B
	jr nz, .rowLoop
	
.nextRow
	dec d
	ret z
	
	ld a, c
	add SCRN_VX_B - SCRN_X_B
	ld c, a
	ld a, b
	adc 0
	ld b, a
	
	jr .rowLoop

LoadMapAtHLBankA::
	rst SwapBank ; is not backed up
	
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
	jr z, .loadEvents
	
	ld a, c
	add SCRN_VX_B - SCRN_X_B
	ld c, a
	ld a, b
	adc 0
	ld b, a
	
	jr .rowLoop

.loadEvents
	ld a, [hl+] ; number of times to loop
	and a
	ret z ; don't start if the loop count is 0
	ld b, a
	inc b
	
.loadEventLoop
	ld a, [hl+] ; event type
	
	cp MAP_EVENT_SPAWN
	jr nz, :+
	ld a, [hl+]
	ld [wPlayerPos.x], a
	ld a, [hl+]
	ld [wPlayerPos.y], a
:
	
	dec b
	jr nz, .loadEventLoop
	ret
