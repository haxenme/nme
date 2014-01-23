package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class AndroidView extends AndroidPlatform
{
   public function new(inProject:NMEProject)
   {
      super(inProject);
   }

   function getDest()     { return project.app.path + "/androidview/sdk"; }
   function getBuildDir() { return project.app.path + "/androidview/build"; }
   function getObjDir() { return project.app.path + "/androidview/obj"; }

   override public function build():Void 
   {
      var destination = getDest();

      var hxml = project.app.path + "/android/haxe/" + (project.debug ? "debug" : "release") + ".hxml";

      var arm5 = destination + "/libs/armeabi/libApplicationMain.so";

      ProcessHelper.runCommand("", "haxe", [ hxml ] );

      FileHelper.copyIfNewer( getObjDir() + "/libApplicationMain" + (project.debug ? "-debug" : "") + ".so", arm5);

      runBuild(getBuildDir());

      var jarName = project.app.file + "_sdk.jar";
      FileHelper.copyIfNewer( getBuildDir() + "/bin/classes.jar", destination +"/libs/" + jarName);
   }

   override public function clean():Void 
   {
      var targetPath = project.app.path + "/androidview";

      if (FileSystem.exists(targetPath)) 
      {
         PathHelper.removeDirectory(targetPath);
      }
   }

   override public function display():Void 
   {
      var hxml = PathHelper.findTemplate(project.templatePaths, "android/hxml/" + (project.debug ? "debug" : "release") + ".hxml");

      var context = project.templateContext;
      context.CPP_DIR = project.app.path + "/android/obj";

      var template = new Template(File.getContent(hxml));
      Sys.println(template.execute(context));
   }

   override public function install():Void { }

   override public function run(arguments:Array<String>):Void 
   {
   }

   override public function update():Void 
   {
      var destination = getDest();

      var context = project.templateContext;

      context.CPP_DIR = getObjDir();
      context.ANDROID_INSTALL_LOCATION = project.config.android.installLocation;

      context.ANDROIDVIEW = true;
      context.ANDROID_API_LEVEL = getApiLevel(11);

      var packageDirectory = project.app.packageName;

      var srcBuild =  getBuildDir();

      packageDirectory = srcBuild + "/src/" + packageDirectory.split(".").join("/");
      PathHelper.mkdir(packageDirectory);

      //SWFHelper.generateSWFClasses(project, project.app.path + "/android/haxe");
      for(ndll in project.ndlls) 
      {
         FileHelper.copyLibrary(ndll, "Android", "lib", ".so", destination + "/libs/armeabi", project.debug);
      }


      FileHelper.recursiveCopyTemplate(project.templatePaths, "android/template/src", srcBuild+"/src", context);
      FileHelper.copyFileTemplate(project.templatePaths, "android/template/build.xml", srcBuild+"/build.xml", context);
      FileHelper.copyFileTemplate(project.templatePaths, "android/template/AndroidManifest.xml", srcBuild+"/AndroidManifest.xml", context);
      FileHelper.copyFileTemplate(project.templatePaths, "android/template/default.properties", srcBuild+"/project.properties", context);

      FileHelper.recursiveCopyTemplate(project.templatePaths, "android-view/src", srcBuild+"/src");

      FileHelper.recursiveCopyTemplate(project.templatePaths, "haxe", project.app.path + "/android/haxe", context);
      FileHelper.recursiveCopyTemplate(project.templatePaths, "android/hxml", project.app.path + "/android/haxe", context);

      FileHelper.recursiveCopyTemplate(project.templatePaths, "android-view/sdk", getDest() );
   }
}
