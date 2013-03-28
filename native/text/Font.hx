package native.text;
#if (cpp || neko)

import haxe.Resource;
import native.display.Stage;
import native.utils.ByteArray;
import native.Loader;

@:autoBuild(nme.Assets.embedFont())
class Font 
{
   public var fontName(default, null):String;
   public var fontStyle(default, null):FontStyle;
   public var fontType(default, null):FontType;
   
   private static var nmeRegisteredFonts = new Array<Font>();

   public function new(inFilename:String = ""):Void 
   {
      if (inFilename == "")
      {
         var className = Type.getClassName(Type.getClass(this));
         fontName = className.split(".").pop();
	  }
      else
      {
         fontName = inFilename;
      }
      //fontStyle = FontStyle.REGULAR;
      //fontType = FontType.DEVICE;
   }
   
   public static function enumerateFonts(enumerateDeviceFonts:Bool = false):Array<Font>
   {
      return nmeRegisteredFonts.copy();
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
   
   public static function registerFont(font:Class<Dynamic>)
   {
      var instance = cast (Type.createInstance (font, []), Font);
      if (instance != null)
      {
         if (Reflect.hasField(font, "resourceName"))
         {
            nme_font_register_font (instance.fontName, ByteArray.fromBytes (Resource.getBytes(Reflect.field(font, "resourceName"))));
         }
         nmeRegisteredFonts.push (instance);
      }
   }

   // Native Methods
   #if !iphone
   private static var freetype_import_font = Loader.load("freetype_import_font", 3);
   private static var nme_font_register_font = Loader.load("nme_font_register_font", 2);
   #end
}

typedef NativeFontData = 
{
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

typedef NativeGlyphData = 
{
   var char_code: Int;
   var advance: Int;
   var min_x: Int;
   var max_x: Int;
   var min_y: Int;
   var max_y: Int;
   var points: Array<Int>;
}

typedef NativeKerningData = 
{
   var left_glyph:Int;
   var right_glyph:Int;
   var x:Int;
   var y:Int;
}

#end