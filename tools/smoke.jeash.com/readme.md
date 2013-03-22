# smoke.jeash.com

It is a set of tests for the NME html5 target that originally created by Niel Drummond.
It can be run on Mac/Linux.

Each of the tests normally comprises of
 * A *.hx* file, which is the haxe code.
 * A *.hxml* file, which is used to compile the haxe code.
 * A *.spec* file, which tells what the test type is and what events need to be fired by the browser. 
   Read [phantomjs/PhantomSuiteRunner.hx](https://github.com/haxenme/NME/blob/master/tools/smoke.jeash.com/phantomjs/PhantomSuiteRunner.hx) for the details.

Some of the tests are temporarily disable and need to be fixed. Read [line 160 of phantomjs/PhantomSuiteRunner.hx ](https://github.com/haxenme/NME/blob/master/tools/smoke.jeash.com/phantomjs/PhantomSuiteRunner.hx#L160) for the list of disabled tests.

## dependencies

To run the test, a number of dependencies need to be installed.

### node.js

[node.js](http://nodejs.org/) and a number of node.js libraries (defined by **package.json** in the root directory) is needed.
It is used to run a server to host the web pages and resource needed by the tests.

Once we've node.js installed, we can install the node.js libraries by:

```
cd path/to/NME
npm install
```

### PhantomJS

The tests are run by [PhantomJS](http://phantomjs.org/), which is a headless WebKit, think of it a browser without UI.

### haxe libraries

The following need to be installed:
 * pdiff-hx
 * utest
 * format
 * hscript

### xsltproc

[xsltproc](http://xmlsoft.org/XSLT/xsltproc2.html) should be pre-installed on Mac. On Linux, we can install it by `sudo apt-get install xsltproc`.

## run it

1. Change directory to smoke.jeash.com.
   ```
   cd tools/smoke.jeash.com
   ```
1. Start the node server. Since it will not return, we need the trailing **&**.
   ```
   node webserver.js &
   ```
2. Run the tests.
   ```
   make clean  #clean the tests, if they were run previously
   make all    #compile the tests
   make test   #compile and run the PhantomJS test runner
   ```