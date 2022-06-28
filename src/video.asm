INCLUDE "lib/hardware.asm"

SECTION "Video", ROM0

StopLCD::
	ld a, [rLCDC]
	rlca
	ret nc
.wait
	ld a, [rLY]
	cp SCRN_Y
	jr c, .wait
	ld a, [rLCDC]
	res 7, a ; BG display
	ld [rLCDC], a
	ret

StartLCD::
	ld a, [rLCDC]
	or LCDCF_ON
	ld [rLCDC], a
	ret

WaitVRAMAccess::
	push af
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	pop af
	ret
