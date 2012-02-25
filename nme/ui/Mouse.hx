package nme.ui;
#if (cpp || neko)


class Mouse
{
	
	public static function hide()
	{
		if (nme.Lib.stage != null)
			nme.Lib.stage.showCursor(false);
	}
	
	
	public static function show()
	{
		if (nme.Lib.stage != null)
			nme.Lib.stage.showCursor(true);
	}
	
}


#elseif js

class Mouse
{
   public function new() { }

   public static function hide() { }
   public static function show() { }
}

#else
typedef Mouse = flash.ui.Mouse;
#end