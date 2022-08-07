INCLUDE "lib/hardware.inc"
INCLUDE "include/constants.inc"

SECTION "Game Init", ROM0

GameInit::
	; Load tileset
	ld bc, TilesetGraphics.end - TilesetGraphics
	ld hl, TilesetGraphics
	ld de, _VRAM
	call CopyBytes
	
	; Load map
	ld a, BANK(StartingMap)
	ld hl, StartingMap
	call LoadMapAtHLBankA
	ld a, SPAWN_X
	ld [wPlayerPos.x], a
	ld a, SPAWN_Y
	ld [wPlayerPos.y], a
	
	; Make sprite 0 a player
	ld hl, wShadowOAM + sizeof_OAM_ATTRS * 0
	ld a, 0 + 16
	ld [hl+], a
	ld a, 0 + 8
	ld [hl+], a
	ld a, TILE_PLAYER
	ld [hl+], a
	
	ld a, PLAYER_MOVE_SPEED
	ld [wPlayerMoveSpeed], a
	xor a
	ld [wPlayerMoveProgress], a
	ld [wLastPlayerInputs], a
	ld a, DIR_NONE
	ld [wPlayerMoveDirection], a
	
	call UpdatePlayerSpritePos
	
	ret
