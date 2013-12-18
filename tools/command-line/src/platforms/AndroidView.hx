package platforms;

import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;

class AndroidView extends Platform
{
   var project : NMEProject;


   public function new() { super(); }

   function getDest()     { return project.app.path + "/androidview/sdk"; }
   function getBuildDir() { return project.app.path + "/androidview/build"; }
   function getObjDir() { return project.app.path + "/androidview/obj"; }

   override public function build(project:NMEProject):Void 
   {
      initialize(project);

      var destination = getDest();

      var hxml = project.app.path + "/android/haxe/" + (project.debug ? "debug" : "release") + ".hxml";

      var arm5 = destination + "/libs/armeabi/libApplicationMain.so";

      ProcessHelper.runCommand("", "haxe", [ hxml ] );

      FileHelper.copyIfNewer( getObjDir() + "/libApplicationMain" + (project.debug ? "-debug" : "") + ".so", arm5);

      AndroidHelper.build(project, getBuildDir());

      var jarName = project.app.file + "_sdk.jar";
      FileHelper.copyIfNewer( getBuildDir() + "/bin/classes.jar", destination +"/libs/" + jarName);
   }

   override public function clean(project:NMEProject):Void 
   {
      var targetPath = project.app.path + "/androidview";

      if (FileSystem.exists(targetPath)) 
      {
         PathHelper.removeDirectory(targetPath);
      }
   }

   override public function display(project:NMEProject):Void 
   {
      var hxml = PathHelper.findTemplate(project.templatePaths, "android/hxml/" + (project.debug ? "debug" : "release") + ".hxml");

      var context = project.templateContext;
      context.CPP_DIR = project.app.path + "/android/obj";

      var template = new Template(File.getContent(hxml));
      Sys.println(template.execute(context));
   }

   override public function install(project:NMEProject):Void { }

   override private function initialize(inProject:NMEProject):Void 
   {
      project = inProject;
      AndroidHelper.initialize(project);
   }

   override public function run(project:NMEProject, arguments:Array<String>):Void 
   {
      initialize(project);
   }

   override public function trace(project:NMEProject):Void 
   {
      initialize(project);
      AndroidHelper.trace(project, project.debug);
   }

   override public function uninstall(project:NMEProject):Void 
   {
      initialize(project);
      AndroidHelper.uninstall(project.meta.packageName);
   }

   override public function update(project:NMEProject):Void 
   {
      project = project.clone();

      initialize(project);

      var destination = getDest();

      var context = project.templateContext;

      context.CPP_DIR = getObjDir();
      context.ANDROID_INSTALL_LOCATION = project.config.android.installLocation;

      context.ANDROIDVIEW = true;
      context.ANDROID_API_LEVEL = AndroidHelper.getApiLevel(project,11);

      var packageDirectory = project.meta.packageName;

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
