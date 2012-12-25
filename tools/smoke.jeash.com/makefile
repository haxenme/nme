default: clean all test

clean:
	make clean -C display
	make clean -C events
	make clean -C net
	make clean -C interop
	make clean -C media

all:
	make all -C display
	make all -C events
	make all -C net
	make -C utils
	make -C zjnue/jeash-rotate-scroll
	make -C zjnue/scrolltest
	make all -C interop
	make all -C media

test:
	make -C phantomjs
