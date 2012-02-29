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


#else
typedef DropShadowFilter = flash.filters.DropShadowFilter;
#end