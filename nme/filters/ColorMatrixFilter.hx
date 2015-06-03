package nme.filters;
#if (cpp || neko)

@:nativeProperty
class ColorMatrixFilter extends BitmapFilter 
{
   public var matrix:Array<Float>;
   public function new(inMatrix:Array<Float>) 
   {
      super("ColorMatrixFilter");
	  
      matrix = inMatrix;
   }

   override public function clone():BitmapFilter 
   {
      return new ColorMatrixFilter(matrix);
   }
}

#else
typedef ColorMatrixFilter = flash.filters.ColorMatrixFilter;
#end
