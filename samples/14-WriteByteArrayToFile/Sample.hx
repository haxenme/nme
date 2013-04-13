// Example for writing a ByteArray to file.
// Note thatyou can load a file from the App bundle - but you can't write to it.
// The workaround (behind the scenes) is that if you write a to a file, you write
// in the Documents directory, and when you read a file, nmeneko first looks in
// the Documents directory for "written" files, and then only if it couldn't find
// the file there it reads from the original App bundle file.
// Using the iPhone simulator, you can check the created files as per one of these
// links in http://is.gd/s6WB3x
// Also, you can reset the state of the filesystem in the simulator by doing
// iOS Simulator -> Reset Contents And Settings 

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
          // This should effectively completely overwrite the
          // original ByteArray
          ba.writeUTFBytes("MODIFIED FILE ///////////////////////");
          
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
