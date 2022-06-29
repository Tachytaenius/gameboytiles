SECTION "Memory Manipulation", ROM0

; Taken from pokecrystal

ByteFill::
; fill bc bytes with the value of a, starting at hl
    inc b ; we bail the moment b hits 0, so include the last run
    inc c ; same thing; include last byte
    jr .HandleLoop
.PutByte:
    ldi [hl], a
.HandleLoop:
    dec c
    jr nz, .PutByte
    dec b
    jr nz, .PutByte
    ret

CopyBytes::
; copy bc bytes from hl to de
	inc b ; we bail the moment b hits 0, so include the last run
	inc c ; same thing; include last byte
	jr .HandleLoop
.CopyByte:
	ldi a, [hl]
	ld [de], a
	inc de
.HandleLoop:
	dec c
	jr nz, .CopyByte
	dec b
	jr nz, .CopyByte
	ret
