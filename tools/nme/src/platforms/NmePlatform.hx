package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class NmePlatform extends CppiaPlatform
{
   public function new(inProject:NMEProject)
   {
      super(inProject);
   }

   override public function createInstaller()
   {
      var dir = getOutputDir();
      var bytesOutput = new haxe.io.BytesOutput();
      var writer = new haxe.zip.Writer(bytesOutput);

      var entries:List<haxe.zip.Entry> = new List();
      for(file in outputFiles)
      {
         var src = dir + "/" + file;
         var bytes = sys.io.File.getBytes(src);
         // Add our text data entry:
         var entry =
           {
               fileName : file,
               fileSize : bytes.length,
               fileTime : Date.now(),
               compressed : false,
               dataSize : 0,
               data : bytes,
               crc32 : haxe.crypto.Crc32.make(bytes),
               extraFields : new List()
           };
         haxe.zip.Tools.compress(entry,5);
         entries.add(entry);
      }
      writer.write(entries);

      // Grab the zipped file from the output stream
      var zipfileBytes = bytesOutput.getBytes();
      // Save the zipped file to disc
      var filename = getOutputDir() + "/" + project.app.file + ".nme";
      var file = File.write(filename, true);
      file.write(zipfileBytes);
      file.close();

      Log.verbose("Wrote " + filename + " size=" + zipfileBytes.length);
   }

   /*
   override public function run(arguments:Array<String>):Void 
   {
      var fullPath =  FileSystem.fullPath('$applicationDirectory/ScriptMain.cppia');
      ProcessHelper.runCommand("", host, [fullPath].concat(arguments));
   }
   */
}



