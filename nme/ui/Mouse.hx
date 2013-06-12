package nme.ui;
#if (cpp || neko)

import nme.Lib;

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