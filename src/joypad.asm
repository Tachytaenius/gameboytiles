INCLUDE "lib/hardware.asm"
INCLUDE "inc/constants.asm"

SECTION "Joypad", ROM0

UpdateJoypad::
	ld a, P1F_4
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	and $0F
	swap a
	ld b, a
	ld a, P1F_5
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	and $0F
	or b
	cpl
	ld d, a
	ld b, a
	ld a, [hJoypad.down]
	cpl
	and b
	ld [hJoypad.pressed], a
	ld a, [hJoypad.down]
	ld b, a
	ld a, d
	cpl
	and b
	ld a, b
	ld [hJoypad.released], a
	ld a, d
	ld [hJoypad.down], a
	ret
