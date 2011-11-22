package nme.display;


import nme.text.TextField;
import nme.events.Event;
import haxe.Timer;


class FPS extends TextField
{
	
	private var times:Array<Float>;
	
	
	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{	
		super();
		
		x = inX;
		y = inY;
		selectable = false;
		text = "FPS:";
		textColor = inCol;
		times = [];
		
		addEventListener(Event.ENTER_FRAME, onEnter);
	}
	
	
	
	// Event Handlers
	
	
	
	public function onEnter(_)
	{	
		var now = Timer.stamp();
		times.push(now);
		
		while (times[0] < now - 1)
			times.shift();
		
		if (visible)
		{	
			text = "FPS:" + times.length;	
		}
	}
	
}