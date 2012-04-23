package neash.ui;


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