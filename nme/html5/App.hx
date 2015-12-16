package nme.html5;
import js.Browser;
import nme.app.Window;

class App
{
   public static function nme_set_package(inCompany:String, inFile:String, inPack:String, inVersion:String) 
   {
      trace("Thanks to : " + inCompany);
      Browser.document.title = inPack;
   }

   public static function nme_create_main_frame( inCallBack : Dynamic->Void )
   {
      var win = Browser.window;
      inCallBack(win);
   }

   public static function nme_get_frame_stage(win:js.html.Window)
   {
      return new DisplayObject(win.document.getElementById("stage"));
   }

   public static function nme_set_stage_handler(nmeHandle:js.html.Element, handler:Dynamic->Dynamic, inWidth:Int, inHeight:Int)
   {
      trace("Create handler " + inWidth + "x" + inHeight);
   }
}
