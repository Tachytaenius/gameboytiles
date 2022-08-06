; Enum macros taken from pokecrystal

SetEnum: macro
if _NARG >= 1
const_value = \1
else
const_value = 0
endc
endm

Enum: macro
\1 EQU const_value
const_value = const_value + 1
endm
