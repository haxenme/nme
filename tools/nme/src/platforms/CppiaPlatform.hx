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
   override public function getBinaryName()
   {
      var file = project.expandCppia() ?
            getOutputDir() + "/ScriptMain.cppia"  :
            getOutputDir() + "/" + getNmeFilename();
      return PathHelper.tryFullPath(file);
   }


   override public function copyBinary():Void 
   {
      if (project.expandCppia())
      {
         copyOutputTo(getOutputDir());
         outputFiles.push( "ScriptMain.cppia" );
      }
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

         addManifest();
      }
   }

   override public function updateAssets()
   {
      if (project.expandCppia())
         super.updateAssets();
   }

   override public function run(arguments:Array<String>):Void 
   {
      var fullPath = getBinaryName();
      CommandLineTools.runAcadnme([fullPath].concat(arguments), project);
   }



   override public function buildPackage()
   {
      if (!project.expandCppia())
      {
         createNmeFile();
      }
   }
}



