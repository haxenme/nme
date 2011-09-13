package nme.display;
#if cpp || neko


interface IBitmapDrawable
{
   public function nmeDrawToSurface(inSurface : Dynamic,
               matrix:nme.geom.Matrix,
               colorTransform:nme.geom.ColorTransform,
               blendMode:String,
               clipRect:nme.geom.Rectangle,
               smoothing:Bool):Void;
}


#else
typedef IBitmapDrawable = flash.display.IBitmapDrawable;
#end