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
   public var handle(get_handle,null):Void;
   var mHandle:Void;

   public function new(inName:String, inSize:Int)
   {
      mHandle = nme_create_font_handle(untyped inName.__s,inSize);
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

   public function get_handle() : Void { return mHandle; }

/*
   public function RenderGlyph(inMatrix Matrix,inChar:Int)
   {
      ClosePolygon(false);

      inGFX.AddDrawable(nme_create_glyph_draw_obj(inX,inY,
             mHandle,inChar,
             mFillColour, mFillAlpha,
             untyped mSolidGradient==null? mBitmap : mSolidGradient,
             mCurrentLine ) );
   }
*/



   static var nme_create_glyph_draw_obj = neko.Lib.load("nme","nme_create_glyph_draw_obj",-1);

   static var nme_create_font_handle = neko.Lib.load("nme","nme_create_font_handle",2);
   static var nme_get_font_metrics = neko.Lib.load("nme","nme_get_font_metrics",1);
   static var nme_get_glyph_metrics = neko.Lib.load("nme","nme_get_glyph_metrics",2);

}
