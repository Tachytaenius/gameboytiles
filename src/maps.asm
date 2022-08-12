MACRO DefWarp
	db \1, \2, BANK(\3)
	dw \3
ENDM

INCLUDE "res/maps/ExampleMap.inc"
INCLUDE "res/maps/ExampleMapHouseInside.inc"
