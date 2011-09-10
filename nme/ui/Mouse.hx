package nme.ui;


#if flash
@:native ("flash.ui.Mouse")
extern class Mouse {
	@:require(flash10) static var cursor : MouseCursor;
	@:require(flash10_1) static var supportsCursor(default,null) : Bool;
	static function hide() : Void;
	@:require(flash10_2) static function registerCursor(cursor : nme.display.MouseCursorData) : Void;
	static function show() : Void;
}
#else



class Mouse
{
   public static function show()
   {
      if (nme.Lib.stage!=null)
         nme.Lib.stage.showCursor(true);
   }
   public static function hide()
   {
      if (nme.Lib.stage!=null)
         nme.Lib.stage.showCursor(false);
   }
}
#end