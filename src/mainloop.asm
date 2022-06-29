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
.up
	ldh a, [hJoypad.down]
	and JOY_UP
	jr z, .down
	ld a, [wPlayerPos.y]
	dec a
	ld [wPlayerPos.y], a
.down
	ldh a, [hJoypad.down]
	and JOY_DOWN
	jr z, .left
	ld a, [wPlayerPos.y]
	inc a
	ld [wPlayerPos.y], a
.left
	ldh a, [hJoypad.down]
	and JOY_LEFT
	jr z, .right
	ld a, [wPlayerPos.x]
	dec a
	ld [wPlayerPos.x], a
.right
	ldh a, [hJoypad.down]
	and JOY_RIGHT
	jr z, .done
	ld a, [wPlayerPos.x]
	inc a
	ld [wPlayerPos.x], a
.done
	ld a, [wPlayerPos.x]
	; ld c, 8
	; call SimpleMultiply
	add 8
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_X], a
	ld a, [wPlayerPos.y]
	; ld c, 8
	; call SimpleMultiply
	add 16
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_Y], a
	ret
