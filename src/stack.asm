INCLUDE "include/constants.asm"

SECTION "Stack", WRAM0

wStack::
	ds STACK_SIZE * 2 - 1
.bottom::
	ds 1
