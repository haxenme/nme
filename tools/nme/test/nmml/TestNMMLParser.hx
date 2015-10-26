package nmml;
import sys.io.Process;
class TestNMMLParser extends haxe.unit.TestCase
{
    public function testAssetRenames() {
        var previous:String = Sys.getCwd();
        Sys.setCwd('test/nmml/renameExample');
        var process:Process = new Process('nme', ['test']);
        Sys.setCwd(previous);
        assertTrue(process.exitCode() == 0);
    }
}
