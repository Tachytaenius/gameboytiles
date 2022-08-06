INCLUDE "lib/hardware.inc"
INCLUDE "include/constants.inc"

SECTION "Main Loop Variables", WRAM0

wPlayerSpawning::
	ds 1 ; If this is FALSE, skip player spawn position events

wPlayerPos::
.x::
	ds 1
.y::
	ds 1

wPlayerMoveProgress::
	ds 1

wPlayerMoveDirection::
	ds 1

wPlayerMoveSpeed::
	ds 1

wPlayerMovementPriority::
	ds 1

SECTION "Main Loop", ROM0

MainLoop::
	; Wait for VBlank
	halt
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
	jp nz, .skipAllowingMove
	
	ld a, [hJoypad.down]
	; next: b = horizontal?, c = vertical?
	; next: e = to-be-filtered inputs
	ld bc, 0
	ld e, a
	and (1 << JOY_UP_BIT) | (1 << JOY_DOWN_BIT)
	jr z, .notVertical
	inc c
.notVertical
	ld a, e
	and (1 << JOY_LEFT_BIT) | (1 << JOY_RIGHT_BIT)
	jr z, .notHorizontal
	inc b
.notHorizontal
	; done checking input
	; if vertical and horizontal, then use wPlayerMovementPriority to filter out non-prioritised inputs
	; else, set priority to aixs currently not being pressed
	ld a, b
	and c
	jr z, .setPriorityToOtherAxis
	; if ...
	ld a, [wPlayerMovementPriority]
	ASSERT AXIS_HORIZONTAL == 0
	and a
	ld a, e
	jr nz, .filterOutHorizontalInputs ; vertical has priority
	; horizontal has priority, filter out vertical inputs
	and JOY_LEFT_MASK | JOY_RIGHT_MASK
	jr .doneCheckingAndUsingPriority
.filterOutHorizontalInputs
	and JOY_UP_MASK | JOY_DOWN_MASK
	jr .doneCheckingAndUsingPriority
.setPriorityToOtherAxis
	; else ...
	; are we moving horizontally?
	dec b ; z if was 1, nz if was 0
	jr nz, .changePriorityToHorizontal ; we are moving vertically
	; we are moving horizontally, make vertical the priority
	ld a, AXIS_VERTICAL
	ld [wPlayerMovementPriority], a
	ld a, e ; use original inputs as filtered inputs since nothing needed filtering
	jr .doneCheckingAndUsingPriority
.changePriorityToHorizontal
	ld a, AXIS_HORIZONTAL
	ld [wPlayerMovementPriority], a
	ld a, e ; use original inputs as filtered inputs since nothing needed filtering
	; fallthrough
.doneCheckingAndUsingPriority
	
	; now: a = filtered inputs
	; next: b = x, c = y, d = direction
	ld e, a ; backup
	ld a, [wPlayerPos.x]
	ld b, a
	ld a, [wPlayerPos.y]
	ld c, a
	ld d, DIR_NONE
	ld a, e ; restore
.tryMoveLeft
	bit JOY_LEFT_BIT, a
	jr z, .tryMoveRight
	dec b
	ld d, DIR_LEFT
	jr .doneTryMovement
.tryMoveRight
	bit JOY_RIGHT_BIT, a
	jr z, .tryMoveUp
	inc b
	ld d, DIR_RIGHT
	jr .doneTryMovement
.tryMoveUp
	bit JOY_UP_BIT, a
	jr z, .tryMoveDown
	dec c
	ld d, DIR_UP
	jr .doneTryMovement
.tryMoveDown
	bit JOY_DOWN_BIT, a
	jr z, .doneTryMovement
	inc c
	ld d, DIR_DOWN
.doneTryMovement

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
	and TILEATTR_SOLID_MASK
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
REPT NUM_SUBPIXEL_BITS
	srl a
ENDR
	add b
	jr .skipRestoreHorizontal ; skip restoring base tile from b
.tryLeft
	cp DIR_LEFT
	jr nz, .skipHorizontal
	; add move progress to left
	ld a, [wPlayerMoveProgress]
REPT NUM_SUBPIXEL_BITS
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
REPT NUM_SUBPIXEL_BITS
	srl a
ENDR
	add b
	jr .skipRestoreVertical ; skip restoring base tile from b
.tryUp
	cp DIR_UP
	jr nz, .skipVertical
	; add move progress to up
	ld a, [wPlayerMoveProgress]
REPT NUM_SUBPIXEL_BITS
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
