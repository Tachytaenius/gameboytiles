INCLUDE "lib/hardware.asm"

STACK_SIZE EQU $80 ; In words, not bytes

JOY_START  EQU 1<<7
JOY_SELECT EQU 1<<6
JOY_B      EQU 1<<5
JOY_A      EQU 1<<4
JOY_DOWN   EQU 1<<3
JOY_UP     EQU 1<<2
JOY_LEFT   EQU 1<<1
JOY_RIGHT  EQU 1<<0

TILEATTR_NONSOLID EQU 0<<0
TILEATTR_SOLID EQU 1<<0

RSRESET
DEF MAP_SPAWN_X RB 1
DEF MAP_SPAWN_Y RB 1
DEF MAP_TILE_DATA RB SCRN_X_B * SCRN_Y_B
DEF sizeof_MAP_ATTRS RB 0

DEF DIR_NONE EQU -1
DEF DIR_UP EQU 0
DEF DIR_RIGHT EQU 1
DEF DIR_DOWN EQU 2
DEF DIR_LEFT EQU 3

DEF PLAYER_MOVE_SPEED EQU 32
DEF NUM_SHIFTS_PLAYER_MOVE_PROGRESS_TO_PIXEL_POSITION EQU 8 - 3
