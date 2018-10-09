package nme.ui;
#if (!flash)

import nme.Lib;

@:nativeProperty
class Mouse 
{
   public static function hide() 
   {
      if (Lib.stage != null)
         Lib.stage.showCursor(false);
   }

   public static function show() 
   {
      if (Lib.stage != null)
         Lib.stage.showCursor(true);
   }
}

#else
typedef Mouse = flash.ui.Mouse;
#end
