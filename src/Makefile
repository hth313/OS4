
SRCS = core.s coreBank2.s buffer.s shell.s keyboard.s catalog.s \
       secondaryFAT.s semiMerged.s xmem.s partial.s assignment.s timer.s
OBJS = $(SRCS:%.s=%.o)
MOD = OS4.mod

all: $(MOD)

%.o: %.s
	asnut --cpu=NEWT -g -l $<

$(MOD): $(OBJS) linker.scm OS4.moddesc
	lnnut -g $(OBJS) --list-file=linker.lst --extra-output-formats=mod2 linker.scm OS4.moddesc

clean:
	rm $(OBJS) $(MOD)
