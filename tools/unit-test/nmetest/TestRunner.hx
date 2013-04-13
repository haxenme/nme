package nmetest;

import sys.*;
import sys.io.*;
using haxe.io.Path;
using StringTools;
using Lambda;

class TestRunner {
	public var testCases:List<String>;
	public var success:Bool;
	public var path:String;
	public function new():Void {
		testCases = new List();
		path = "tools/unit-test/";
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
			Sys.println('-- $testCase');
			if (testCase.endsWith("NMETest")) {
				var nmml = path + testCase.replace(".", "/").withoutExtension() + ".nmml";
				if (!(
					runProcess("haxelib", 'run nme test $nmml neko'.split(" ")) == 0
				)) {
					success = false;
				}
			} else {
				if (!(
					runProcess("haxe", '-cp tools/unit-test --remap flash:nme -main $testCase -neko bin/${testCase}.n'.split(" ")) == 0 &&
					runProcess("neko", ['bin/${testCase}.n']) == 0
				)) {
					success = false;
				}
			}
		}
	}
	
	public function testCpp():Void {
		for (testCase in testCases) {
			Sys.println('-- $testCase');
			if (testCase.endsWith("NMETest")) {
				var nmml = path + testCase.replace(".", "/").withoutExtension() + ".nmml";
				var compileArgs = 'run nme test $nmml cpp'.split(" ");
				
				if (Sys.args().indexOf("-64") != -1 || Sys.environment().exists("TRAVIS")) {
					compileArgs.push("-DHXCPP_M64");
				}
				if (!(
					runProcess("haxelib", compileArgs) == 0
				)) {
					success = false;
				}
			} else {
				var testCaseName = testCase.substr(testCase.lastIndexOf(".")+1);
				var compileArgs = '-cp tools/unit-test --remap flash:nme -main $testCase -cpp bin'.split(" ");
				
				if (Sys.args().indexOf("-64") != -1 || Sys.environment().exists("TRAVIS")) {
					compileArgs.push("-D");
					compileArgs.push("HXCPP_M64");
				}
				
				if (!(
					runProcess("haxe", compileArgs) == 0 &&
					runProcess('bin/$testCaseName', []) == 0
				)) {
					success = false;
				}
			}
		}
	}
	
	public function testJs():Void {
		//compile PhantomRunner
		Sys.println('-- PhantomRunner');
		if (!(runProcess("haxe", [path + "PhantomRunner.hxml"]) == 0)) {
			success = false;
			return;
		}
		Sys.println('   OK\n');
		
		
		for (testCase in testCases) {
			Sys.println('-- $testCase');
			if (testCase.endsWith("NMETest")) {
				var nmml = path + testCase.replace(".", "/").withoutExtension() + ".nmml";
				if (!(
					runProcess("haxelib", 'run nme build $nmml html5'.split(" ")) == 0 &&
					runProcess("phantomjs", ["bin/nmetest.PhantomRunner.js", "html5/bin/index.html"]) == 0
				)) {
					success = false;
				}
			} else {
				var testCaseName = testCase.substr(testCase.lastIndexOf(".")+1);
				if (!(
					runProcess("haxe", '-cp tools/unit-test --remap flash:nme -main $testCase -js bin/${testCase}.js -lib phantomjs'.split(" ")) == 0 &&
					runProcess("phantomjs", ['bin/${testCase}.js']) == 0
				)) {
					success = false;
				}
			}
		}
	}
	
	static public function runProcess(cmd : String, args : Array<String>, ?indent = "   "):Int {
		Sys.println("start process: " + cmd + " " + args.join(" "));
		var p = new Process(cmd, args);
		Sys.println(indent + p.stdout.readAll().toString().replace("\n", "\n" + indent));
		var exitCode = p.exitCode();
		Sys.println("process exit with: " + exitCode);
		return exitCode;
	}
	
	static var instance(default, null):TestRunner;
	static function main():Void {
		instance = new TestRunner();
	}
}
