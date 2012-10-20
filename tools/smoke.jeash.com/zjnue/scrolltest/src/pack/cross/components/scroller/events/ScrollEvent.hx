package pack.cross.components.scroller.events;

import pack.cross.data.Rectangle;

import flash.events.Event;

class ScrollEvent extends Event
{
	public static inline var UPDATE : String = "UPDATE";
	
	var data : { total : Rectangle, thumb : Rectangle };
	
	public function new(data : { total : Rectangle, thumb : Rectangle })
	{
		super(UPDATE);
		
		this.data = data;
	}
	
	public function getData() : { total : Rectangle, thumb : Rectangle }
	{
		return data;
	}
	
	// TODO clone
}
