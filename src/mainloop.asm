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
	call TryMovePlayer
	
.finishMainLoop
	jp MainLoop

TryMovePlayer:
	ld a, [wPlayerMoveDirection]
	cp DIR_NONE
	jr nz, .skipAllowingMove
	
	ld a, [wPlayerPos.x]
	ld b, a
	ld a, [wPlayerPos.y]
	ld c, a
	ld a, DIR_NONE
	ld d, a
.moveUp
	ldh a, [hJoypad.down]
	and JOY_UP
	jr z, .moveDown
	dec c
	ld d, DIR_UP
	jr .done
.moveDown
	ldh a, [hJoypad.down]
	and JOY_DOWN
	jr z, .moveLeft
	inc c
	ld d, DIR_DOWN
	jr .done
.moveLeft
	ldh a, [hJoypad.down]
	and JOY_LEFT
	jr z, .moveRight
	dec b
	ld d, DIR_LEFT
	jr .done
.moveRight
	ldh a, [hJoypad.down]
	and JOY_RIGHT
	jr z, .done
	inc b
	ld d, DIR_RIGHT
	; fallthrough
.done
	push bc
	push de
	call GetTileAddressFromBCAsXYInHL
	pop de
	
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
	ld a, d
	ld [wPlayerMoveDirection], a
	xor a
	ld [wPlayerMoveProgress], a
	
.skipAllowingMove
	; Tick movement
	ld a, [wPlayerMoveDirection]
	cp DIR_NONE
	jr z, .doneTickingMovement
	ld a, [wPlayerMoveSpeed]
	ld b, a
	ld a, [wPlayerMoveProgress]
	add b
	ld [wPlayerMoveProgress], a
	jr nc, .doneTickingMovement
	; overflowed, we are done moving
	ld a, [wPlayerMoveDirection]
	
.tryFinishingMovementUp
	cp DIR_UP
	jr nz, .tryFinishingMovementDown
	ld a, [wPlayerPos.y]
	dec a
	ld [wPlayerPos.y], a
	jr .doneChangingPlayerPos
.tryFinishingMovementDown
	cp DIR_DOWN
	jr nz, .tryFinishingMovementLeft
	ld a, [wPlayerPos.y]
	inc a
	ld [wPlayerPos.y], a
	jr .doneChangingPlayerPos
.tryFinishingMovementLeft
	cp DIR_LEFT
	jr nz, .tryFinishingMovementRight
	ld a, [wPlayerPos.x]
	dec a
	ld [wPlayerPos.x], a
	jr .doneChangingPlayerPos
.tryFinishingMovementRight
	; no compare needed
	ld a, [wPlayerPos.x]
	inc a
	ld [wPlayerPos.x], a
	; fallthrough
.doneChangingPlayerPos
	xor a
	ld [wPlayerMoveProgress], a
	ld a, DIR_NONE
	ld [wPlayerMoveDirection], a
.doneTickingMovement	
	; Get player sprite position
	; x
	ld a, [wPlayerPos.x]
	ld c, 8
	call SimpleMultiply
	; now add progress
	ld b, a ; back up base tile in b
	ld a, [wPlayerMoveDirection]
.tryRight
	cp DIR_RIGHT
	jr nz, .tryLeft
	; move progress to right
	ld a, [wPlayerMoveProgress]
REPT NUM_SHIFTS_PLAYER_MOVE_PROGRESS_TO_PIXEL_POSITION
	srl a
ENDR
	add b
	jr .skipRestoreHorizontal ; skip restoring base tile from b
.tryLeft
	cp DIR_LEFT
	jr nz, .skipHorizontal
	; add move progress to left
	ld a, [wPlayerMoveProgress]
REPT NUM_SHIFTS_PLAYER_MOVE_PROGRESS_TO_PIXEL_POSITION
	srl a
ENDR
	ld c, a
	ld a, b
	sub c
	jr .skipRestoreHorizontal
.skipHorizontal
	ld a, b
.skipRestoreHorizontal
	add 8
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_X], a
	
	; y
	ld a, [wPlayerPos.y]
	ld c, 8
	call SimpleMultiply
	; now add progress
	ld b, a ; back up base tile in b
	ld a, [wPlayerMoveDirection]
.tryDown
	cp DIR_DOWN
	jr nz, .tryUp
	; move progress to down
	ld a, [wPlayerMoveProgress]
REPT NUM_SHIFTS_PLAYER_MOVE_PROGRESS_TO_PIXEL_POSITION
	srl a
ENDR
	add b
	jr .skipRestoreVertical ; skip restoring base tile from b
.tryUp
	cp DIR_UP
	jr nz, .skipVertical
	; add move progress to up
	ld a, [wPlayerMoveProgress]
REPT NUM_SHIFTS_PLAYER_MOVE_PROGRESS_TO_PIXEL_POSITION
	srl a
ENDR
	ld c, a
	ld a, b
	sub c
	jr .skipRestoreVertical
.skipVertical
	ld a, b
.skipRestoreVertical
	add 16
	ld [wShadowOAM + sizeof_OAM_ATTRS * 0 + OAMA_Y], a
	
	ret
