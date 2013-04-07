package nmetest;

import haxe.macro.Expr;
import haxe.macro.*;

#if !macro @:autoBuild(nmetest.TestBaseBuilder.build()) #end
interface TestBase {}

class TestBaseBuilder {
	#if macro
	static public function build():Array<Field> {
		var fields = Context.getBuildFields();
		var cPos = Context.currentPos();
		var cls = Context.getLocalClass().get();
		var clsName = cls.name;
		
		var mainField:Field = {
			name: "main",
			access: [AStatic, APublic],
			kind: FFun({
				args: [],
				ret: macro:Void,
				expr:
					if (Context.defined("sys"))
						macro {
							var runner = new haxe.unit.TestRunner();
							runner.add(new $clsName());
							Sys.exit(runner.run() ? 0 : 1);
						}
					else if (Context.defined("js"))
						macro {
							var printBuf = new StringBuf();
							haxe.unit.TestRunner.print = printBuf.add;
							var runner = new haxe.unit.TestRunner();
							runner.add(new $clsName());
							var success = runner.run();
							js.Browser.window.console.log(printBuf.toString());
							if (js.phantomjs.PhantomTools.inPhantom())
								js.phantomjs.Phantom.exit(success ? 0 : 1);
						}
					else
						macro {
							var runner = new haxe.unit.TestRunner();
							runner.add(new $clsName());
							runner.run();
						},
				params: []
			}),
			pos: cls.pos,
			meta: []
		};
		fields.push(mainField);
		return fields;
	}
	#end
}
