package neash.text;


import neash.display.Stage;
import neash.Loader;


class Font
{
	
	public var fontName(default, null):String;
	public var fontStyle(default, null):FontStyle;
	public var fontType(default, null):FontType;
	
	
	public function new(inFilename:String):Void
	{	
		fontName = inFilename;
		//fontStyle = FontStyle.REGULAR;
		//fontType = FontType.DEVICE;	
	}
	
	
	public static function load(inFilename:String):NativeFontData
	{
		#if !iphone
		var result = freetype_import_font(inFilename, null, 1024 * 20);
		return result;
		#else
		return null;
		#end
	}
	
	
	
	// Native Methods
	
	
	
	#if !iphone
	private static var freetype_import_font = Loader.load("freetype_import_font", 3);
	#end
	
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


typedef NativeGlyphData = {
	var char_code: Int;
	var advance: Int;
	var min_x: Int;
	var max_x: Int;
	var min_y: Int;
	var max_y: Int;
	var points: Array<Int>;
}


typedef NativeKerningData = {
	var left_glyph:Int;
	var right_glyph:Int;
	var x:Int;
	var y:Int;
}