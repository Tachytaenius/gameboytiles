MACRO DefTileWarp
	db \1, \2, BANK(\3)
	dw \3
ENDM

MACRO DefEdgeWarp
	db BANK(\1)
	dw \1
ENDM

INCLUDE "res/maps/ExampleMap.inc"
INCLUDE "res/maps/ExampleMapHouseInside.inc"
INCLUDE "res/maps/ExampleMap2.inc"
