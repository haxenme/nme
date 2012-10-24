.PHONY : PhantomSuiteRunner.js

run: build
	phantomjs ./PhantomSuiteRunner.js

build: CompareImages PhantomSuiteRunner

CompareImages: CompareImages.hx
	haxe -js CompareImages.js -main CompareImages -lib pdiff-hx

PhantomSuiteRunner: PhantomSuiteRunner.hx
	haxe -js PhantomSuiteRunner.js -main PhantomSuiteRunner -lib tink_macros -lib utest 
