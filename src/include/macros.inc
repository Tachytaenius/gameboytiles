DefWarp: MACRO
	db \1, \2, BANK(\3)
	dw \3
ENDM
