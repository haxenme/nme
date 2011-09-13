package nme.text;
#if cpp || neko


import nme.display.Stage;


typedef NativeKerningData = {
   var left_glyph: Int;
   var right_glyph: Int;
   var x: Int;
   var y: Int;
}

typedef NativeGlyphData = {
   var char_code: Int;
   var advance: Int;
   var min_x: Int;
   var max_x: Int;
   var min_y: Int;
   var max_y: Int;
   var points: Array<Int>;
}

typedef NativeFontData = {
   var has_kerning: Bool;
   var is_fixed_width: Bool;
   var has_glyph_names: Bool;
   var is_italic: Bool;
   var is_bold: Bool;
   var num_glyphs: Int;
   var family_name: String;
   var style_name: String;
   var em_size: Int;
   var ascend: Int;
   var descend: Int;
   var height: Int;
   var glyphs: Array<NativeGlyphData>;
   var kerning: Array<NativeKerningData>;
}


class Font
{
	
	var fontName(default,null) : String;
	var fontStyle(default,null) : FontStyle;
	var fontType(default, null) : FontType;
	
	public function new(inFilename:String):Void {
		
		fontName = inFilename;
		fontStyle = FontStyle.REGULAR;
		fontType = FontType.DEVICE;
		
	}
	
   public static function load(inFilename:String) : NativeFontData
   {
       var result = freetype_import_font(inFilename,null,1024*20);
       return result;
   }

   static var freetype_import_font = nme.Loader.load("freetype_import_font",3);

}


#else
typedef Font = flash.text.Font;
#end