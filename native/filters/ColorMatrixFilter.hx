package native.filters;
#if (cpp || neko)

class ColorMatrixFilter extends BitmapFilter 
{
   /** @private */ private var matrix:Array<Float>;
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

#end