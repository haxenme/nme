package nme.image;

import nme.native.ImageBuffer;
import nme.display.BitmapData;


@:generic extern
abstract Image<PIXEL>(cpp.Pointer<ImageBuffer>)
{
   inline public function new(inSrc:cpp.Pointer<ImageBuffer>) this = inSrc;

   public var width(get,never):Int;
   public var height(get,never):Int;
   public var pixelFormat(get,never):Int;

   inline public function invalidate():Void this.value.Edit();

   inline public function get_width():Int return this.value.Width();
   inline public function get_height():Int return this.value.Height();
   inline public function get_pixelFormat():Int return this.value.Format();

   inline public static function fromBitmapData<PIXEL>(data:BitmapData) : Image<PIXEL>
       return new Image<PIXEL>( ImageBuffer.fromBitmapData(data) );

   @:arrayAccess public inline function row( index : Int ): cpp.Pointer<PIXEL> {
      return cpp.Pointer.fromRaw(this.ref.Row(index)).typeCast();
   }

}


