package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class CppiaPlatform extends Platform
{
   private var applicationDirectory:String;

   public function new(inProject:NMEProject)
   {
      super(inProject);

      applicationDirectory = getOutputDir();

      project.haxeflags.push('-cpp $haxeDir/ScriptMain.cppia');
   }

   public function restoreState()
   {
      project.haxeflags.remove('-cpp $haxeDir/ScriptMain.cppia');
   }

   override public function getPlatformDir() : String { return "cppia"; }
   override public function getBinName() : String { return null; }
   override public function getNativeDllExt() { return null; }
   override public function getLibExt() { return null; }
   override public function getHaxeTemplateDir() { return "script"; }
   override public function getAssetDir() { return getOutputDir()+"/assets"; }


   override public function copyBinary():Void 
   {
      if (project.expandCppia())
         copyOutputTo(getOutputDir());
      else
         project.localDefines.set("cppiaScript",haxeDir+"/ScriptMain.cppia");
   }

   public function copyOutputTo(destDir:String):Void 
   {
      PathHelper.mkdir(destDir);
      FileHelper.copyFile('$haxeDir/ScriptMain.cppia', '$destDir/ScriptMain.cppia');
      project.localDefines.set("cppiaScript",destDir+"/ScriptMain.cppia");
   }


   override public function runHaxe()
   {
      super.runHaxe();
   }

   public function getScriptName()
   {
      return haxeDir + "/ScriptMain.cppia";
   }

   override public function updateOutputDir():Void 
   {
      if (project.expandCppia())
      {
         super.updateOutputDir();

         var destination = getOutputDir();
         var icon = IconHelper.getSvgIcon(project.icons);
         if (icon!=null)
         {
            FileHelper.copyFile(icon, destination + "/icon.svg", addOutput);
         }
         else
            IconHelper.createIcon(project.icons, 128, 128, destination + "/icon.png", addOutput);
      }
   }

   override public function updateAssets()
   {
      if (project.expandCppia())
         super.updateAssets();
   }

   override public function run(arguments:Array<String>):Void 
   {
      var fullPath =  project.expandCppia() ? 
           FileSystem.fullPath( getOutputDir() + "/ScriptMain.cppia" ) :
           FileSystem.fullPath( getOutputDir() + "/" + getNmeFilename() );
      CommandLineTools.runAcadnme([fullPath].concat(arguments), project);
   }



   override public function buildPackage()
   {
      if (!project.expandCppia())
      {
         createNmeFile();
      }
   }

   /*
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

      var outfile = sys.io.File.write(filename,true);
      outfile.bigEndian = false;
      outfile.writeString("NME!");
      var header = haxe.Json.stringify( createManifestHeader(zipfileBytes, true) );
      outfile.writeInt32(header.length);
      outfile.writeInt32(zipfileBytes.length);
      outfile.writeString(header);
      outfile.writeBytes(zipfileBytes,0,zipfileBytes.length);
      outfile.close();

      Log.verbose("Wrote " + filename + " data=" + zipfileBytes.length);
   }

    override public function deploy(inAndRun:Bool):Bool {
        addManifest();
        return super.deploy(inAndRun);
    }
   */
}



