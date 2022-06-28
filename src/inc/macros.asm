Copy: macro
	ld hl, \2
	ld bc, \2.end - \2
	ld de, \1
	call CopyBytes
endm

Fill: macro
	ld hl, \1
	ld bc, \1.end - \1
	ld a, \2
	call ByteFill
endm

LoadHLIntoAddress: macro
	ld a, l
	ld [\1], a
	ld a, h
	ld [\1 + 1], a
endm

LoadHLFromAddress: macro
	ld a, [\1]	
	ld l, a
	ld a, [\1 + 1]
	ld h, a
endm

LoadWordAtHLIntoHL: macro
	ld a, [hl+]
	ld h, [hl]
	ld l, a
endm

Breakpoint: macro
	ld b, b ; on some emulators
endm

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
