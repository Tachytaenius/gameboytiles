INCLUDE "lib/hardware.inc"
INCLUDE "include/constants.inc"

DEF DIR_NONE  EQU -1
DEF DIR_UP    EQU 0
DEF DIR_RIGHT EQU 1
DEF DIR_DOWN  EQU 2
DEF DIR_LEFT  EQU 3

EXPORT DIR_NONE

SECTION "Main Loop Variables", WRAM0

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

wLastPlayerInputs::
	ds 1

wLoadMapTileTypesIntoVRAMFlag::
	ds 1

wCurrentTilePropertiesCache:
	ds 1

wPlayerMoveDirectionCache:
	ds 1

wPlayerMoveSpeedThisTile:
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
	
	ld a, [wLoadMapTileTypesIntoVRAMFlag]
	and a
	jr z, :+
	call LoadMapTileTypesIntoVRAM
:
	
	call UpdateJoypad
	call TryMovePlayer
	
.finishMainLoop
	jp MainLoop

SetPriorityToCurrentInput:
	ldh a, [hJoypad.down]
	
.checkNewInputLeft
	bit JOY_LEFT_BIT, a
	jr z, .checkNewInputRight
	ld a, DIR_LEFT
	ld [wPlayerMovementPriority], a
	ret

.checkNewInputRight
	bit JOY_RIGHT_BIT, a
	jr z, .checkNewInputUp
	ld a, DIR_RIGHT
	ld [wPlayerMovementPriority], a
	ret

.checkNewInputUp
	bit JOY_UP_BIT, a
	jr z, .checkNewInputDown
	ld a, DIR_UP
	ld [wPlayerMovementPriority], a
	ret

.checkNewInputDown
	bit JOY_DOWN_BIT, a
	ret z
	ld a, DIR_DOWN
	ld [wPlayerMovementPriority], a
	ret

EdgeWarpCommonCode:
	ld hl, wCurMapEdgeWarpDestinationsAddress
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de
	ld a, [hl+]
	ld b, a ; backup bank
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, b
 	call LoadMapAtHLBankA
	; Now check if we entered the map onto a slippery tile
	ld a, [wPlayerPos.x]
	ld b, a
	ld a, [wPlayerPos.y]
	ld c, a
	call GetTilePropertiesAtBCAsXY
	and TILEPROP_SLIPPERINESS_MASK
	ret z
	ld a, [wPlayerMoveDirectionCache]
	ld [wPlayerMoveDirection], a
	ret

StopPlayerMovement:
	xor a
	ld [wPlayerMoveProgress], a
	ld a, DIR_NONE
	ld [wPlayerMoveDirection], a
	ret

TryMovePlayer:
	ld a, [wPlayerMoveDirection]
	cp DIR_NONE
	jp nz, .skipAllowingMove	
	
	ldh a, [hJoypad.down] ; get inputs
	ld b, a
	
	; if the priority input was un-inputted since last movement check, then set priority input to the first found direction being inputted
	ld a, [wLastPlayerInputs]
	ld c, a
	ld a, b
	cpl
	and c
	; now: a contains inputs released since last movement check
	ld c, a ; backup
	ld a, [wPlayerMovementPriority]
.checkPriorityUp1
	cp DIR_UP
	jr nz, .checkPriorityRight1
	ld a, c ; restore
	and JOY_UP_MASK
	call nz, SetPriorityToCurrentInput
	jr .doneCheckingPriority1
.checkPriorityRight1
	cp DIR_RIGHT
	jr nz, .checkPriorityDown1
	ld a, c
	and JOY_RIGHT_MASK
	call nz, SetPriorityToCurrentInput
	jr .doneCheckingPriority1
.checkPriorityDown1
	cp DIR_DOWN
	jr nz, .priorityLeft1
	ld a, c
	and JOY_DOWN_MASK
	call nz, SetPriorityToCurrentInput
	jr .doneCheckingPriority1
.priorityLeft1
	ld a, c
	and JOY_LEFT_MASK
	call nz, SetPriorityToCurrentInput
.doneCheckingPriority1
	
	; if a down input has been pressed since the last movement input check, set it as priority
	ld a, [wLastPlayerInputs]
	cpl
	and b ; b = inputs
	; a = new inputs since last movement input check
.checkNewInputLeft
	bit JOY_LEFT_BIT, a
	jr z, .checkNewInputRight
	ld a, DIR_LEFT
	ld [wPlayerMovementPriority], a
	jr .doneCheckingNewInput
.checkNewInputRight
	bit JOY_RIGHT_BIT, a
	jr z, .checkNewInputUp
	ld a, DIR_RIGHT
	ld [wPlayerMovementPriority], a
	jr .doneCheckingNewInput
.checkNewInputUp
	bit JOY_UP_BIT, a
	jr z, .checkNewInputDown
	ld a, DIR_UP
	ld [wPlayerMovementPriority], a
	jr .doneCheckingNewInput
.checkNewInputDown
	bit JOY_DOWN_BIT, a
	jr z, .doneCheckingNewInput
	ld a, DIR_DOWN
	ld [wPlayerMovementPriority], a
.doneCheckingNewInput
	
	; save inputs for next frame
	ld a, b ; inputs
	ld [wLastPlayerInputs], a
	
	; filter inputs
	ld a, [wPlayerMovementPriority]
.checkPriorityUp2
	cp DIR_UP
	jr nz, .checkPriorityRight2
	ld a, b ; inputs
	and ~(JOY_RIGHT_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK)
	jr .doneCheckingPriority2
.checkPriorityRight2
	cp DIR_RIGHT
	jr nz, .checkPriorityDown2
	ld a, b
	and ~(JOY_UP_MASK | JOY_DOWN_MASK | JOY_LEFT_MASK)
	jr .doneCheckingPriority2
.checkPriorityDown2
	cp DIR_DOWN
	jr nz, .priorityLeft2
	ld a, b
	and ~(JOY_RIGHT_MASK | JOY_UP_MASK | JOY_LEFT_MASK)
	jr .doneCheckingPriority2
.priorityLeft2
	ld a, b
	and ~(JOY_RIGHT_MASK | JOY_DOWN_MASK | JOY_UP_MASK)
.doneCheckingPriority2
	
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
	call GetTilePropertiesAtBCAsXY
	pop de
	pop bc
	
	and TILEPROP_SOLIDITY_MASK
	jr nz, .skipAllowingMove
	
	; Allow move
	ld a, d
	ld [wPlayerMoveDirection], a
	xor a
	ld [wPlayerMoveProgress], a
	; If B is not held then half speed
	ldh a, [hJoypad.down]
	and JOY_B_MASK
	ld a, [wPlayerMoveSpeed]
	jr nz, :+
	srl a
:
	ld [wPlayerMoveSpeedThisTile], a
	
.skipAllowingMove
	; Tick movement
	ld a, [wPlayerMoveDirection]
	cp DIR_NONE
	jp z, .doneTickingMovement
	ld a, [wPlayerMoveSpeedThisTile]
	ld b, a
	ld a, [wPlayerMoveProgress]
	add b
	ld [wPlayerMoveProgress], a
	jp nc, .doneTickingMovement
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
	ld a, [wPlayerPos.x]
	ld b, a
	ld a, [wPlayerPos.y]
	ld c, a
	call GetTilePropertiesAtBCAsXY
	ld [wCurrentTilePropertiesCache], a
	and TILEPROP_SLIPPERINESS_MASK
	jr nz, .slippery
	ld a, [wPlayerMoveDirection]
	ld [wPlayerMoveDirectionCache], a
	call StopPlayerMovement
.slippery
	
	; check for warp
	; walking off map edge first
.checkMovedOffLeftEdge
	ld a, [wPlayerPos.x]
	cp -1
	jr nz, .checkMovedOffRightEdge
	; walked off left edge!
	ld a, SCRN_X_B - 1 ; wrap pos
	ld [wPlayerPos.x], a
	ld de, sizeof_EDGE_WARP_ATTRS * 0
	call EdgeWarpCommonCode
	jr .doneTickingMovement
.checkMovedOffRightEdge
	cp SCRN_X_B
	jr nz, .checkMovedOffTopEdge
	; walked off right edge
	xor a ; wrap pos
	ld [wPlayerPos.x], a
	ld de, sizeof_EDGE_WARP_ATTRS * 1
	call EdgeWarpCommonCode
	jr .doneTickingMovement
.checkMovedOffTopEdge
	ld a, [wPlayerPos.y]
	cp -1
	jr nz, .checkMovedOffBottomEdge
	; walked off top edge
	ld a, SCRN_Y_B - 1 ; wrap pos
	ld [wPlayerPos.y], a
	ld de, sizeof_EDGE_WARP_ATTRS * 2
	call EdgeWarpCommonCode
	jr .doneTickingMovement
.checkMovedOffBottomEdge
	cp SCRN_Y_B
	jr nz, .checkWarpTile
	; walked off bottom edge
	xor a ; wrap pos
	ld [wPlayerPos.y], a
	ld de, sizeof_EDGE_WARP_ATTRS * 3
	call EdgeWarpCommonCode
	jr .doneTickingMovement

.checkWarpTile
	ld a, [wCurrentTilePropertiesCache]
	and TILEPROP_WARP_MASK
	jr z, .doneTickingMovement
	; we stepped onto a warp
	ld b, a ; number of times to step forwards in the search (0 is no warp, 1 is 0 times, 2 is 1 time, etc)
	ld hl, wCurMapTileWarpDestinationsAddress
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld de, sizeof_WARP_ATTRS ; for add hl, de
.warpSearchLoop
	dec b
	jr z, .warpSearchLoopDone
	add hl, de
	jr .warpSearchLoop
.warpSearchLoopDone
	ld a, [hl+]
	ld [wPlayerPos.x], a
	ld a, [hl+]
	ld [wPlayerPos.y], a
	ld a, [hl+]
	ld b, a ; backup bank
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, b
	call StopPlayerMovement	
	call LoadMapAtHLBankA
	
.doneTickingMovement
	; fallthrough
	
UpdatePlayerSpritePos::
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
