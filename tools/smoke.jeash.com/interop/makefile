default: all

JS := $(patsubst %.hx,%.js,$(wildcard *.hx))

all: $(JS) 

%.js: %.hx
	haxe -debug -lib hscript -D interop -js $*.js -cp ../../../ --remap flash:browser -main $* 

clean:
	touch *.hx
