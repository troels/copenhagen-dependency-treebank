%-auto.atag:
	../tools/tags2atag da es $*

all:
	make `cd ../src ; cat mini1.ids mini2.ids mini3.ids  | sed -e 's/$$/-auto.atag/g'`
