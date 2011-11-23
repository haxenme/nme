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


#else
typedef Mouse = flash.ui.Mouse;
#end