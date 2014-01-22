package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class MacPlatform extends Platform
{
   private var applicationDirectory:String;
   private var contentDirectory:String;
   private var executableDirectory:String;
   private var executablePath:String;
   private var targetDirectory:String;
   private var useNeko:Bool;

   public function new(inProject:NMEProject)
   {
      super(inProject);

      targetDirectory = project.app.path + "/mac/cpp";

      if (project.targetFlags.exists("neko") || project.target != PlatformHelper.hostPlatform) 
      {
         targetDirectory = project.app.path + "/mac/neko";
         useNeko = true;
      }

      applicationDirectory = targetDirectory + "/bin/" + project.app.file + ".app";
      contentDirectory = applicationDirectory + "/Contents/Resources";
      executableDirectory = applicationDirectory + "/Contents/MacOS";
      executablePath = executableDirectory + "/" + project.app.file;
   }

   override public function build():Void 
   {
      var hxml = targetDirectory + "/haxe/" + (project.debug ? "debug" : "release") + ".hxml";

      PathHelper.mkdir(targetDirectory);
      ProcessHelper.runCommand("", "haxe", [ hxml ]);

      if (useNeko) 
      {
         NekoHelper.createExecutable(project.templatePaths, "Mac", targetDirectory + "/obj/ApplicationMain.n", executablePath);
         NekoHelper.copyLibraries(project.templatePaths, "Mac", executableDirectory);
      }
      else
      {
         FileHelper.copyFile(targetDirectory + "/obj/ApplicationMain" + (project.debug ? "-debug" : ""), executablePath);
      }

      if (PlatformHelper.hostPlatform != Platform.WINDOWS) 
      {
         ProcessHelper.runCommand("", "chmod", [ "755", executablePath ]);
      }
   }

   override public function clean():Void 
   {
      if (FileSystem.exists(targetDirectory)) 
      {
         PathHelper.removeDirectory(targetDirectory);
      }
   }

   override public function display():Void 
   {
      var hxml = PathHelper.findTemplate(project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml/" + (project.debug ? "debug" : "release") + ".hxml");
      var template = new Template(File.getContent(hxml));
      Sys.println(template.execute(generateContext()));
   }

   override private function generateContext():Dynamic 
   {
      var context = project.templateContext;
      context.NEKO_FILE = targetDirectory + "/obj/ApplicationMain.n";
      context.CPP_DIR = targetDirectory + "/obj/";
      context.BUILD_DIR = project.app.path + "/mac";

      return context;
   }

   override public function run(arguments:Array<String>):Void 
   {
      if (project.target == PlatformHelper.hostPlatform) 
      {
         ProcessHelper.runCommand(executableDirectory, "./" + Path.withoutDirectory(executablePath), arguments);
      }
   }

   override public function update():Void 
   {
      if (project.targetFlags.exists("xml")) 
      {
         project.haxeflags.push("-xml " + targetDirectory + "/types.xml");
      }

      var context = generateContext();

      PathHelper.mkdir(targetDirectory);
      PathHelper.mkdir(targetDirectory + "/obj");
      PathHelper.mkdir(targetDirectory + "/haxe");
      PathHelper.mkdir(applicationDirectory);
      PathHelper.mkdir(contentDirectory);

      //SWFHelper.generateSWFClasses(project, targetDirectory + "/haxe");
      FileHelper.recursiveCopyTemplate(project.templatePaths, "haxe", targetDirectory + "/haxe", context);
      FileHelper.recursiveCopyTemplate(project.templatePaths, (useNeko ? "neko" : "cpp") + "/hxml", targetDirectory + "/haxe", context);
      FileHelper.copyFileTemplate(project.templatePaths, "mac/Info.plist", targetDirectory + "/bin/" + project.app.file + ".app/Contents/Info.plist", context);

      for(ndll in project.ndlls) 
      {
         FileHelper.copyLibrary(ndll, "Mac", "", (ndll.haxelib != null && ndll.haxelib.name == "hxcpp") ? ".dylib" : ".ndll", executableDirectory, project.debug);
      }

      context.HAS_ICON = IconHelper.createMacIcon(project.icons, PathHelper.combine(contentDirectory,"icon.icns"));

      for(asset in project.assets) 
      {
         if (asset.type != AssetType.TEMPLATE) 
         {
            PathHelper.mkdir(Path.directory(contentDirectory + "/" + asset.targetPath));
            FileHelper.copyAssetIfNewer(asset, contentDirectory + "/" + asset.targetPath);
         }
         else
         {
            PathHelper.mkdir(Path.directory(targetDirectory + "/" + asset.targetPath));
            FileHelper.copyAsset(asset, targetDirectory + "/" + asset.targetPath, context);
         }
      }
   }

}
