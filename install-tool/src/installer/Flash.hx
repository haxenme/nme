package installer;

import format.swf.Data;
import format.swf.Constants;
import format.mp3.Data;
import format.wav.Data;
import nme.text.Font;



class Flash extends Base
{
  override function update()
   {
      var dest = mBuildDir + "/flash/";
      var bin = dest + "bin";

      mkdir(dest);
      mkdir(dest+"/bin");

      cp_recurse(NME + "/install-tool/flash/hxml",dest + "haxe");
      cp_recurse(NME + "/install-tool/flash/template",dest + "haxe");

      // addAssets(bin,"flash");
   }


   override function build()
   {
      var dest = mBuildDir + "/flash/bin";
      var file = mDefines.get("APP_FILE") + ".swf";
      var input = neko.io.File.read(dest+"/"+file,true);
      var reader = new format.swf.Reader(input);
      var swf = reader.read();
      input.close();

      var new_tags = new Array<SWFTag>();
      var inserted = false;
      for(tag in swf.tags)
      {
         var name = Type.enumConstructor(tag);
         //trace(name);
         //if (name=="TSymbolClass") trace(tag);

         if (name=="TShowFrame" && !inserted && mAssets.length>0 )
         {
            new_tags.push(TShowFrame);
            for(asset in mAssets)
               if (asset.toSwf(new_tags) )
                  inserted = true;
         }
         new_tags.push(tag);
      }

      if (inserted)
      {
         swf.tags = new_tags;
         var output = neko.io.File.write(dest+"/"+file,true);
         var writer = new format.swf.Writer(output);
         writer.write(swf);
         output.close();
      }
   }

   override function test()
   {
      var dest = mBuildDir + "/flash/bin";

      var player = neko.Sys.getEnv("FLASH_PLAYER_EXE");
      if (player==null)
      {
         if (isMac())
           player = "/Applications/Flash Player Debugger.app/Contents/MacOS/Flash Player Debugger";
      }

      if (player==null || player=="")
         // Launch on windows
         run(dest, dotSlash() + mDefines.get("APP_FILE") + ".swf", [] );
      else
         run(dest, player, [ mDefines.get("APP_FILE") + ".swf" ] );
   }


}


