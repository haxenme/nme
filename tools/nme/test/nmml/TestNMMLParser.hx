package nmml;
import sys.io.Process;

class TestNMMLParser
{
    public function testAssetRenames() {
        var previous:String = Sys.getCwd();
        Sys.setCwd('test/nmml/renameExample');
        var process:Process = new Process('nme', ['test', 'neko']);
        var all:String = process.stdout.readAll().toString();
        if(all != '')
            Sys.println(all);
        var error:String = process.stderr.readAll().toString();
        if(error != '')
            Sys.println(error);
        Sys.setCwd(previous);
        assertTrue(process.exitCode() == 0, "process ok");
    }

    public function assertTrue(result:Bool, msg:String)
    {
       if (!result)
          trace("Test Failed:" + msg);
    }

    public function new()
    {
    }

    public function run()
    {
        testAssetRenames();
        trace("ok");
        return true;
    }
}
