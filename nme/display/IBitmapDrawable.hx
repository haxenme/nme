package nme.display;


#if flash
@:native ("flash.display.IBitmapDrawable")
extern interface IBitmapDrawable {
}
#else



interface IBitmapDrawable
{
   public function nmeDrawToSurface(inSurface : Dynamic,
               matrix:nme.geom.Matrix,
               colorTransform:nme.geom.ColorTransform,
               blendMode:String,
               clipRect:nme.geom.Rectangle,
               smoothing:Bool):Void;
}
#end