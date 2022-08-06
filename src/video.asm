INCLUDE "lib/hardware.asm"

SECTION "Video", ROM0

StopLCD::
	ldh a, [rLCDC]
	rlca
	ret nc
.wait
	ldh a, [rLY]
	cp SCRN_Y
	jr c, .wait
	ldh a, [rLCDC]
	res 7, a ; BG display
	ldh [rLCDC], a
	ret

StartLCD::
	ldh a, [rLCDC]
	or LCDCF_ON
	ldh [rLCDC], a
	ret

WaitVRAMAccess::
	push af
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	pop af
	ret
