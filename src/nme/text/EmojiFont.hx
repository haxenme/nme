package nme.text;

class EmojiFont
{
   static public function getDefaultFontFile() : String
   {
      #if windows
      return "seguiemj.ttf";
      #elseif mac
      return null;
      #elseif linux
      return null;
      #elseif ios
      return null;
      #elseif android
      return null;
      #end

      return null;
   }

   static public function register(fontFile:String=null) : Bool
   {
      if (fontFile==null)
         fontFile = getDefaultFontFile();

      if (fontFile==null)
         return false;

      TextField.addSpecialCharFont( fontFile, [
            0x2300, 0x2400,   // Misc Technical (⌚⏰⌨️)
            0x2600, 0x2700,   // Misc Symbols (☀️⚡☔♻️)
            0x2700, 0x27C0,   // Dingbats (✂️✈️✉️✔️)
            0x2B50, 0x2B56,   // Stars (⭐⭕)
            0xFE00, 0xFE10,   // Variation Selectors - used for emoji modifiers (skin tones, etc) ignore
            0x1F300, 0x1F600, // Misc Symbols & Pictographs (🌀🌈🍎🎂🏀)
            0x1F600, 0x1F650, // Emoticons (😀😂🙂)
            0x1F680, 0x1F700, // Transport & Map (🚀🚗🛒)
            0x1F900, 0x1FA00, // Supplemental Symbols (🤔🤖🥳🦄)
            0x1FA00, 0x1FB00, // Symbols Extended-A (🩷🪐🫠)
         ] );

      return true;
   }
}
