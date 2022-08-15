INCLUDE "lib/hardware.inc"

DEF PLAYER_MOVE_SPEED EQU 24

DEF StartingMapLabel EQUS "xExampleMapHouseInside"
DEF SPAWN_X          EQU 7
DEF SPAWN_Y          EQU 4

SECTION "Game Init", ROM0

GameInit::
	; Load tileset
	ld bc, TilesetGraphics.end - TilesetGraphics
	ld hl, TilesetGraphics
	ld de, _VRAM
	call CopyBytes
	
	; Load map
	ld a, BANK(StartingMapLabel)
	ld hl, StartingMapLabel
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
	ld [wPlayerMovementPriority], a ; just to shut up BGB's "uninitialised memory", really, it works fine
	
	call UpdatePlayerSpritePos
	
	ret
