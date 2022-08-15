INCLUDE "lib/hardware.inc"

DEF TILEPROP_WARP_MASK         EQU %00001111
DEF TILEPROP_NONSOLID          EQU %00000000
DEF TILEPROP_SOLID             EQU %00010000
DEF TILEPROP_SOLIDITY_MASK     EQU %00010000
DEF TILEPROP_NONSLIPPPERY      EQU %00000000
DEF TILEPROP_SLIPPERY          EQU %00100000
DEF TILEPROP_SLIPPERINESS_MASK EQU %00100000

DEF OUT_OF_BOUNDS_TILE_PROPERTIES EQU TILEPROP_NONSOLID

RSRESET
DEF EDGE_WARP_BANK         RB 1
DEF EDGE_WARP_ADDRESS      RB 2
DEF sizeof_EDGE_WARP_ATTRS RB 0

RSRESET
DEF TILE_WARP_DEST_X          RB 1
DEF TILE_WARP_DEST_Y          RB 1
DEF TILE_WARP_DEST_BANK       RB 1
DEF TILE_WARP_DEST_ADDRESS    RB 2
DEF sizeof_TILE_WARP_ATTRS    RB 0

DEF EDGE_WARPS_SIZE EQU 4 * sizeof_EDGE_WARP_ATTRS

RSRESET
DEF MAP_TILE_TYPES      RB SCRN_X_B * SCRN_Y_B
DEF MAP_TILE_PROPERTIES RB SCRN_X_B * SCRN_Y_B
DEF MAP_EDGE_WARPS      RB EDGE_WARPS_SIZE
DEF sizeof_MAP_ATTRS RB 0

EXPORT TILEPROP_WARP_MASK
EXPORT sizeof_EDGE_WARP_ATTRS
EXPORT TILEPROP_SLIPPERINESS_MASK
EXPORT TILEPROP_SOLIDITY_MASK
EXPORT sizeof_TILE_WARP_ATTRS

SECTION "Map", ROM0

; Returns the property at given x y coordinates in the current map, or a default if out of bounds
; Assumes the map's bank is loaded
; param b: The x coordinate
; param c: The y coordinate
; return a: The requested property
; destroys af hl de
GetTilePropertiesAtBCAsXY::
	; First, we check if we are in bounds
	ld a, b
	cp SCRN_X_B
	jr nc, .outside
	
	ld a, c
	cp SCRN_Y_B
	jr nc, .outside
	
	ld hl, wCurMapAddress
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld de, SCRN_X_B * SCRN_Y_B
	add hl, de

	; add (b = x) to hl
	ld d, 0
	ld e, b
	add hl, de
	
	; add (c = y) * SCRN_X_B to hl
	; ld d, 0
	ld e, c
	ld a, SCRN_X_B
:
	add hl, de
	dec a
	jr nz, :-
	
	ld a, [hl]
	ret

.outside
	ld a, OUT_OF_BOUNDS_TILE_PROPERTIES
	ret

; Loads the requested map
; param a: The requested map's bank
; param hl: The requested map's address
; destroys af hl bc
LoadMapAtHLBankA::
	ld [wCurMapBank], a
	rst SwapBank ; is not backed up
	
	ld a, 1
	ld [wLoadMapTileTypesIntoVRAMFlag], a
	
	ld a, l
	ld [wCurMapAddress], a
	ld a, h
	ld [wCurMapAddress + 1], a
	
	; skip over tile types and properties
	ld bc, SCRN_X_B * SCRN_Y_B * 2
	add hl, bc
	
	; save edge warp addresses
	ld a, l
	ld [wCurMapEdgeWarpDestinationsAddress], a
	ld a, h
	ld [wCurMapEdgeWarpDestinationsAddress + 1], a
	
	ld bc, EDGE_WARPS_SIZE
	add hl, bc
	
	; save tile warps address
	ld a, l
	ld [wCurMapTileWarpDestinationsAddress], a
	ld a, h
	ld [wCurMapTileWarpDestinationsAddress + 1], a
	
	ret

; Loads map's tiles into VRAM
; destroys af hl bc d
LoadMapTileTypesIntoVRAM::
	xor a
	ld [wLoadMapTileTypesIntoVRAMFlag], a
	
	ld hl, wCurMapAddress
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	
	ld bc, _SCRN0
	ld d, SCRN_Y_B ; number of times to loop
	
.rowLoop
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, .rowLoop
	
	ld a, [hl+]
	ld [bc], a
	inc bc
	
	ld a, c
	and %00011111 ; get x component
	cp SCRN_X_B
	jr nz, .rowLoop
	
.nextRow
	dec d
	ret z
	
	ld a, c
	add SCRN_VX_B - SCRN_X_B
	ld c, a
	ld a, b
	adc 0
	ld b, a
	
	jr .rowLoop


SECTION "Map Information", WRAM0

wCurMapBank::
	ds 1

wCurMapAddress::
	ds 2

wCurMapEdgeWarpDestinationsAddress::
	ds 2

wCurMapTileWarpDestinationsAddress::
	ds 2
