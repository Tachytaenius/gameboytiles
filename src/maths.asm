SECTION "Maths", ROM0

; Taken from pokecrystal

; param a: Multiplier
; param c: Multiplicand
; return a: Product
; destroys f
SimpleMultiply::
	and a
	ret z

	push bc
	ld b, a
	xor a
.loop
	add c
	dec b
	jr nz, .loop
	pop bc
	ret

; Divide a by c
; param a: Dividend
; param c: Divisor
; return a: Remainder
; return b: Quotient
; destroys f
SimpleDivide::
	ld b, 0
.loop
	inc b
	sub c
	jr nc, .loop
	dec b
	add c
	ret
