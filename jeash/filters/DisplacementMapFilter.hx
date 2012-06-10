package jeash.filters;

import jeash.Html5Dom;

class DisplacementMapFilter extends BitmapFilter {
	public var alpha : Float;
	public var color : UInt;
	public var componentX : UInt;
	public var componentY : UInt;
	public var mapBitmap : jeash.display.BitmapData;
	public var mapPoint : jeash.geom.Point;
	public var mode : DisplacementMapFilterMode;
	public var scaleX : Float;
	public var scaleY : Float;
	public function new(?mapBitmap : jeash.display.BitmapData, ?mapPoint : jeash.geom.Point, ?componentX : UInt, ?componentY : UInt, ?scaleX : Float, ?scaleY : Float, ?mode : DisplacementMapFilterMode, ?color : UInt, ?alpha : Float) 
	{
		super("DisplacementMapFilter");
		this.mapBitmap = mapBitmap;
		this.mapPoint = mapPoint;
		this.componentY = componentY;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
		this.mode = mode;
		this.color = color;
		this.alpha = alpha;
	}
}

