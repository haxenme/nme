package nme.filters;
#if (cpp || neko)


class BlurFilter extends BitmapFilter
{
	
	private var blurX:Float;
	private var blurY:Float;
	private var quality:Int;
	
	
	public function new(inBlurX:Float = 4.0, inBlurY:Float = 4.0, inQuality:Int = 1)
	{
		super("BlurFilter");
		blurX = inBlurX;
		blurY = inBlurY;
		quality = inQuality;
	}
	
	
	override public function clone():BitmapFilter
	{
		return new BlurFilter(blurX, blurY, quality);
	}
	
}


#else
typedef BlurFilter = flash.filters.BlurFilter;
#end