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
		
		/*
			Add: static public function main
		*/
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
							
							var log = js.Browser.window.console.log;
							
							var runner = new haxe.unit.TestRunner();
							runner.add(new $clsName());
							var success = runner.run();
							var resultDetail = printBuf.toString();
							log(resultDetail);
							
							if (js.phantomjs.PhantomTools.inPhantom()) {
								js.phantomjs.Phantom.exit(success ? 0 : 1);
							} else {
								var resultDiv = js.Browser.document.createDivElement();
								resultDiv.id = "result";
								resultDiv.style.position = "absolute";
								resultDiv.style.zIndex = "5";
								resultDiv.style.backgroundColor = "rgba(255,255,255,0.75)";
								js.Browser.document.body.appendChild(resultDiv);
								
								var div = js.Browser.document.createDivElement();
								div.id = "detail";
								div.innerHTML = StringTools.replace(resultDetail, "\n", "<br>");
								resultDiv.appendChild(div);
								
								var div = js.Browser.document.createDivElement();
								div.id = "success";
								div.innerHTML = Std.string(success);
								resultDiv.appendChild(div);
								
								log("success:" + success);
							}
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
