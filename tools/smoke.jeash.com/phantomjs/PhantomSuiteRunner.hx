import PhantomJs;

import haxe.PosInfos;
import haxe.Json;
import haxe.macro.Expr;
import haxe.macro.Context;

import utest.Assert;
import utest.Runner;
import utest.TestResult;
import utest.ui.text.PrintReport;

using haxe.io.Path;

using tink.macro.tools.MacroTools;
using tink.core.types.Outcome;

using Lambda;
using Std;
using StringTools;

#if !macro @:build(PhantomSuiteRunner.build()) #end class PhantomTestCase {
}

class PhantomSuiteRunner {
	static var phantom:Phantom #if !macro = untyped window.phantom #end;
	static var TMP_PATH = "/tmp";
	static var BASE_URL = "http://localhost:3001/";
	static var ROOT_PATH = PhantomSuiteRunner.rootPath();
	static var COMPARE_URL = "phantomjs/CompareImages.html";
	static var WAIT_BEFORE_SNAPSHOT = 120;
	static var ASYNC_WAIT = 12000;
	static var DELAY_WAIT_BEFORE_SNAPSHOT = Math.ceil(WAIT_BEFORE_SNAPSHOT * 2.0);
		
	static function main () {
		haxe.Log.trace = function (msg:String, ?pos:PosInfos) {
			untyped window.console.log(msg);
		}

		var runner = new Runner();
		runner.addCase(Type.createEmptyInstance(PhantomTestCase));
		new PrintReport(runner);
		runner.run();
		var returnCode = 0;
		runner.onProgress.add(function (progress: { result : TestResult, done : Int, totals : Int }) if (!progress.result.allOk()) returnCode = 1);
		runner.onComplete.add(function (_) phantom.exit(returnCode));
	}

	public static function loadPage(address: String, cbs: Array<WebPage -> Void>) {
		var page = new WebPage();

		page.onResourceRequested = function (request:WebServerRequest) {
			//trace("Resource requested: " + request.url);
		}

		page.onResourceReceived = function (request:WebServerRequest) {
			//trace("Resource received: " + request.url);
		}

		page.onLoadStarted = function () {
			//trace("Load started");
		}

		page.onLoadFinished = function (_) {
			//trace("Load started" + _);
		}

		page.onConsoleMessage = function (msg) { trace(msg); };

		var async = Assert.createAsync( function () { 
			var delay = WAIT_BEFORE_SNAPSHOT;
			for (cb in cbs) {
				#if js haxe.Timer.delay(Assert.createAsync(function () cb(page), Math.ceil(delay * 2.0)), delay); #end
				delay += WAIT_BEFORE_SNAPSHOT;
			}
			trace("-- done -- " + address); 
		}, ASYNC_WAIT );

		trace("Loading ${address}".format());
		page.open(address, executeAfterPageLoad(async));	
	}

	public static function executeAfterPageLoad( cb: Void -> Void )
		return function (status: String)
			if (status != "success") { 
				phantom.exit(1);
			} else {
				cb();
			}

	public static function stringTest(expected: String) return function (page) stringTestPage(page, expected)
	public static function stringTestPage(page: WebPage, expected: String) {
		Assert.equals(expected, page.evaluate(function () return untyped window.phantomTestResult));
	}
	public static function boolTest() return function (page) boolTestPage(page)
	public static function boolTestPage(page: WebPage) {
#if js
		Assert.isTrue(page.evaluate(function () return untyped window.phantomTestResult));
#end
	}
	public static function intTest(expected: Int) return function (page) intTestPage(page, expected)
	public static function intTestPage(page: WebPage, expected: Int) {
		Assert.equals(expected, page.evaluate(function () return untyped window.phantomTestResult));
	}
	public static function arrayTest(expected: Array<Dynamic>) return function (page) arrayTestPage(page, expected)
	public static function arrayTestPage(page: WebPage, expected: Array<Dynamic>) {
		Assert.same(expected, page.evaluate(function () return untyped window.phantomTestResult));
	}
	public static function imageTest(imageFileName: String) return function (page) imageTestPage(page, imageFileName)
	public static function imageTestPage(page: WebPage, imageFileName: String) {
#if js
			var compareFileName = "/" + imageFileName.withoutDirectory().withoutExtension() + "_compare.png";
			page.render(ROOT_PATH + imageFileName.directory() + compareFileName);
			trace(BASE_URL + COMPARE_URL + "?expected=" + imageFileName + "&actual=" + imageFileName.directory() + compareFileName);
			page.open(BASE_URL + COMPARE_URL + "?expected=" + imageFileName + "&actual=" + imageFileName.directory() + compareFileName, executeAfterPageLoad( Assert.createAsync( function () Assert.isTrue(page.evaluate(function () return untyped window.phantomTestResult)), ASYNC_WAIT) ));
#end
	}

	public static function imageDump(imageFileName: String) return function (page) imageDumpPage(page, imageFileName)
	public static function imageDumpPage(page: WebPage, imageFileName: String) {
#if js
		page.render(ROOT_PATH + imageFileName);
#end
	}

	public static function sendMouseEvent(eventType: String, coords: Array<Int>) return function (page) sendMouseEventPage(page, eventType, coords)
	public static function sendMouseEventPage(page: WebPage, eventType: String, coords: Array<Int>) {
		trace("sending event " + eventType + " to page at x,y = " + coords);
#if js
		page.sendEvent(eventType, coords[0], coords[1]);
#end
	}

	public static function sendKeyboardEvent(eventType: String, keys: Array<Int>) return function (page) sendKeyboardEventPage(page, eventType, keys)
	public static function sendKeyboardEventPage(page: WebPage, eventType: String, keys: Array<Int>) {
		trace("sending event " + eventType + " to page with keys = " + keys);
#if js
		keys.map(function (key) page.sendEvent(eventType, key));
#end
	}

	@:macro public static function rootPath() {
#if neko
		return sys.FileSystem.fullPath(Sys.getCwd() + "/../").toExpr();
#end
	}

#if macro
	@:macro public static function build () : Array<Field> {
		var fields = [];
		for (spec in findSpecs(ROOT_PATH, []))
			for (test in PhantomSuiteRunner.loadSpec(spec)) 
				fields.push(test);
		return fields;
	}
																					 
	public static function findSpecs(cur: String, rest: Array<String>) : Array<String> {
		if (sys.FileSystem.isDirectory(cur)) {
			for (file in sys.FileSystem.readDirectory(cur)) rest = findSpecs(cur + '/' + file, rest);
		} else {
			if (cur.extension() == "spec") rest.push(cur); 
		}
		return rest;
	}

	public static function loadSpec( fileName: String ) : Array<Field> {
		var basename = fileName.withoutExtension().replace(ROOT_PATH, "");
		var content = try sys.io.File.getContent(fileName) catch( e : Dynamic ) Context.error(Std.string(e), Context.currentPos());
		var p = Context.makePosition({min: 0, max: 0, file: fileName });

		var spec : TestSpec = try Json.parse(content) catch ( e : Dynamic ) Context.error(Std.string(e), p);
		var url = BASE_URL + if (spec.target != null) basename.directory() + '/' + spec.target; else basename + ".html"; 

		var fields = Context.getBuildFields();
		var block = [];
		if (spec.events != null) {
			spec.events.map(function (s) 
				if (s.eventType != null && Std.is(s.coords, Array)) {
					if (s.eventType.startsWith("key")) {
						block.push("PhantomSuiteRunner.sendKeyboardEvent".resolve().call([s.eventType.toExpr(), s.coords.toExpr()]));
					} else {
						block.push("PhantomSuiteRunner.sendMouseEvent".resolve().call([s.eventType.toExpr(), s.coords.toExpr()]));
					}
				} else {
					Context.error(s + " should have attribute 'eventType' and array 'coords'", p);
				}
			);
		}
		block.push(switch (spec.testType) {
			case "STRING": 
				var expected = spec.assrt;
				"PhantomSuiteRunner.stringTest".resolve().call([expected.toExpr()]);

			case "BOOL": 
				"PhantomSuiteRunner.boolTest".resolve().call([]);

			case "INT":
				var expected = spec.assrt;
				"PhantomSuiteRunner.intTest".resolve().call([expected.toExpr()]);

			case "ARRAY":
				var expected = spec.assrt;
				"PhantomSuiteRunner.arrayTest".resolve().call([expected.toExpr()]);

			case "IMAGE":
				var img = (basename + ".png");
				if (sys.FileSystem.exists(ROOT_PATH + img)) {
					"PhantomSuiteRunner.imageTest".resolve().call([img.toExpr()]);
				} else {
					"PhantomSuiteRunner.imageDump".resolve().call([img.toExpr()]);
					
				}

			default: Context.error(fileName + " should have a valid testType attribute", p);
		});	
		var test = "PhantomSuiteRunner.loadPage".resolve().call([url.toExpr(), block.toArray()]);
		fields.push({ name : "test" + basename.withoutDirectory(), doc: null, meta: [], access : [APublic], kind: FFun(test.func()), pos : p });
		return fields;

	}
#end
}

typedef TestSpec = { testType: String, assrt: String, target: String, events: Array<EventSpec> };
typedef EventSpec = { eventType: String, coords: Array<Int> };


