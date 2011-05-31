package nme.text;

class NativeKerningData
{
   public function new() {}
   public var left_glyph: Int;
   public var right_glyph: Int;
   public var x: Int;
   public var y: Int;
}

class NativeGlyphData
{
   public function new(inCount:Int)
   {
      points = [];
      if (inCount>0)
        points[inCount-1] = 0;
   }
   public var char_code: Int;
   public var advance: Int;
   public var min_x: Int;
   public var max_x: Int;
   public var min_y: Int;
   public var max_y: Int;
   public var points: Array<Int>;
}


class Font
{
   var nmeHandle:Dynamic;

   public var is_fixed_width: Bool;
   public var has_glyph_names: Bool;
   public var is_italic: Bool;
   public var is_bold: Bool;
   public var num_glyphs: Int;
   public var family_name: String;
   public var style_name: String;
   public var em_size: Int;
   public var ascend: Int;
   public var descend: Int;
   public var height: Int;
   public var kerning_count: Int;
   public var glyph_count: Int;

   public var glyphs: Array<NativeGlyphData>;
   public var kerning: Array<NativeKerningData>;


   public function new(inFilename:String)
   {
      kerning = [];
      glyphs = [];
      kerning_count = 0;
      glyph_count = 0;
      nmeHandle = nme_font_create_handle(inFilename,this);
      if (nmeHandle==null)
         throw("Could not open font file:" + inFilename);

      for(i in 0...kerning_count)
      {
         kerning[i] = new NativeKerningData();
         nme_font_get_kerning_info(nmeHandle,i,kerning[i]);
      }

      for(i in 0...glyph_count)
      {
         var pts:Int = nme_font_get_glyph_point_count(nmeHandle,i);
         glyphs[i] = new NativeGlyphData(pts);
         nme_font_get_glyph_info(nmeHandle,i,glyphs[i]);
      }
   }

   static var nme_font_create_handle = nme.Loader.load("nme_font_create_handle",2);
   static var nme_font_get_kerning_info = nme.Loader.load("nme_font_get_kerning_info",3);
   static var nme_font_get_glyph_point_count = nme.Loader.load("nme_font_get_glyph_point_count",2);
   static var nme_font_get_glyph_info = nme.Loader.load("nme_font_get_glyph_info",3);

}




