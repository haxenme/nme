package;
import haxe.Timer;
import nme.display.TestBitmapDataCopyChannel;
import nme.display.TestTilesheet;
import nme.StaticNme;


class TestMain {

	static function main(){
        //nme.display.BitmapData.defaultPremultiplied = false;

        var r = new haxe.unit.TestRunner();
        r.add(new TestBitmapDataCopyChannel());
        r.add(new TestTilesheet());
        
        var t0 = Timer.stamp();
        var success = r.run();
        trace(" Time : " + (Timer.stamp()-t0)*1000 );
        Sys.exit(success ? 0 : 1);
	}
}
