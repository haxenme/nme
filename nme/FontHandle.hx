package nme;
import Type;


typedef FontMetrics =
{
   var height:Int;
   var ascent:Int;
   var descent:Int;
   var max_x_advance:Int;
}

typedef GlyphMetrics =
{
   var min_x: Int;
   var max_x: Int;
   var width: Int;
   var height : Int;
   var x_advance: Int;
}


class FontHandle
{
   public var handle(get_handle,null):Dynamic;
   var mHandle:Dynamic;

   public function new(inName:String, inSize:Int)
   {
   #if neko
      mHandle = nme_create_font_handle(untyped inName.__s,inSize);
   #else
      mHandle = nme_create_font_handle(inName,inSize);
   #end
   }

   public function GetGlyphMetrics(inChar:Dynamic) : GlyphMetrics
   {
      var c : Int = Type.typeof(inChar) == ValueType.TInt ? inChar :
                            inChar.charCodeAt(0) ;
      return nme_get_glyph_metrics(mHandle,c);
   }

   public function GetFontMetrics() : FontMetrics
   {
      return nme_get_font_metrics(mHandle);
   }

   public function get_handle() : Dynamic { return mHandle; }


   static var nme_create_font_handle = nme.Loader.load("nme_create_font_handle",2);
   static var nme_get_font_metrics = nme.Loader.load("nme_get_font_metrics",1);
   static var nme_get_glyph_metrics = nme.Loader.load("nme_get_glyph_metrics",2);

}
