INCLUDE "inc/constants.asm"

section "WRAM0", WRAM0

wStack::
	ds STACK_SIZE * 2 - 1
.bottom::
	ds 1

wCountingBuffer1::
	ds 1
