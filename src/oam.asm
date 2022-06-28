INCLUDE "lib/hardware.asm"

SECTION "OAM DMA Source", ROM0

OAMDMASource::
	ldh [rDMA], a
	ld a, 40
:
	dec a
	jr nz, :-
	ret
.end::

SECTION "Shadow OAM", WRAM0, ALIGN[8]

wShadowOAM::
	ds sizeof_OAM_ATTRS * OAM_COUNT
.end::

SECTION "OAM DMA", HRAM

hOAMDMA::
	ds OAMDMASource.end - OAMDMASource
