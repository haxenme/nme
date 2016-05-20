package nme.text;
#if (!flash)

import haxe.Resource;
import nme.display.Stage;
import nme.utils.ByteArray;
import nme.Loader;

@:nativeProperty
@:autoBuild(nme.macros.Embed.embedAsset("NME_font_",":font"))
class Font 
{
   public var fontName(default, null):String;
   public var fontStyle(default, null):FontStyle;
   public var fontType(default, null):FontType;
   public static var useNative(get, set):Bool;
   
   private static var nmeRegisteredFonts = new Array<Font>();
   private static var nmeDeviceFonts: Array<Font>;

   public function new(inFilename:String = "", ?inStyle:FontStyle, ?inType:FontType, ?resourceName:String ):Void 
   {
      if (inFilename == "")
      {
         var fontClass = Type.getClass(this);
         var name = resourceName!=null ? resourceName :
                    Reflect.hasField(fontClass,"resourceName") ? Reflect.field(fontClass,"resourceName") :
                    null;
         if (name!=null)
         {
            var bytes = ByteArray.fromBytes(Resource.getBytes(name));
            var details = loadBytes(bytes);
            fontName = details.family_name;
            if (details.is_bold && details.is_italic)
            {
               fontStyle = FontStyle.BOLD_ITALIC;
            }
            else if (details.is_bold)
            {
               fontStyle = FontStyle.BOLD;
            }
            else if (details.is_italic)
            {
               fontStyle = FontStyle.ITALIC;
            }
            else
            {
               fontStyle = FontStyle.REGULAR;
            }
            fontType = FontType.EMBEDDED;
            if (resourceName!=null)
               registerFontData(this, bytes);
         }
         else
         {
            var className = Type.getClassName(Type.getClass(this));
            fontName = className.split(".").pop();
            fontStyle = FontStyle.REGULAR;
            fontType = FontType.EMBEDDED;
         }
      }
      else
      {
         fontName = inFilename;
         fontStyle = inStyle==null ? FontStyle.REGULAR : inStyle;
         fontType = inType==null ? FontType.EMBEDDED : inType;
      }
   }

   public function toString() : String
   {
      return "{ name=" + fontName + ", style=" + fontStyle + ", type=" + fontType + " }";
   }
   
   public static function enumerateFonts(enumerateDeviceFonts:Bool = false):Array<Font>
   {
      var result = nmeRegisteredFonts.copy();
      if (enumerateDeviceFonts)
      {
         if (nmeDeviceFonts==null)
         {
            nmeDeviceFonts = new Array<Font>();
            var styles = [ FontStyle.BOLD, FontStyle.BOLD_ITALIC, FontStyle.ITALIC, FontStyle.REGULAR ];
            nme_font_iterate_device_fonts( function(name,style) nmeDeviceFonts.push(new Font(name,styles[style],FontType.DEVICE)) );
         }
         result = result.concat(nmeDeviceFonts);
         
      }
      return result;
   }

   public static function load(inFilename:String):NativeFontData 
   {
      var result = freetype_import_font(inFilename, null, 1024 * 20, null);
      return result;
   }
   
   public static function loadBytes(inBytes:ByteArray):NativeFontData 
   {
      var result = freetype_import_font("", null, 1024 * 20, inBytes);
      return result;
   }

 
   public static function registerFontData(instance:Font, inBytes:ByteArray)
   {
      nme_font_register_font(instance.fontName, inBytes);
      nmeRegisteredFonts.push(instance);
   }

   
   public static function registerFont(font:Class<Font>)
   {
      var instance = Type.createInstance (font, [ "", null, null ]);
      if (instance != null)
      {
         if (Reflect.hasField(font, "resourceName"))
            nme_font_register_font(instance.fontName, ByteArray.fromBytes (Resource.getBytes(Reflect.field(font, "resourceName"))));

         nmeRegisteredFonts.push(cast instance);
      }
   }

   #if (cpp||neko)
   static function get_useNative():Bool return nme_font_get_use_native();
   static function set_useNative(inVal:Bool):Bool return nme_font_set_use_native(inVal);

   // Native Methods
   private static var nme_font_set_use_native = Loader.load("nme_font_set_use_native", 1);
   private static var nme_font_get_use_native = Loader.load("nme_font_get_use_native", 0);
   #else
   static function get_useNative():Bool return false;
   static function set_useNative(inVal:Bool):Bool return false;
   #end
   private static var freetype_import_font = Loader.load("freetype_import_font", 4);
   private static var nme_font_register_font = Loader.load("nme_font_register_font", 2);
   private static var nme_font_iterate_device_fonts = Loader.load("nme_font_iterate_device_fonts", 1);
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

#else
typedef Font = flash.text.Font;
#end
