MACRO define_tile_warp
	db \1, \2, BANK(\3)
	dw \3
ENDM

MACRO define_edge_warp
	db BANK(\1)
	dw \1
ENDM

INCLUDE "res/maps/ExampleMap.inc"
INCLUDE "res/maps/ExampleMapHouseInside.inc"
INCLUDE "res/maps/ExampleMap2.inc"
INCLUDE "res/maps/ExampleMap3.inc"
