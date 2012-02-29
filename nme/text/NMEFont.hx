package nme.text;

import nme.display.BitmapData;

typedef NMEFontDef =
{
  name:String,
  height:Int,
  bold:Bool,
  italic:Bool,
};

typedef NMEFontFactory = NMEFontDef->NMEFont;


typedef NMEGlyphInfo =
{
  width:Int,
  height:Int,
  advance:Int,
  offsetX:Int,
  offsetY:Int,
};

class NMEFont
{
   var height:Int;
   var ascent:Int;
   var descent:Int;
   var isRGB:Bool;
   static var factories = new Hash<NMEFontFactory>();

   public function new(inHeight:Int, inAscent:Int, inDescent:Int, inIsRGB:Bool)
   {
      height = inHeight;
      ascent = inAscent;
      descent = inDescent;
      isRGB = inIsRGB;
   }

   // Implementation should override
   public function getGlyphInfo(inChar:Int) : NMEGlyphInfo
   {
   trace("getGlyphInfo");
      return null;
   }


   // Implementation should override
   public function renderGlyph(inChar:Int) : BitmapData
   {
      return new BitmapData(1,1);
   }

   private function renderGlyphInternal(inChar:Int) : Dynamic
   {
      var result = renderGlyph(inChar);
      if (result!=null)
         return result.nmeHandle;
      return null;
   }

   static public function registerFont(inName:String,inFactory:NMEFontFactory)
   {
      factories.set(inName,inFactory);

      var register = Loader.load("nme_font_set_factory", 1);
      register(createFont);
   }

   static function createFont(inDef:NMEFontDef) : NMEFont
   {
     if (factories.exists(inDef.name))
        return factories.get(inDef.name)(inDef);
     return null;
   }
}

