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
		
		if (success) {
			Sys.println("ALL OK");
			Sys.exit(0);
		} else {
			Sys.println("FAIL");
			Sys.exit(1);
		}
	}
	
	/**
	* Returns the path to the nmml of an NMETest.
	* If there is no nmml placed next to the NMETest hx file, a minimal nmml will be created from "NMETest.tpl.nmml".
	*/
	public function getNmml(testCase:String):String {
		var nmml = path + testCase.replace(".", "/").withoutExtension() + ".nmml";
		//if custom nmml does not exist
		if (!FileSystem.exists(nmml)) {
			nmml = "bin/NMETest.nmml";
			var nmmlContent = new haxe.Template(File.getContent(path + "NMETest.tpl.nmml")).execute({
				testCase: testCase
			});
			File.saveContent(nmml, nmmlContent);
		}
		
		return nmml;
	}
	
	public function testNeko():Void {
		for (testCase in testCases) {
			Sys.println('-- $testCase');
			if (testCase.endsWith("NMETest")) {
				runProcess("haxelib", 'run nme test ${getNmml(testCase)} neko'.split(" "));
			} else {
				runProcess("haxe", '-cp tools/unit-test --remap flash:nme -main $testCase -neko bin/${testCase}.n'.split(" ")) &&
				runProcess("neko", ['bin/${testCase}.n']);
			}
		}
	}
	
	public function testCpp():Void {
		for (testCase in testCases) {
			Sys.println('-- $testCase');
			if (testCase.endsWith("NMETest")) {
				var compileArgs = 'run nme test ${getNmml(testCase)} cpp'.split(" ");
				
				if (Sys.args().indexOf("-64") != -1 || Sys.environment().exists("TRAVIS")) {
					compileArgs.push("-DHXCPP_M64");
				}
				
				runProcess("haxelib", compileArgs);
			} else {
				var testCaseName = testCase.substr(testCase.lastIndexOf(".")+1);
				var compileArgs = '-cp tools/unit-test --remap flash:nme -main $testCase -cpp bin'.split(" ");
				
				if (Sys.args().indexOf("-64") != -1 || Sys.environment().exists("TRAVIS")) {
					compileArgs.push("-D");
					compileArgs.push("HXCPP_M64");
				}
				
				runProcess("haxe", compileArgs) &&
				runProcess('bin/$testCaseName', []);
			}
		}
	}
	
	public function testJs():Void {
		//compile PhantomRunner
		Sys.println('-- PhantomRunner');
		if (runProcess("haxe", [path + "PhantomRunner.hxml"])) {
			Sys.println('   OK\n');
		} else {
			return;
		}
		
		
		for (testCase in testCases) {
			Sys.println('-- $testCase');
			if (testCase.endsWith("NMETest")) {
				runProcess("haxelib", 'run nme build ${getNmml(testCase)} html5'.split(" ")) &&
				runProcess("phantomjs", ["bin/nmetest.PhantomRunner.js", "html5/bin/index.html"]);
			} else {
				var testCaseName = testCase.substr(testCase.lastIndexOf(".")+1);
				runProcess("haxe", '-cp tools/unit-test --remap flash:nme -main $testCase -js bin/${testCase}.js -lib phantomjs'.split(" ")) &&
				runProcess("phantomjs", ['bin/${testCase}.js']);
			}
		}
	}
	
	/**
	* Run a process. The process output will be printed.
	*/
	public function runProcess(cmd : String, args : Array<String>, ?shouldPass = true, ?indent = "   "):Bool {
		Sys.println("start process: " + cmd + " " + args.join(" "));
		var p = new Process(cmd, args);
		Sys.println(indent + p.stdout.readAll().toString().replace("\n", "\n" + indent));
		var exitCode = p.exitCode();
		Sys.println("process exit with: " + exitCode);
		
		if (shouldPass && exitCode != 0) {
			success = false;
		}
		
		return exitCode == 0;
	}
	
	static var instance(default, null):TestRunner;
	static function main():Void {
		instance = new TestRunner();
	}
}
