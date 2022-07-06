INCLUDE "lib/hardware.asm"
INCLUDE "include/constants.asm"

SECTION "Joypad Memory", HRAM

hJoypad::
.down::
	ds 1
.pressed::
	ds 1
.released::
	ds 1

SECTION "Update Joypad", ROM0

UpdateJoypad::
	ld a, P1F_4
	ldh [rP1], a
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	and $0F
	swap a
	ld b, a
	ld a, P1F_5
	ldh [rP1], a
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	and $0F
	or b
	cpl
	ld d, a
	ld b, a
	ldh a, [hJoypad.down]
	cpl
	and b
	ldh [hJoypad.pressed], a
	ldh a, [hJoypad.down]
	ld b, a
	ld a, d
	cpl
	and b
	ld a, b
	ldh [hJoypad.released], a
	ld a, d
	ldh [hJoypad.down], a
	ret
