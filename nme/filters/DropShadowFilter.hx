package nme.filters;
#if (cpp || neko)


class DropShadowFilter extends BitmapFilter
{
	
	private var alpha:Float;
	private var angle:Float;
	private var blurX:Float;
	private var blurY:Float;
	private var color:Int;
	private var distance:Float;
	private var hideObject:Bool;
	private var inner:Bool;
	private var knockout:Bool;
	private var quality:Int;
	private var strength:Float;
	
	
	public function new(in_distance:Float = 4.0, in_angle:Float = 45.0, in_color:Int = 0, in_alpha:Float = 1.0, in_blurX:Float = 4.0, in_blurY:Float = 4.0, in_strength:Float = 1.0, in_quality:Int = 1, in_inner:Bool = false, in_knockout:Bool = false, in_hideObject:Bool = false)
	{
		super("DropShadowFilter");
		
		distance = in_distance;
		angle = in_angle;
		color = in_color;
		alpha = in_alpha;
		blurX = in_blurX;
		blurY = in_blurY;
		strength = in_strength;
		quality = in_quality;
		inner = in_inner;
		knockout = in_knockout;
		hideObject = in_hideObject;
	}
	
	
	override public function clone():BitmapFilter
	{
		return new DropShadowFilter(distance, angle, color, alpha, blurX, blurY, strength, quality, inner, knockout, hideObject);
	}

}


#elseif js


import Html5Dom;


class DropShadowFilter extends BitmapFilter
{
	var distance : Float;
	var angle : Float;
	var color : Int;
	var alpha : Float;
	var blurX : Float;
	var blurY : Float;
	var quality : Int;
	var strength : Float;
	var inner : Bool;
	var knockout : Bool;
	var hideObject : Bool;

	public function new(in_distance:Float = 4.0, in_angle:Float = 45.0, in_color:Int = 0,
			in_alpha:Float = 1.0, in_blurX:Float = 4.0, in_blurY:Float = 4.0,
			in_strength:Float = 1.0, in_quality:Int = 1, in_inner:Bool = false,
			in_knockout:Bool = false, in_hideObject:Bool = false)
	{
		super("DropShadowFilter");

		distance = in_distance;
		angle = in_angle;
		color = in_color;
		alpha = in_alpha;
		blurX = in_blurX;
		blurY = in_blurX;
		strength = in_strength;
		quality = in_quality;
		inner = in_inner;
		knockout = in_knockout;
		hideObject = in_hideObject;
		jeashCached = false;
	}
	override public function clone() : BitmapFilter
	{
		return new DropShadowFilter(distance, angle, color, alpha, blurX, blurY,
				strength, quality, inner, knockout, hideObject );

	}

	static inline var DEGREES_FULL_RADIUS = 360.0;
	var jeashCached : Bool;
	override public function jeashApplyFilter(surface:HTMLCanvasElement)
	{
		if (jeashCached) return;
		var distanceX = distance*Math.sin(2*Math.PI*angle/DEGREES_FULL_RADIUS);
		var distanceY = distance*Math.cos(2*Math.PI*angle/DEGREES_FULL_RADIUS);
		var blurRadius = if (distanceY == 0) blurX;
		else if (distanceX == 0) blurY;
		else (blurX * (distanceX/distanceY)/(distanceX+distanceY) + blurY * (distanceY/distanceX)/(distanceX+distanceY))/2;
		flash.Lib.trace(distanceX);

		untyped
		{
			var ctx = surface.getContext('2d');
			ctx.shadowOffsetX = distanceX;
			ctx.shadowOffsetX = distanceX;
			ctx.shadowBlur = blurRadius;
			ctx.shadowColor = StringTools.hex(color);
		}
		//Lib.jeashSetSurfaceBoxShadow(surface, distanceX, distanceY, blurRadius, color, inner);  
		jeashCached = true;
	}

}


#else
typedef DropShadowFilter = flash.filters.DropShadowFilter;
#end