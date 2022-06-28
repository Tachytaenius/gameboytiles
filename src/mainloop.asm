INCLUDE "lib/hardware.asm"
INCLUDE "inc/constants.asm"

SECTION "Main Loop", ROM0

MainLoop::
	call UpdateJoypad
	
	; Wait for VBlank
	ldh a, [hVBlankFlag]
	and a
	jr z, MainLoop
	xor a
	ldh [hVBlankFlag], a
	
	; Update sprites
	call hOAMDMA
	
	call TryMoveTringle
	
.finishMainLoop
	jp MainLoop

TryMoveTringle:
.up
	ldh a, [hJoypad.down]
	and JOY_UP
	jr z, .down
	ld a, [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_Y]
	dec a
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_Y], a
.down
	ldh a, [hJoypad.down]
	and JOY_DOWN
	jr z, .left
	ld a, [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_Y]
	inc a
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_Y], a
.left
	ldh a, [hJoypad.down]
	and JOY_LEFT
	jr z, .right
	ld a, [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_X]
	dec a
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_X], a
.right
	ldh a, [hJoypad.down]
	and JOY_RIGHT
	ret z
	ld a, [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_X]
	inc a
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_X], a
	ret
