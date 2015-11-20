package;
import helper.CommandLineToolsHelper;
class TestToolRuns extends haxe.unit.TestCase
{
    var clt:CommandLineToolsHelper;

    public function testRuns() {
        clt = new CommandLineToolsHelper();
        clt.run();
        assertTrue(true);
    }
}
