INCLUDE "include/constants.inc"

DEF DIR_NONE  EQU -1
DEF DIR_UP    EQU 0
DEF DIR_RIGHT EQU 1
DEF DIR_DOWN  EQU 2
DEF DIR_LEFT  EQU 3

EXPORT DIR_NONE
EXPORT DIR_UP
EXPORT DIR_RIGHT
EXPORT DIR_DOWN
EXPORT DIR_LEFT

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
