.POSIX:
.SUFFIXES: .asm

name = tiles
src = src/
obj = ${src}/header.o ${src}/init.o ${src}/memory/hram.o ${src}/memory/wram.o ${src}/video.o ${src}/oam.o ${src}/memmanip.o ${src}/joypad.o ${src}/gameinit.o ${src}/mainloop.o ${src}/vblank.o ${src}/tiledata.o

all: ${name}.gb

clean:
	@rm -f ${obj} ${name}.gb ${name}.sym

gfx:
	@find -iname "*.png" -exec sh -c 'rgbgfx -o $${1%.png}.2bpp $$1' _ {} \;

.asm.o:
	@rgbasm -i ${src}/ -o $@ $<

${name}.gb: gfx ${obj}
	@rgblink -n ${name}.sym -o $@ ${obj}
	@rgbfix -jv -i TILE -k HB -l 0x33 -m 0x01 -p 0 -r 0 -t TILES $@
