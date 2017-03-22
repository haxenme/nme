package ios.coregraphics;
using cpp.NativeArray;

class ArrayData
{
   public static function create<T>( array:Array<T> ) : CGDataProvider
   {
      var base = array.getBase();
      var size = base.getByteCount();
      var data:cpp.Pointer<cpp.Void> = cpp.Stdlib.malloc( size );
      cpp.Stdlib.memcpy( data, cpp.Pointer.fromRaw( base.getBase() ), size );
      return CGDataProvider.createWithData( data.raw, data.raw, size, cpp.Function.fromStaticFunction( freeData ) );
   }

   static function freeData(freeable:cpp.RawPointer<cpp.Void>, data:cpp.RawConstPointer<cpp.Void>, size:cpp.SizeT ) : Void
   {
      cpp.Stdlib.nativeFree(freeable);
   }
}


