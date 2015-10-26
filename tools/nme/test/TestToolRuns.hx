package;
import std.MockSys;
class TestToolRuns extends haxe.unit.TestCase
{
    var sys:MockSys;

    public function testRuns() {
        sys = new MockSys();
        CommandLineTools.sys = sys;
        CommandLineTools.main();
        assertTrue(true);
    }
}
