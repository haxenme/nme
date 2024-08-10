class Main
{
   public static function main()
   {
      var args = nme.system.System.getArgs();
      if (args.length!=1)
      {
         Sys.println("Usage: Application name.jpg");
         Sys.println(" or  : nme cpp -args name.jpg");
         return;
      }

      var name = args[0];
      var bmp = nme.display.BitmapData.load(name);
      trace('Loaded $bmp');

      var bytes = nme.utils.ByteArray.readFile(name);
      trace("Found " + bytes.length + " bytes");

      trace("Timing...");
      var t0 = haxe.Timer.stamp();
      for(i in 0...100)
      {
         var bmp = nme.display.BitmapData.loadFromBytes(bytes);
         bmp.dispose();
      }
      var t1 = haxe.Timer.stamp();
      trace("Load time:" + (t1-t0)/100 + "s");

   }
}
