
.SUFFIXES:

################################################
#                                              #
#             CONSTANT DEFINITIONS             #
#                                              #
################################################

## Directory constants
# These directories can be placed elsewhere if you want; directories whose placement
# must be fixed, lest this Makefile breaks, are hardcoded throughout this Makefile
BINDIR := bin
OBJDIR := obj
DEPDIR := dep

# Shortcut if you want to use a local copy of RGBDS
RGBDS   :=
RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBFIX  := $(RGBDS)rgbfix
RGBGFX  := $(RGBDS)rgbgfx

TILED := tiled

LUA := lua

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

# Argument constants
INCDIRS  = src/ src/include/
WARNINGS = all extra
ASFLAGS  = -p $(PADVALUE) $(addprefix -i,$(INCDIRS)) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -p $(PADVALUE) -v -i "$(GAMEID)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)

# The list of "root" ASM files that RGBASM will be invoked on (all the asm files and subfolder asm files, excluding src/res/)
SRCS = $(shell find src/ -name "*.asm" -not -path "src/res/*")

## Project-specific configuration
# Use this to override the above
include project.mk

################################################
#                                              #
#                    TARGETS                   #
#                                              #
################################################

# `all` (Default target): build the ROM
all: $(ROM)
.PHONY: all

# `clean`: Clean temp and bin files
clean:
	rm -rf $(BINDIR)
	rm -rf $(OBJDIR)
	rm -rf $(DEPDIR)
	rm -rf res
.PHONY: clean

# `rebuild`: Build everything from scratch
# It's important to do these two in order if we're using more than one job
rebuild:
	$(MAKE) clean
	$(MAKE) all
.PHONY: rebuild

###############################################
#                                             #
#                 COMPILATION                 #
#                                             #
###############################################

# How to build a ROM
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(patsubst src/%.asm,$(OBJDIR)/%.o,$(SRCS))
	@mkdir -p $(@D)
	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/build_date.o src/res/build_date.asm
	$(RGBLINK) $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $^ $(OBJDIR)/build_date.o \
	&& $(RGBFIX) -v $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

# `.mk` files are auto-generated dependency lists of the "root" ASM files, to save a lot of hassle.
# Also add all obj dependencies to the dep file too, so Make knows to remake it
# Caution: some of these flags were added in RGBDS 0.4.0, using an earlier version WILL NOT WORK
# (and produce weird errors)
$(OBJDIR)/%.o $(DEPDIR)/%.mk: src/%.asm
	@mkdir -p $(patsubst %/,%,$(dir $(OBJDIR)/$* $(DEPDIR)/$*))
	$(RGBASM) $(ASFLAGS) -M $(DEPDIR)/$*.mk -MG -MP -MQ $(OBJDIR)/$*.o -MQ $(DEPDIR)/$*.mk -o $(OBJDIR)/$*.o $<

ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst src/%.asm,$(DEPDIR)/%.mk,$(SRCS))
endif

################################################
#                                              #
#                RESOURCE FILES                #
#                                              #
################################################


# By default, asset recipes convert files in `res/` into other files in `res/`
# This line causes assets not found in `res/` to be also looked for in `src/res/`
# "Source" assets can thus be safely stored there without `make clean` removing them
VPATH := src

res/%.1bpp: res/%.png
	@mkdir -p $(@D)
	$(RGBGFX) -d 1 -o $@ $<

res/%.2bpp: res/%.png
	@mkdir -p $(@D)
	$(RGBGFX) -d 2 -o $@ $<

# Define how to compress files using the PackBits16 codec
# Compressor script requires Python 3
res/%.pb16: src/tools/pb16.py res/%
	@mkdir -p $(@D)
	$^ $@

# Export tiled maps to json
res/%.tmj: res/tiled/maps/%.tmx
	@mkdir -p $(@D)
	$(TILED) --export-map --embed-tilesets $^ $@

# Convert tiled map exports to assembly files and INCBIN'd map data files
res/maps/%.inc res/maps/%-tile-types.bin res/maps/%-tile-properties.bin: src/tools/tmj2game.lua res/%.tmj
	@mkdir -p $(@D)
	$(LUA) $^ res/maps/$* $*

# Catch non-existent files
# KEEP THIS LAST!!
%:
	@false
