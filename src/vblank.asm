section	"VBlank IRQ Vector", ROM0[$40]

VBlankVector::
	push af
	ld a, 1
	ldh [hVBlankFlag], a
	pop af
	reti
