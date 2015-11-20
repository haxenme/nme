package helper;
import std.MockSys;
class CommandLineToolsHelper {

    public var sys:MockSys;

    public function new() {
        sys = new MockSys();
        CommandLineTools.sys = sys;
    }

    public function run():Void {
        CommandLineTools.main();
    }
}