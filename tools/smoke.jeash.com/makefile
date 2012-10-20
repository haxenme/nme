JS := $(patsubst %.hx,%.js,$(wildcard *.hx))

default: $(JS) misc/main.js display

%.js: %.hx
	haxe -js $*.js -cp ../jeash/ --remap flash:jeash -main $* 

misc/main.js: Main.hx
	haxe -js misc/main.js -cp ../jeash/ --remap flash:jeash -main Main.hx

text/main.js: Main.hx
	haxe -js text/main.js -cp ../jeash/ --remap flash:jeash -main Main.hx

clean:
	make clean -C display
	make clean -C events
	make clean -C net

all:
	make all -C display
	make all -C events
	make all -C net
	make -C utils
	make -C zjnue/jeash-rotate-scroll
	make -C zjnue/scrolltest

test:
	make -C phantomjs
