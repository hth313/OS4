
SRCS = core.s buffer.s shell.s mainframe.s mainframe_cx.s keyboard.s \
       secondaryFAT.s semiMerged.s xmem.s partial.s assignment.s timer.s
OBJS = $(SRCS:%.s=%.o)
MOD = OS4.mod

all: $(MOD)

%.o: %.s
	asnut -g -l $<

$(MOD): $(OBJS) linker.scm OS4.moddesc
	lnnut -g $(OBJS) --list-file=linker.lst linker.scm OS4.moddesc

clean:
	rm $(OBJS) $(MOD)
