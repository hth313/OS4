OS4 = ../src
RPN_SRCS =
SRCS = play.s poll.s tvm.s mockups.s countDown.s

OBJS = $(SRCS:%.s=%.o) $(RPN_SRCS:%.rpn=%.o)
MOD = playOS4.mod

all: $(MOD)

%.o: %.rpn
	rpncomp -l --no-fat --prefix-labels LBL_ $<

%.o: %.s
	asnut --cpu=newt  -I$(OS4) -g -l $<

$(MOD): $(OBJS) linker.scm playOS4.moddesc
	lnnut -g $(OBJS) --list-file=linker.lst linker.scm playOS4.moddesc

clean:
	rm $(OBJS) $(MOD)
