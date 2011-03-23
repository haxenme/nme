import nme.Lib;
import nme.Timer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;


class Sample extends nme.display.Sprite
{
   public function new()
   {
      super();

          var ba:nme.utils.ByteArray = nme.utils.ByteArray.readFile("Data/README.txt");
          trace("length: " + ba.length);
          var dkdkd:String = ba.asString();
          trace("file contents: " + dkdkd);

          // modifying contents to check we can really overwrite the file
          ba.__set(0,65); // A
          ba.__set(1,66); // B
          ba.__set(2,67); // C
          
          trace("now writing as another file and re-reading");

          ba.writeFile("Data/README.txt");

          var ba2:nme.utils.ByteArray = nme.utils.ByteArray.readFile("Data/README.txt");
          trace("length: " + ba2.length);
          var dkdkd2:String = ba2.asString();
          trace("file contents: " + dkdkd2);

   }


   public static function main()
   {
      new Sample();
   }

}
