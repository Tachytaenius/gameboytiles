INCLUDE "lib/hardware.inc"

DEF NUM_SUBPIXEL_BITS EQU 5

SECTION "Update Player Sprite Pos", ROM0

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
