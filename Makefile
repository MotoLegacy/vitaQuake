TARGET		:= vitaQuake
TITLE		:= QUAK00001
GIT_VERSION := $(shell git describe --abbrev=6 --dirty --always --tags)
SHADERS     := shaders

LIBS = -lvitaGL -lvitashark -lSceShaccCgExt -ltaihen_stub -lvorbisfile -lvorbis -logg \
	-lspeexdsp -lmpg123 -lScePspnetAdhoc_stub -lSceShaccCg_stub -lSceKernelDmacMgr_stub \
	-lc -lSceCommonDialog_stub -lSceAudio_stub -lSceLibKernel_stub -lmathneon \
	-lSceNet_stub -lSceNetCtl_stub -lpng -lSceDisplay_stub -lSceGxm_stub \
	-Wl,--whole-archive -lSceSysmodule_stub -Wl,--no-whole-archive \
	-lSceCtrl_stub -lSceTouch_stub -lSceMotion_stub -lm -lSceAppMgr_stub \
	-lSceAppUtil_stub -lScePgf_stub -ljpeg -lSceRtc_stub -lScePower_stub -lcurl -lssl -lcrypto -lz

COMMON_OBJS =	source/chase.o \
	source/cl_demo.o \
	source/cl_input.o \
	source/cl_main.o \
	source/cl_parse.o \
	source/cl_tent.o \
	source/chase.o \
	source/cmd.o \
	source/common.o \
	source/console.o \
	source/crc.o \
	source/cvar.o \
	source/host.o \
	source/host_cmd.o \
	source/image.o \
	source/keys.o \
	source/mathlib.o \
	source/menu.o \
	source/net_dgrm.o \
	source/net_loop.o \
	source/net_main.o \
	source/net_vcr.o \
	source/pr_cmds.o \
	source/pr_edict.o \
	source/pr_exec.o \
	source/r_part.o \
	source/sbar.o \
	source/sv_main.o \
	source/sv_move.o \
	source/sv_phys.o \
	source/sv_user.o \
	source/view.o \
	source/wad.o \
	source/world.o \
	source/zone.o \
	source/sys_psp2.o \
	source/gl_draw.o \
	source/gl_mesh.o \
	source/gl_model.o \
	source/gl_refrag.o \
	source/gl_rlight.o \
	source/gl_rmain.o \
	source/gl_rmisc.o \
	source/gl_rsurf.o \
	source/gl_screen.o \
	source/gl_warp.o \
	source/gl_fullbright.o \
	source/r_part.o \
	source/snd_dma.o \
	source/snd_mix.o \
	source/snd_mem.o \
	source/snd_psp2.o \
	source/net_psp2.o \
	source/net_adhoc_psp2.o \
	source/net_udp_psp2.o \
	source/in_psp2.o \
	source/gl_vidpsp2.o \
	source/neon_mathfun.o \
	source/webdownload.o
	
CPPSOURCES	:= source/audiodec

CFILES	:= $(COMMON_OBJS)
CPPFILES   := $(foreach dir,$(CPPSOURCES), $(wildcard $(dir)/*.cpp))
CGFILES  := $(foreach dir,$(SHADERS), $(wildcard $(dir)/*.cg))
CGSHADERS  := $(CGFILES:.cg=.h)
OBJS     := $(CFILES:.c=.o) $(CPPFILES:.cpp=.o)

PREFIX  = arm-vita-eabi
CC      = $(PREFIX)-gcc
CXX      = $(PREFIX)-g++
CFLAGS  = -fsigned-char -Wl,-q -O3 -g -fno-optimize-sibling-calls \
	-ffast-math -mtune=cortex-a9 -mfpu=neon \
	-DGLQUAKE -DHAVE_OGGVORBIS -DHAVE_MPG123 -DHAVE_LIBSPEEXDSP \
	-DUSE_AUDIO_RESAMPLER -DGIT_VERSION=\"$(GIT_VERSION)\"
CXXFLAGS  = $(CFLAGS) -fno-exceptions -std=gnu++11
ASFLAGS = $(CFLAGS)

all: $(TARGET).vpk

$(TARGET).vpk: $(TARGET).velf
	vita-make-fself -c -s $< build/eboot.bin
	vita-mksfoex -s TITLE_ID=$(TITLE) -d ATTRIBUTE2=12 "$(TARGET)" param.sfo
	cp -f param.sfo build/sce_sys/param.sfo
	vita-pack-vpk -s param.sfo -b build/eboot.bin $(TARGET).vpk \
		-a build/shaders=shaders \
		-a build/sce_sys=sce_sys

%_f.h:
	psp2cgc -profile sce_fp_psp2 $(@:_f.h=_f.cg) -Wperf -fastprecision -O3 -o build/$(@:_f.h=_f.gxp)
	
%_v.h:
	psp2cgc -profile sce_vp_psp2 $(@:_v.h=_v.cg) -Wperf -fastprecision -O3 -o build/$(@:_v.h=_v.gxp)
	
shaders: $(CGSHADERS)
	
%.velf: %.elf
	cp $< $<.unstripped.elf
	$(PREFIX)-strip -g $<
	vita-elf-create $< $@

$(TARGET).elf: $(OBJS)
	$(CXX) $(CXXFLAGS) $^ $(LIBS) -o $@

clean:
	@rm -rf $(TARGET).velf $(TARGET).elf $(OBJS) $(TARGET).elf.unstripped.elf $(TARGET).vpk build/eboot.bin build/sce_sys/param.sfo ./param.sfo
