
SRCS = core.s buffer.s shell.s mainframe.s mainframe_cx.s keyboard.s \
       secondaryFAT.s semiMerged.s xmem.s partial.s assignment.s
OBJS = $(SRCS:%.s=%.o)
MOD = osext.mod

all: $(MOD)

%.o: %.s
	asnut -g -l $<

$(MOD): $(OBJS) linker.scm osext.moddesc
	lnnut -g $(OBJS) --list-file=linker.lst linker.scm osext.moddesc

clean:
	rm $(OBJS) $(MOD)
