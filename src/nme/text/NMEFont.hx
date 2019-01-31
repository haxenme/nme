package nme.text;
#if (!flash)

import nme.display.BitmapData;

@:nativeProperty
class NMEFont 
{
   static var factories:Map<String,NMEFontFactory>;

   var height:Int;
   var ascent:Int;
   var descent:Int;
   var isRGB:Bool;

   public function new(inHeight:Int, inAscent:Int, inDescent:Int, inIsRGB:Bool) 
   {
      height = inHeight;
      ascent = inAscent;
      descent = inDescent;
      isRGB = inIsRGB;
   }

   static function createFont(inDef:NMEFontDef):NMEFont 
   {
      if (factories==null)
         return null;

      if (factories.exists(inDef.name))
         return factories.get(inDef.name)(inDef);

      return null;
   }

   // Implementation should override
   public function getGlyphInfo(inChar:Int):NMEGlyphInfo 
   {
      trace("getGlyphInfo - not implemented");
      return null;
   }

   static public function registerFont(inName:String, inFactory:NMEFontFactory) 
   {

      if (factories==null)
      {
         factories = new Map<String,NMEFontFactory>();
         var register = PrimeLoader.load("nme_font_set_factory", "ov");
         register(createFont);
      }

      factories.set(inName, inFactory);
   }

   // Implementation should override
   public function renderGlyph(inChar:Int) : BitmapData 
   {
      return new BitmapData(1, 1);
   }

   private function renderGlyphInternal(inChar:Int):Dynamic 
   {
      var result = renderGlyph(inChar);
      if (result != null)
         return result.nmeHandle;
      return null;
   }
}

typedef NMEFontDef = 
{
   name:String,
   height:Int,
   bold:Bool,
   italic:Bool,

};

typedef NMEFontFactory = NMEFontDef -> NMEFont;

typedef NMEGlyphInfo = 
{
   width:Int,
   height:Int,
   advance:Int,
   offsetX:Int,
   offsetY:Int,

};

#end
