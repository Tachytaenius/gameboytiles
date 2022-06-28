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
	
	; Copy OAM DMA routine to HRAM
	ld hl, OAMDMASource
	ld bc, OAMDMASource.end - OAMDMASource
	ld de, hOAMDMA
	call CopyBytes
	; Clear shadow OAM
	ld hl, wShadowOAM
	xor a
	ld bc, wShadowOAM.end - wShadowOAM
	call ByteFill
	
	; Set palettes
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	
	; Clear VBlank flag
	xor a
	ld [hVBlankFlag], a
	
	; Clear joypad
	ld hl, hJoypad
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	
	; Enable sprites
	ld a, [rLCDC]
	or LCDCF_OBJON
	ld [rLCDC], a
	
	call GameInit
	
	; Start LCD and enable interrupts
	call StartLCD
	ei
	ld a, IEF_VBLANK
	ldh [rIE], a
	
	jp MainLoop
