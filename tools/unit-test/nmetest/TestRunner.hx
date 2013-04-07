package nmetest;

import sys.*;
import sys.io.*;
using StringTools;

class TestRunner {
	public var testCases:List<String>;
	public var success:Bool;
	public function new():Void {
		testCases = new List();
		var path = "tools/unit-test/";
		function getTestCases(dir:String) {
			for (item in FileSystem.readDirectory(dir)) {
				if (FileSystem.isDirectory(dir + item)) {
					getTestCases(dir + item + "/");
				} else if (item.endsWith("Test.hx")) {
					testCases.add((dir + item).substr(path.length).replace("/", ".").substr(0, -3));
				}
			}
		}
		getTestCases(path);
		
		if (!FileSystem.exists("bin")) {
			FileSystem.createDirectory("bin");
		}
		
		success = true;
		
		var NME_UNIT_TEST = Sys.getEnv("NME_UNIT_TEST");
		if (NME_UNIT_TEST == null || NME_UNIT_TEST == "neko") {
			Sys.println("== Test neko ".rpad("=", 50));
			testNeko();
		}
		if (NME_UNIT_TEST == null || NME_UNIT_TEST == "js") {
			Sys.println("== Test js ".rpad("=", 50));
			testJs();
		}
		if (NME_UNIT_TEST == null || NME_UNIT_TEST == "cpp") {
			Sys.println("== Test cpp ".rpad("=", 50));
			testCpp();
		}
		
		Sys.exit(success ? 0 : 1);
	}
	
	public function testNeko():Void {
		for (testCase in testCases) {
			if (!(
				runProcess("haxe", '-cp tools/unit-test --remap flash:nme -main $testCase -neko bin/${testCase}.n'.split(" ")) == 0 &&
				runProcess("neko", ['bin/${testCase}.n']) == 0
			)) {
				success = false;
			}
		}
	}
	
	public function testCpp():Void {
		for (testCase in testCases) {
			var testCaseName = testCase.substr(testCase.lastIndexOf(".")+1);
			if (!(
				runProcess("haxe", '-cp tools/unit-test --remap flash:nme -main $testCase -cpp bin -D HXCPP_M64'.split(" ")) == 0 &&
				runProcess('bin/$testCaseName', []) == 0
			)) {
				success = false;
			}
		}
	}
	
	public function testJs():Void {
		for (testCase in testCases) {
			var testCaseName = testCase.substr(testCase.lastIndexOf(".")+1);
			if (!(
				runProcess("haxe", '-cp tools/unit-test --remap flash:nme -main $testCase -js bin/${testCase}.js -lib phantomjs'.split(" ")) == 0 &&
				runProcess("phantomjs", ['bin/${testCase}.js']) == 0
			)) {
				success = false;
			}
		}
	}
	
	static public function runProcess(cmd : String, args : Array<String>):Int {
		var p = new Process(cmd, args);
		var exitCode = p.exitCode();
		Sys.println(p.stdout.readAll().toString());
		return exitCode;
	}
	
	static var instance(default, null):TestRunner;
	static function main():Void {
		instance = new TestRunner();
	}
}
