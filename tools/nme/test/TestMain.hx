package;
import nmml.TestNMMLParser;
import haxe.Timer;
class TestMain {

	static function main(){
        try
        {
           var r = new TestNMMLParser();
           var t0 = Timer.stamp();
           var success = r.run();
           Sys.println(" Time : " + (Timer.stamp()-t0)*1000 );
           Sys.exit(success ? 0 : 1);
        }
        catch(e:Dynamic)
        {
           trace("Error:" + e);
           Sys.exit( 1);
        }
	}
}
