package native.ui;
#if (cpp || neko)

import native.Lib;

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

#end