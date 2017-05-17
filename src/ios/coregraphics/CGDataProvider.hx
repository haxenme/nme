package ios.coregraphics;

@:include("CoreGraphics/CoreGraphics.h")
@:native("cpp::Pointer<CGDataProvider>")
extern class CGDataProvider
{
   @:native("CGDataProviderCreateWithData")
   public static function createWithData<TI,TD>( info:cpp.RawPointer<TI>, data:cpp.RawConstPointer<TD>, size:Int, releaseData:CGDataProviderReleaseDataCallback):CGDataProvider;

   inline public static function createWithArray<T>( data:Array<T> ):CGDataProvider return ArrayData.create(data);

}

