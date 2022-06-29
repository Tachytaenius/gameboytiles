INCLUDE "lib/hardware.asm"
INCLUDE "inc/constants.asm"

SECTION "Main Loop", ROM0

MainLoop::
	; Wait for VBlank
	ldh a, [hVBlankFlag]
	and a
	jr z, MainLoop
	xor a
	ldh [hVBlankFlag], a
	
	call UpdateJoypad
	call hOAMDMA
	call TryMoveTringle
	
.finishMainLoop
	jp MainLoop

TryMoveTringle:
	ld a, [wPlayerPos.x]
	ld b, a
	ld a, [wPlayerPos.y]
	ld c, a
.up
	ldh a, [hJoypad.pressed]
	and JOY_UP
	jr z, .down
	dec c
	jr .done
.down
	ldh a, [hJoypad.pressed]
	and JOY_DOWN
	jr z, .left
	inc c
	jr .done
.left
	ldh a, [hJoypad.pressed]
	and JOY_LEFT
	jr z, .right
	dec b
	jr .done
.right
	ldh a, [hJoypad.pressed]
	and JOY_RIGHT
	jr z, .done
	inc b
	jr .done
.done
	push bc
	call GetTileAddressFromBCAsXYInHL
	
	; wait for VBlank
	push af
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	pop af
	
	; Get properties for tile at bc as xy
	ld a, [hl]
	ld hl, TilesetProperties
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	pop bc
	and TILEATTR_SOLID
	jr nz, .skipAllowingMove
	; Allow move
	ld a, b
	ld [wPlayerPos.x], a
	ld a, c
	ld [wPlayerPos.y], a
.skipAllowingMove
	
	ld a, [wPlayerPos.x]
	ld c, 8
	call SimpleMultiply
	add 8
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_X], a
	ld a, [wPlayerPos.y]
	ld c, 8
	call SimpleMultiply
	add 16
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_Y], a
	ret
