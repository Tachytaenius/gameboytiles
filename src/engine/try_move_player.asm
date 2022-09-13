INCLUDE "include/constants.inc"

SECTION "Try Move Player Variables", WRAM0

wCurrentTilePropertiesCache:
	ds 1

wPlayerMoveDirectionCache:
	ds 1

wPlayerMoveSpeedThisTile:
	ds 1

SECTION "Try Move Player", ROM0

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

TryMovePlayer::
	ld a, [wPlayerMoveDirection]
	cp DIR_NONE
	jp nz, .skipAllowingMove
	
	ldh a, [hJoypad.down]
	ld b, a
	ld a, [wPlayerMovementPriority]
	and b
	jr nz, .skipChangingDirection
	
.changeDirection
	ldh a, [hJoypad.down]
.changeDirectionTryLeft
	bit JOY_LEFT_BIT, a
	jr z, .changeDirectionTryRight
	ld a, JOY_LEFT_MASK
	jr .doneChangeDirection
.changeDirectionTryRight
	bit JOY_RIGHT_BIT, a
	jr z, .changeDirectionTryUp
	ld a, JOY_RIGHT_MASK
	jr .doneChangeDirection
.changeDirectionTryUp
	bit JOY_UP_BIT, a
	jr z, .changeDirectionTryDown
	ld a, JOY_UP_MASK
	jr .doneChangeDirection
.changeDirectionTryDown
	bit JOY_DOWN_BIT, a
	jr z, .changeDirectionNone
	ld a, JOY_DOWN_MASK
	jr .doneChangeDirection
.changeDirectionNone
	xor a
	; fallthrough
.doneChangeDirection
	ld [wPlayerMovementPriority], a
.skipChangingDirection
	
	; filter inputs
	ldh a, [hJoypad.down]
	ld b, a
	ld a, [wPlayerMovementPriority]
	and b
	
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
.notSlippery
	ld a, [wPlayerMoveDirection]
	ld [wPlayerMoveDirectionCache], a ; in case we walk off a map into a slippery tile and do indeed need to slip
	call StopPlayerMovement
	jr .doneCheckingSlipperiness
.slippery
	ld a, [wPlayerMoveDirection]
.slipperyCheckMovingLeft
	cp DIR_LEFT
	jr nz, .slipperyCheckMovingRight
	dec b
	jr .slipperyDoneCheckingMoveDirection
.slipperyCheckMovingRight
	cp DIR_RIGHT
	jr nz, .slipperyCheckMovingUp
	inc b
	jr .slipperyDoneCheckingMoveDirection
.slipperyCheckMovingUp
	cp DIR_UP
	jr nz, .slipperyCheckMovingDown
	dec c
	jr .slipperyDoneCheckingMoveDirection
.slipperyCheckMovingDown
	; assume it's down
	inc c
	; fallthrough
.slipperyDoneCheckingMoveDirection
	call GetTilePropertiesAtBCAsXY
	and TILEPROP_SOLIDITY_MASK
	jr z, .doneCheckingSlipperiness
	call StopPlayerMovement
.doneCheckingSlipperiness
	
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
	ld de, sizeof_TILE_WARP_ATTRS ; for add hl, de
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
	jp UpdatePlayerSpritePos
