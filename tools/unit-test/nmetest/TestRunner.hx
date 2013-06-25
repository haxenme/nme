package nmetest;

import sys.*;
import sys.io.*;
using haxe.io.Path;
using StringTools;
using Lambda;
using Reflect;

class TestRunner {
	public var testCases:List<String>;
	public var success:Bool = true;
	public var path:String;
	public var testTargets:{
		neko:Bool,
		js:Bool,
		cpp:Bool,
		flash:Bool
	};
	
	public function new():Void {
		testCases = new List();
		path = "tools/unit-test/";
		testTargets = {
			neko: true,
			js: true,
			cpp: true,
			flash: false
		};
		
		var NME_UNIT_TEST:String = null;
		var args = Sys.args();
		switch (args.length) {
			case 0: //pass
			case 1:
				switch (args[0]) {
					case "neko", "js", "cpp", "flash":
						NME_UNIT_TEST = args[0];
					default:
						testCases.add(args[0]);
				}
			case 2, _:
				testCases.add(args[0]);
				NME_UNIT_TEST = args[1];
		}
		
		if (testCases.length == 0) {
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
		}
		
		if (!FileSystem.exists("bin")) {
			FileSystem.createDirectory("bin");
		}
		
		if (NME_UNIT_TEST == null)
			NME_UNIT_TEST = Sys.getEnv("NME_UNIT_TEST");
		
		if (NME_UNIT_TEST != null) {
			for (target in testTargets.fields()) {
				testTargets.setField(target, target == NME_UNIT_TEST);
			}
		}
		
		for (target in testTargets.fields()) {
			if (testTargets.field(target)) {
				var testMethodName = "test" + target.charAt(0).toUpperCase() + target.substr(1);
				Sys.println('== Test $target '.rpad("=", 50));
				
				if (target == "js"){
					//compile PhantomRunner
					Sys.println('-- PhantomRunner');
					if (runProcess("haxe", [path + "PhantomRunner.hxml"])) {
						Sys.println('   OK\n');
					} else {
						return;
					}
				}
				
				for (testCase in testCases) {
					this.callMethod(this.field(testMethodName), [testCase]);
				}
			}
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
	
	public function testFlash(testCase:String):Void {
		Sys.println('-- $testCase');
		if (testCase.endsWith("NMETest")) {
			runProcess("haxelib", 'run nme test ${getNmml(testCase)} flash'.split(" "));
		} else {
			runProcess("haxe", '-cp tools/unit-test -main $testCase -swf bin/${testCase}.swf -swf-version 11.4'.split(" ")) &&
			runProcess("open", ['bin/${testCase}.swf']);
		}
	}
	
	public function testNeko(testCase:String):Void {
		Sys.println('-- $testCase');
		if (testCase.endsWith("NMETest")) {
			if (Sys.environment().exists("TRAVIS")) {
				Sys.println("      Skipped.");
			} else {
				runProcess("haxelib", 'run nme test ${getNmml(testCase)} neko'.split(" "));
			}
		} else {
			runProcess("haxe", '-cp tools/unit-test --remap flash:nme -main $testCase -neko bin/${testCase}.n'.split(" ")) &&
			runProcess("neko", ['bin/${testCase}.n']);
		}
	}
	
	public function testCpp(testCase:String):Void {
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
	
	public function testJs(testCase:String):Void {		
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
	
	/**
	* Run a process. The process output will be printed.
	*/
	public function runProcess(cmd : String, args : Array<String>, ?shouldPass = true, ?indent = "   "):Bool {
		Sys.println("start process: " + cmd + " " + args.join(" "));
		var p = new Process(cmd, args);
		Sys.println(indent + p.stdout.readAll().toString().replace("\n", "\n" + indent));
		var exitCode = p.exitCode();
		if (exitCode != 0) {
			Sys.println(indent + p.stderr.readAll().toString().replace("\n", "\n" + indent));
		}
		Sys.println("process exited with: " + exitCode);
		
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
