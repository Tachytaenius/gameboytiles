INCLUDE "inc/macros.asm"
INCLUDE "lib/hardware.asm"

SECTION "Init", ROM0

Init::
	; Game Boy Colour?
	cp $11
	ld a, 1
	jr z, .cgb
	xor a
.cgb
	ldh [hGBCFlag], a
	
	di
	ld sp, wStack.bottom
	call StopLCD
	
	; Setup OAM library
	call ResetOAM
	ld hl, OAMDMA
	ld bc, OAMDMA.end - OAMDMA
	ld de, hOAMDMA
	call CopyBytes
	
	; Set palettes
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	
	; Clear frame status
	xor a
	ld [hFrameStatus], a
	; Clear joypad
	ld hl, hJoypad
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	
	; Enable sprites
	ld a, [rLCDC]
	or LCDCF_OBJON | LCDCF_OBJ16
	ld [rLCDC], a
	
	; call GameInit
	
	; Start LCD and enable interrupts
	call StartLCD
	ei
	ld a, IEF_VBLANK
	ldh [rIE], a
	
	jr @
	
	; jp MainLoop
