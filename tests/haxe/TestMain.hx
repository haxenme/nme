package;
import haxe.Timer;
import nme.display.TestBitmapDataCopyChannel;
import nme.display.TestTilesheet;
import nme.StaticNme;


class TestMain {

	static function main()
   {
        //nme.display.BitmapData.defaultPremultiplied = false;

         var success = false;
         var t0 = Timer.stamp();
         try
         {
            new TestTilesheet();
            new TestBitmapDataCopyChannel();
            success = true;
         }
         catch(e:Dynamic)
         {
            trace("Error:" + e);
         }
        trace(" Time : " + (Timer.stamp()-t0)*1000 );
        Sys.exit(success ? 0 : 1);
	}
}
