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
   public var fontStyle(get, never):FontStyle;
   public var fontType(default, null):FontType;
   public static var useNative(get, set):Bool;
   
   private var knownFontStyle:FontStyle;

   private static var nmeRegisteredFonts = new Map<String,Font>();
   private static var nmeDeviceFonts: Array<Font>;

   public function new(inFilename:String = "", ?inStyle:FontStyle, ?inType:FontType, ?resourceName:String,?id:String ):Void 
   {
      knownFontStyle = inStyle;

      if (inFilename == "")
      {
         var fontClass = Type.getClass(this);
         var name = resourceName!=null ? resourceName :
                    Reflect.hasField(fontClass,"resourceName") ? Reflect.field(fontClass,"resourceName") :
                    null;
         if (name!=null)
         {
            fontName = id;
            var existing = nmeRegisteredFonts.get(fontName);
            if (existing!=null)
            {
               fontType = existing.fontType;
               knownFontStyle = existing.knownFontStyle;
            }
            else
            {
               fontType = FontType.EMBEDDED;
               var bytes = Assets.getResource(name);
               if (bytes!=null)
               {
                  registerFontData(this, bytes);
               }
               else
                  trace("Could not find font data for " + name);
            }
         }
         else
         {
            var className = Type.getClassName(Type.getClass(this));
            fontName = className.split(".").pop();
            knownFontStyle = FontStyle.REGULAR;
            fontType = FontType.EMBEDDED;
         }
      }
      else
      {
         fontName = inFilename;
         knownFontStyle = inStyle==null ? FontStyle.REGULAR : inStyle;
         fontType = inType==null ? FontType.EMBEDDED : inType;
      }
   }

   public function get_fontStyle():FontStyle
   {
      if (knownFontStyle==null)
      {
         knownFontStyle = FontStyle.REGULAR;

         var details:NativeFontData = freetype_import_font(fontName, null, 0, null);
         if (details!=null)
         {
            if (details.is_bold && details.is_italic)
            {
               knownFontStyle = FontStyle.BOLD_ITALIC;
            }
            else if (details.is_bold)
            {
               knownFontStyle = FontStyle.BOLD;
            }
            else if (details.is_italic)
            {
               knownFontStyle = FontStyle.ITALIC;
            }
        }
      }

      return knownFontStyle;
   }


   public function toString() : String
   {
      return "{ name=" + fontName + ", style=" + knownFontStyle + ", type=" + fontType + " }";
   }
   
   public static function enumerateFonts(enumerateDeviceFonts:Bool = false):Array<Font>
   {
      var result = new Array<Font>();
      for(key in nmeRegisteredFonts.keys())
         result.push( nmeRegisteredFonts.get(key) );

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
      var result = freetype_import_font(inFilename, null, 2048, null);
      return result;
   }
   
   public static function loadBytes(inBytes:ByteArray):NativeFontData 
   {
      var result = freetype_import_font("", null, 2048, inBytes);
      return result;
   }

 
   public static function registerFontData(instance:Font, inBytes:ByteArray)
   {
      if (nmeRegisteredFonts.exists(instance.fontName))
         return;

      nme_font_register_font(instance.fontName, inBytes);
      nmeRegisteredFonts.set(instance.fontName,instance);
   }

   
   public static function registerFont(font:Class<Font>)
   {
      var instance = Type.createInstance (font, [ "", null, null ]);
      if (instance != null)
      {
         if (nmeRegisteredFonts.exists(instance.fontName))
            return;

         if (Reflect.hasField(font, "resourceName"))
            nme_font_register_font(instance.fontName, ByteArray.fromBytes(Resource.getBytes(Reflect.field(font, "resourceName"))));

         nmeRegisteredFonts.set(instance.fontName, cast instance);
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
