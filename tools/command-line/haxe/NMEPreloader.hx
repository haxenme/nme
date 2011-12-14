import nme.display.Sprite;


class NMEPreloader extends Sprite
{
	
	public function new()
	{
		super();
	}
	
	
	public function getBackgroundColor():Int
	{
		return ::WIN_BACKGROUND::;
	}
	
	
	public function getHeight():Float
	{
		return ::WIN_HEIGHT::;
	}
	
	
	public function getWidth():Float
	{
		return ::WIN_WIDTH::;
	}
	
	
	public function onInit()
	{
		
	}
	
	
	public function onLoaded()
	{
		
	}

	
	public function onUpdate(bytesLoaded:Int, bytesTotal:Int)
	{
		var percentLoaded = bytesLoaded / bytesTotal;
		
		var padding = 3;
		
		var x = 30;
		var height = 9;
		
		var y = getHeight () / 2 - height / 2;
		var width = getWidth () - x * 2;
		
		var backgroundColor = getBackgroundColor ();
		
		var r = backgroundColor >> 16 & 0xFF;
		var g = backgroundColor >> 8  & 0xFF;
		var b = backgroundColor & 0xFF;
		
		var perceivedLuminosity = (0.299 * r + 0.587 * g + 0.114 * b);
		var color = 0x000000;
		
		if (perceivedLuminosity < 70) {
			
			color = 0xFFFFFF;
			
		}
		
		graphics.clear ();
		
		graphics.lineStyle (1, color, 0.15, true);
		graphics.drawRoundRect (x, y, width, height, padding * 2, padding * 2);
		graphics.endFill ();
		
		graphics.beginFill (color, 0.35);
		graphics.drawRect (x + padding, y + padding, width - padding * 2, height - padding * 2);
		graphics.endFill ();
	}

	
}