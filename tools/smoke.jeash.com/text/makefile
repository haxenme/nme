default: all

SWF := $(patsubst %.hx,%.swf,$(wildcard *.hx))
JS := $(patsubst %.hx,%.js,$(wildcard *.hx))
HTML := $(patsubst %.hx,%.html,$(wildcard *.hx))
TTFHASH := $(patsubst %.hx,%.ttf.hash,$(wildcard *.hx))
TTFSWF := $(patsubst %.hx,%.ttf.swf,$(wildcard *.hx))

all: $(TTFHASH) $(JS) $(TTFSWF) $(SWF) $(HTML)

%.ttf.hash: %.hx
	neko ../../../templates/default/html5/hxswfml.n ttf2hash $*.ttf

%.ttf.swf: %.hx
	#	neko ../../../templates/default/html5/hxswfml.n ttf2swf $*.ttf $*.ttf.swf -class $*Font

%.js: %.hx
	haxe -resource $*.ttf.hash@$*Font -debug -js $*.js -cp ../../../ --remap flash:browser -main $* 

%.swf: %.hx
	#	haxe -swf-lib $*.ttf.swf -cp ../../../ -swf-header 400:400:8:ffffff -swf9 $*.swf -main $* 

%.html: %.hx
	xsltproc --stringparam jsfile "$*.js" -o $*.html template.xsl main.xml

clean:
	touch *.hx

