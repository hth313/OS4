
SRCS = core.s buffer.s shell.s mainframe.s
OBJS = $(SRCS:%.s=%.o)
MOD = osext.mod

all: $(MOD)

%.o: %.s
	asnut -g -l $<

$(MOD): $(OBJS) linker.scm osext.moddesc
	lnnut -g $(OBJS) -llinker.lst linker.scm osext.moddesc

clean:
	rm $(OBJS) $(MOD)
