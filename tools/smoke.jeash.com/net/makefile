default: all

SWF := $(patsubst %.hx,%.swf,$(wildcard *.hx))
JS := $(patsubst %.hx,%.js,$(wildcard *.hx))
HTML := $(patsubst %.hx,%.html,$(wildcard *.hx))

all: $(JS) $(SWF) $(HTML)

%.js: %.hx
	haxe -debug -js $*.js -cp ../../../ --remap flash:browser -main $* 

%.swf: %.hx
	haxe -swf-header 400:400:8:ffffff -swf9 $*.swf -main $* 

%.html: %.hx
	xsltproc --stringparam jsfile "$*.js" -o $*.html template.xsl main.xml

clean:
	touch *.hx

