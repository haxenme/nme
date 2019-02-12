package;

import haxe.io.Path;
import sys.FileSystem;
import platforms.Platform;
import nme.AlphaMode;

typedef IntMap<T> = Map<Int, T>;

class AndroidConfig
{
   public var installLocation:String;
   public var minApiLevel:Int;
   public var addV4Compat:Bool;
   public var targetApiLevel:Null<Int>;
   public var buildApiLevel:Null<Int>;
   public var appHeader:Array<String>;
   public var appIntent:Array<String>;
   public var appActivity:Array<String>;
   public var appPermission:Array<AndroidPermission>;
   public var appFeature:Array<AndroidFeature>;
   // Where to put source code when genrating a package
   public var viewPackageName:String;
   public var viewTestDir:String;
   public var gameActivityBase:String;
   public var gameActivityViewBase:String;
   public var extensions:Map<String,Bool>;

   public function new()
   {
      installLocation = "preferExternal";
      minApiLevel = 14;
      addV4Compat = true;
      appHeader = [];
      appIntent = [];
      appActivity = [];
      appPermission = [];
      appFeature = [];
      viewPackageName = "com.nmehost";
      viewTestDir = "";
      gameActivityBase = "Activity";
      gameActivityViewBase = "android.app.Fragment";
      extensions = new Map<String,Bool>();
   }
}

class WinRTConfig
{
   public var isAppx:Bool;
   public var isXbox:Bool;
   public var appCapability:Array<WinrtCapability>;
   public var packageDependency:Array<WinrtPackageDependency>;

   public function new()
   {
      appCapability = [];
      packageDependency = [];
   }
}

class Engine
{
   public function new(inName:String, inVersion:String)
   {
      name = inName;
      version = inVersion;
   }
   public var name:String;
   public var version:String;
}

class IOSConfig
{
   inline public static var IPHONE     = 0x01;
   inline public static var IPAD       = 0x02;
   inline public static var UNIVERSAL  = 0x03;

   public var compiler:String;
   public var deployment:String;
   public var deviceConfig:Int;
   public var linkerFlags:Array<String>;
   public var prerenderedIcon:Bool;
   public var viewTestDir:String;
   public var sourceFlavour:String;

   public function new()
   {
      compiler =  "clang";
      deployment =  "8.0";
      deviceConfig =  UNIVERSAL;
      linkerFlags =  new Array();
      viewTestDir =  "";
      prerenderedIcon =  false;
      sourceFlavour = "cpp";
   }
}

class FileAssociation
{
   public var extension:String;
   public var description:String;

   public function new(inExtension:String, inDescription:String)
   {
      extension = inExtension;
      description = inDescription;
   }
}



class NMEProject 
{
   public var app:ApplicationData;
   public var window:Window;
   public var architectures:Array<Architecture>;
   public var assets:Array<Asset>;
   public var ndlls:Array<NDLL>;
   public var icons:Array<Icon>;
   public var banners:Array<Icon>;
   public var fileAssociations:Array<FileAssociation>;
   public var splashScreens:Array<SplashScreen>;
   public var optionalStaticLink:Bool;
   public var staticLink:Bool;
   public var stdLibs:Bool;
   public var relocationDir:String;
   public var engines:Map<String, String>;
   public var export:String;
   public var exportFilter:String;
   public var exportSourceDir:String;
   public var projectFilename:String;

   // ios/android build parameters
   public var iosConfig:IOSConfig;
   public var androidConfig:AndroidConfig;
   public var winrtConfig:WinRTConfig;
   public var watchProject:NMEProject;

   // Defines
   public var localDefines:Map<String,String>;
   public var environment:Map<String,String>;
   public var targetFlags:Map<String,String>;

   // For building haxe command line
   public var haxedefs:Map<String, String>;
   public var haxeflags:Array<String>;
   public var haxelibs:Array<Haxelib>;
   public var classPaths:Array<String>;
   public var macros:Array<String>;

   // For <include> elements
   public var includePaths:Array<String>;
   // For bulding projects
   public var templatePaths:Array<String>;
   public var templateCopies:Array<TemplateCopy>;

   // Currently for adding frameworks to ios project, or android library projects
   public var dependencies:Map<String,Dependency>;
   public var otherLinkerFlags:Array<String>;
   public var customIOSproperties:Map<String,String>;
   public var frameworkSearchPaths:Array<String>;
   public var customIOSBlock:Array<String>;
   // For decoding assets
   public var libraryHandlers:Map<String,String>;
   // Additional files to be copied into andoird project
   public var javaPaths:Array<String>;
   // Android signing certificate
   public var certificate:Keystore;

   // Flags
   public var embedAssets:Bool;
   public var openflCompat:Bool;
   public var debug:Bool;
   public var megaTrace:Bool;
   public var isFlash:Bool;
   public var isRawJs:Bool;

   // Exported into project for use in project files
   public var platformType:String;
   public var ndllCheckDir:String;
   public var command:String;
   public var target:String;
   public var targetName:String;

   private var baseTemplateContext:Dynamic;



   public function new() 
   {
      baseTemplateContext = {};
      embedAssets = false;
      openflCompat = true;
      iosConfig = new IOSConfig();
      androidConfig = new AndroidConfig();
      winrtConfig = new WinRTConfig();

      debug = false;
      megaTrace = false;
      target = "";
      relocationDir = "";
      targetFlags = new Map<String,String>();
      templatePaths = [];
      templateCopies = [];
      fileAssociations = [];
      ndllCheckDir = "";
      engines = new Map<String,String>();
      libraryHandlers = new Map<String,String>();

      environment = Sys.environment();
      if (environment.exists("ANDROID_SERIAL"))
         targetFlags.set("device", environment.get("ANDROID_SERIAL"));
      localDefines = new Map<String,String>();
      for(key in environment.keys())
         Reflect.setField(baseTemplateContext, key, environment.get(key));

      app = new ApplicationData();
      window = new Window();


      assets = new Array<Asset>();
      dependencies = new Map<String,Dependency>();
      otherLinkerFlags = [];
      customIOSproperties = new Map<String, String>();
      customIOSBlock = [];
      frameworkSearchPaths = [];
      haxedefs = new Map<String,String>();
      haxeflags = new Array<String>();
      macros = new Array<String>();
      haxelibs = new Array<Haxelib>();
      icons = new Array<Icon>();
      banners = new Array<Icon>();
      javaPaths = new Array<String>();
      includePaths = new Array<String>();
      ndlls = new Array<NDLL>();
      classPaths = new Array<String>();
      splashScreens = new Array<SplashScreen>();
      architectures = [];
      staticLink = false;
      stdLibs = true;
      optionalStaticLink = true;
      isFlash = false;
      exportFilter = "^(class|enum|interface)";
   }

   public function setDebug(inDebug:Bool)
   {
      debug = inDebug;
      if (debug)
         localDefines.set("debug", "1");
      else if (localDefines.exists("debug"))
         localDefines.remove("debug");
   }

   public function setCommand(inCommand:String)
   {
      command = inCommand;
      if (command != null) 
         localDefines.set(command.toLowerCase(), "1");
   }

   public function setBinDir(inDir:String)
   {
      app.binDir = inDir;
   }


   public function setTarget(inTargetName:String)
   {
      targetName = inTargetName;
      switch(inTargetName) 
      {
         case "cpp":
            target = PlatformHelper.hostPlatform;
            targetFlags.set("cpp", "");

         case "cppia":
            target = Platform.CPPIA;
            targetFlags.set("cpp", "");
            targetFlags.set("cppia", "");
            haxedefs.set("cppia","");
            var cp = getDef("CPPIA_CLASSPATH");
            if (cp!=null)
               classPaths.push(cp);
            macros.push("--macro cpp.cppia.HostClasses.include()");

         case "emscripten":
            target = Platform.EMSCRIPTEN;
            targetFlags.set("emscripten", "");
            staticLink = true;
            haxedefs.set("emscripten","1");

         case "neko":
            target = PlatformHelper.hostPlatform;
            staticLink = false;
            optionalStaticLink = false;
            targetFlags.set("neko", "");

         case "ios":
            target = Platform.IOS;
            haxedefs.set("iphone", "1");
            targetFlags.set("iphoneos", "");

         case "iphone", "iphoneos":
            target = Platform.IOS;
            haxedefs.set("iphone", "1");
            targetFlags.set("iphoneos", "");

         case "iosview", "ios-view":
            targetFlags.set("ios", "");
            targetFlags.set("iosview", "");
            targetFlags.set("nativeview", "");
            haxedefs.set("nativeview","1");
            haxedefs.set("iosview","1");
            haxedefs.set("iphone", "1");
            target = Platform.IOSVIEW;

         case "androidview", "android-view":
            targetFlags.set("android", "");
            targetFlags.set("androidview", "");
            targetFlags.set("nativeview", "");
            haxedefs.set("nativeview","1");
            haxedefs.set("androidview","1");
            androidConfig.gameActivityBase = "android.app.Fragment";
            target = Platform.ANDROIDVIEW;

         case "iphonesim":
            target = Platform.IOS;
            haxedefs.set("iphone", "1");
            targetFlags.set("simulator", "");

         case "watchos":
            targetFlags.set("watchos", "");
            haxedefs.set("objc","1");
            target = Platform.WATCH;

         case "watchsimulator":
            targetFlags.set("watchos", "");
            targetFlags.set("watchsimulator", "");
            haxedefs.set("objc","1");
            target = Platform.WATCH;

         case "android":
            target = Platform.ANDROID;
            targetFlags.set("android", "");

         case "androidsim":
            target = Platform.ANDROID;
            targetFlags.set("android", "");
            targetFlags.set("androidsim", "");

         case "flash":
            target = inTargetName.toUpperCase();

         case "html5","jsprime":
            target = Platform.JSPRIME;
            haxedefs.set("js-unflatten", "");

         case "js":
            target = Platform.JS;

         case "winrt","uwp":
            targetFlags.set("cpp", "1");
            haxedefs.set("winrt", "");
            haxedefs.set("NME_ANGLE", "");
            //haxedefs.set("static_link", "");
            haxedefs.set("ABI", "-ZW");
            target = Platform.WINRT;
            winrtConfig.isXbox = haxedefs.exists("xbox");
            winrtConfig.isAppx = haxedefs.exists("appx");
            if(winrtConfig.isXbox)
            {
                haxedefs.set("HXCPP_M64", null);
                winrtConfig.isAppx = true;
            }

         case "rpi":
            targetFlags.set("cpp", "1");
            targetFlags.set("linux", "1");
            targetFlags.set("rpi", "1");
            if (PlatformHelper.hostPlatform==Platform.WINDOWS)
               addHaxelib("winrpi",null);
            target = inTargetName.toUpperCase();

         case "windows", "mac", "linux":
            targetFlags.set("cpp", "1");
            target = inTargetName.toUpperCase();

         default:
            Log.error("Unknown target : " + inTargetName);
      }

      if (target==Platform.ANDROID || target==Platform.ANDROIDVIEW)
         ndllCheckDir = "/Android";
      else if (target==Platform.IOSVIEW || target==Platform.IOS)
         ndllCheckDir = "/iPhone";

      targetFlags.set("target_" + target.toString().toLowerCase() , "");
      if (target==Platform.JSPRIME)
         targetFlags.set("target_html5","");

      if (target==Platform.IOS || target==Platform.IOSVIEW || target==Platform.ANDROIDVIEW || target==Platform.WATCH || target==Platform.WINRT)
      {
         optionalStaticLink = false;
         staticLink = true;
      }

      isFlash =  target==Platform.FLASH;
      isRawJs =  target==Platform.JS;
      if (!isFlash && !isRawJs)
      {
          haxeflags.push("--remap flash:nme");
          haxeflags.push("--remap lime:nme");
      }



      switch(target) 
      {
         case Platform.FLASH:
            platformType = Platform.TYPE_WEB;
            embedAssets = true;

         case Platform.CPPIA:
            platformType = Platform.TYPE_SCRIPT;
            embedAssets = false;

         case Platform.JS:
            platformType = Platform.TYPE_WEB;
            embedAssets = false;

         case Platform.EMSCRIPTEN:
            platformType = Platform.TYPE_WEB;
            embedAssets = true;

         case Platform.JSPRIME, Platform.HTML5:
            platformType = Platform.TYPE_WEB;
            embedAssets = false;

         case Platform.ANDROID, Platform.IOS,
              Platform.IOSVIEW, Platform.ANDROIDVIEW:

            platformType = Platform.TYPE_MOBILE;

            if (target==Platform.IOSVIEW || target==Platform.ANDROIDVIEW) 
               embedAssets = true;

            window.width = 0;
            window.height = 0;
            window.fullscreen = true;


         case Platform.WATCH:
            platformType = Platform.TYPE_MOBILE;
            window.width = 0;
            window.height = 0;
            window.fullscreen = true;

         case Platform.RPI:
            platformType = Platform.TYPE_DESKTOP;
            window.singleInstance = false;

         case Platform.WINDOWS, Platform.MAC, Platform.LINUX, Platform.WINRT:

            platformType = Platform.TYPE_DESKTOP;

            if (architectures.length==0)
            {
               if (isNeko())
               {
                  if (target==Platform.LINUX && hasDef("HXCPP_LINUX_ARMV7"))
                     architectures = [ Architecture.ARMV7 ];
                  else if (target==Platform.LINUX && hasDef("HXCPP_LINUX_ARM64"))
                     architectures = [ Architecture.ARM64 ];
                  else
                     architectures = [ PlatformHelper.hostArchitecture ];
               }
               else
                  architectures = [ Architecture.X64 ];
            }
            window.singleInstance = false;

         default:
            Log.error("Unknown platform target : " + inTargetName);
      }

      switch(platformType) 
      {
         case Platform.TYPE_MOBILE:
            localDefines.set("mobile", "1");
         case Platform.TYPE_DESKTOP:
            localDefines.set("desktop", "1");
         case Platform.TYPE_WEB:
            localDefines.set("web", "1");
         case Platform.TYPE_SCRIPT:
            localDefines.set("script", "1");
      }

      Log.verbose("Platform type: " + platformType);


      for(key in targetFlags.keys())
         localDefines.set(key,targetFlags.get(key));

      localDefines.set("haxe3", "1");

      localDefines.set(target.toLowerCase(), "1");
      if (target==Platform.JSPRIME)
      {
         localDefines.set("html5","1");
         haxedefs.set("html5","1");
      }
   }

   public function setProjectFilename(inFilename:String)
   {
      projectFilename = inFilename;
   }

   public function makeWatchOSConfig()
   {
      if (watchProject==null)
      {
         watchProject = new NMEProject();
         watchProject.setTarget(targetName);
         watchProject.templatePaths.push( CommandLineTools.nme + "/templates/watchos" );
      }
      return watchProject;
   }

   public function expandCppia()
   {
      return hasDef("expand");
   }

   public function getInt(inName:String,inDefault:Int):Int
   {
      if (!hasDef(inName))
         return inDefault;

      var value = getDef(inName);
      return Std.parseInt(value);
   }

   public function getBool(inName:String,inDefault:Bool):Bool
   {
      if (!hasDef(inName))
         return inDefault;

      var value = getDef(inName);
      if (value=="t" || value=="true" || value=="1")
         return true;
      if (value=="f" || value=="false" || value=="0")
         return false;
      Log.error('Bad boolean value for $inName, "$value"');

      return inDefault;
   }

   public function hasDef(inName:String)
   {
      return localDefines.exists(inName) || environment.exists(inName) || haxedefs.exists(inName);
   }

   public function getDef(inName:String):String
   {
      if (localDefines.exists(inName))
         return localDefines.get(inName);
      if (environment.exists(inName))
         return environment.get(inName);
      return haxedefs.get(inName);
   }

   public function checkRelocation(inDir:String)
   {
      var file =  inDir+"/relocation.dir";
      try {
         var content = sys.io.File.getContent(file);
         if (content!="")
         {
            relocationDir = content.split("\n")[0];
            Log.verbose("Using relocation directory: " + relocationDir);
         }
      }
      catch(e:Dynamic) { }
   }

   public function relocatePath(inPath:String):String
   {
      if (relocationDir!="" && inPath.substr(0,2)=="..")
      {
         var test = PathHelper.normalise(relocationDir + "/" + inPath);
         if (FileSystem.exists(test))
         {
            Log.verbose("Relocated " + inPath + " to " + test);
            return test;
         }
      }
      return inPath;
   }

   public function addClassPath(inPath:String)
   {
      ArrayHelper.addUnique(classPaths, inPath);
   }

   public function addArch(arch:Architecture)
   {
      ArrayHelper.addUnique(architectures, arch);
   }

   public function addFileAssociation(extension:String, description:String)
   {
      fileAssociations.push( new FileAssociation(extension,description) );
   }

   public function hasTargetFlag(inFlag:String)
   {
      return targetFlags.exists(inFlag);
   }

   public function isNeko() { return hasTargetFlag("neko"); }

   public function include(path:String):Void 
   {
      // extend project file somehow?
   }

   public function findNdll(inName:String) : NDLL
   {
      //return Lambda.find(ndlls,function(n) return n.name==inName);
      for(ndll in ndlls)
         if (ndll.name==inName)
            return ndll;
      return null;
   }

   public function findHaxelib(inName:String) : Haxelib
   {
      //return Lambda.find(haxelibs,function(h) return h.name==inName);
      for(haxelib in haxelibs)
         if (haxelib.name==inName)
             return haxelib;
      return null;
   }


   function addHaxelib(inName:String, inVersion:String) : Haxelib
   {
      //return Lambda.find(haxelibs,function(h) return h.name==inName);
      for(haxelib in haxelibs)
         if (haxelib.name==inName)
             return haxelib;
      var haxelib = new Haxelib(inName,inVersion);
      haxelibs.push(haxelib);
      return haxelib;
   }



   public function raiseLib(inName:String)
   {
      for(i in 0...haxelibs.length)
         if (haxelibs[i].name==inName)
         {
             var lib =  haxelibs.splice(i,1);
             haxelibs = haxelibs.concat(lib);
             return;
         }
   }

   public function isStaticNme()
   {
      if (hasDef("rpi"))
         haxedefs.set("nme_static","1");

      if (hasDef("nme_static") || hasDef("iphone") || hasDef("ios") ||hasDef("watchos") )
         return true;
      if (hasDef("nme_dynamic"))
         return false;

      var isAndroidSo =  false;//hasDef("android") && !hasDef("androidsim") && !hasDef("androidview");
      if ( hasDef("windows") || hasDef("mac") || hasDef("linux") || isAndroidSo)
      {
         // Use dynamic libraries by default on desktop
         return false;
      }

      haxedefs.set("nme_static","1");
      return true;
   }

   public function addNdll(name:String, base:String, inStatic:Null<Bool>, inHaxelibName:String, noCopy:Bool)
   {
      var ndll =  findNdll(name);
      if ( !isNeko() && (name=="std" || name=="regexp" || name=="zlib" || name=="mysql" || name=="mysql5" || name=="sqlite" ) )
      {
         Log.verbose("Skip ndll " + name + " for toolkit link" );
      }
      else if (ndll==null)
      {
          var isStatic:Bool = optionalStaticLink && inStatic!=null ? inStatic : staticLink;

          if (name=="nme" && inStatic==null)
             isStatic = isStaticNme();

          ndlls.push( new NDLL(name, base, isStatic, inHaxelibName, noCopy) );
      }
      else if (inStatic && optionalStaticLink)
      {
          ndll.setStatic();
      }
      else if (noCopy)
      {
         ndll.noCopy = true;
      }
   }

   public function addLib(name:String, version:String="",inNoCopy:Bool)
   {
      var haxelib = findHaxelib(name);
      if (haxelib==null)
      {
         Log.verbose("Add library " + name + ":" + version );


         if (name=="openfl")
         {
            name = "nme";
            version="";
            Log.verbose("Using nme instead of openfl");
         }
         if (name=="lime")
         {
            name = "nme";
            version="";
            Log.verbose("Using nme instead of lime");
         }

         haxelib = new Haxelib(name,version);
         haxelibs.push(haxelib);

         var path = haxelib.getBase();
         Log.verbose("Adding " + name + "@" + path);

         if (FileSystem.exists(path + "/include.nmml")) 
            new NMMLParser(this, path + "/include.nmml", true);
         else if (FileSystem.exists(path + "/include.xml")) 
            new NMMLParser(this, path + "/include.xml", true);

         // flixel depends on lime, so lime gets same priority as flixel - we want nme with greater priority
         if (name=="flixel")
            raiseLib("nme");

         if (name=="nme" && !hasDef("watchos") )
            addNdll("nme", haxelib.getBase(), null, "nme", inNoCopy);
      }
      return haxelib;
  }


   public function processLibs()
   {
      var needsSwfHandler = false;

      for(asset in assets)
      {
         if (asset.type == SWF)
            needsSwfHandler = true;
      }

      if (needsSwfHandler && !libraryHandlers.exists("SWF"))
      {
         if (hasDef("flash"))
         {
            Log.verbose("Using default flash swf handler");
            libraryHandlers.set("SWF","nme.swf.SwfAssetLib");
         }
         else
         {
            if (findHaxelib("swf")!=null)
            {
               Log.verbose("Using swf haxelib native swf handler");
               libraryHandlers.set("SWF","format.swf.SWFLibrary");
            }
            else if (findHaxelib("gm2d")!=null)
            {
               Log.verbose("Using gm2d haxelib native swf handler");
               libraryHandlers.set("SWF","gm2d.swf.SWFLibrary");
            }
            else
               Log.verbose("No swf libraryHandlers set - getMovieClip may not work");
         }
      }

   }

   public function getContext(inBuildDir:String):Dynamic 
   {
      var context:Dynamic = baseTemplateContext;

       for(key in localDefines.keys())
         Reflect.setField(context, key, localDefines.get(key));

      for(field in Reflect.fields(app)) 
      {
         Reflect.setField(context, "APP_" + StringHelper.formatUppercaseVariable(field), Reflect.field(app, field));
      }

      if (watchProject!=null)
      {
         for(field in Reflect.fields(watchProject.app)) 
         {
            Reflect.setField(context, "WATCH_" + StringHelper.formatUppercaseVariable(field), Reflect.field(watchProject.app, field));
         }
      }

      context.BUILD_DIR = app.binDir;
      context.EMBED_ASSETS = embedAssets ? "true" : "false";
      context.OPENFL_COMPAT = openflCompat ? "true" : "false";
      if (openflCompat)
      {
         var oflVersion = hasDef("NME_OPENFL_VERSION") ? getDef("NME_OPENFL_VERSION") : "3.5.0";
         haxedefs.set("openfl",oflVersion);
         if (target!=Platform.FLASH ) 
         {
            haxedefs.set("openfl_legacy","1");
            haxedefs.set("lime_legacy","1");
         }
         haxeflags.push("--remap openfl:nme");
         addLib("nme","",false);
      }

      if (export!=null && export!="")
      {
         haxedefs.set("dll_export", export);
      }


      for(field in Reflect.fields(app)) 
         Reflect.setField(context, "APP_" + StringHelper.formatUppercaseVariable(field), Reflect.field(app, field));


      context.APP_PACKAGE = app.packageName;
      var engineArray = new Array<Dynamic>();
      for(key in engines.keys())
         engineArray.push( {name:key, version:engines.get(key) } );
      context.ENGINES = engineArray;
      context.NATIVE_FONTS = getBool("nativeFonts", true);
      context.PROJECT_FILENAME = projectFilename==null ? "Unknown.nmml" : projectFilename;

      for(field in Reflect.fields(window)) 
         Reflect.setField(context, "WIN_" + StringHelper.formatUppercaseVariable(field), Reflect.field(window, field));

      context.WIN_SCALE_FLAGS = Type.enumIndex(window.scaleMode);

      context.STAGE_SCALE = "NO_SCALE";
      context.STAGE_ALIGN = "TOP_LEFT";
      switch(window.scaleMode)
      {
         case ScaleNative:
         case ScaleGamePixels:
            context.STAGE_SCALE = "SHOW_ALL";
            context.STAGE_ALIGN = "GAME_PIXELS";
         case ScaleGameStretch:
            context.STAGE_SCALE = "SHOW_ALL";
            context.STAGE_ALIGN = "GAME_STRETCH";
         case ScaleCentre:
            context.STAGE_SCALE = "SHOW_ALL";
            context.STAGE_ALIGN = "CENTRE";
         case ScaleGame:
            context.STAGE_SCALE = "SHOW_ALL";
            context.STAGE_ALIGN = "GAME";
         case ScaleUiScaled:
      }
      context.WIN_STAGE_ALIGN = Type.enumIndex(window.scaleMode);


      for(haxeflag in haxeflags) 
      {
         if (StringTools.startsWith(haxeflag, "-lib")) 
            Reflect.setField(context, "LIB_" + haxeflag.substr(5).toUpperCase(), "true");
      }

      context.fileAssociations = fileAssociations;

      context.assets = new Array<Dynamic>();

      var alpha:String = getDef("NME_ALPHA_MODE");
      var defaultMode:AlphaMode = alpha!=null && alpha!="" ? NMMLParser.parseAlphaMode(alpha) : AlphaUnmultiplied;

      var convertDir = app.binDir + "/converted";
      for(asset in assets) 
      {
         if (asset.alphaMode==AlphaDefault)
            asset.alphaMode = defaultMode;
         asset.preprocess(convertDir);

         if ( (embedAssets || asset.embed) && target!=Platform.FLASH && target!=Platform.JSPRIME && target!=Platform.CPPIA)
         {
            asset.resourceName = asset.flatName;
            //var relPath = PathHelper.relocatePath(asset.sourcePath, inBuildDir);
            //haxeflags.push("-resource " + relPath  + "@" + asset.flatName );
            haxeflags.push("-resource " + asset.sourcePath  + "@" + asset.flatName );
         }

         context.assets.push(asset);
      }


      var handlers = new Array<Dynamic>();
      context.libraryHandlers = handlers;
      for(h in libraryHandlers.keys())
      {
         handlers.push({ type:h, handler:libraryHandlers.get(h) } );
      }

      Reflect.setField(context, "ndlls", ndlls);
      //Reflect.setField(context, "sslCaCert", sslCaCert);
      context.sslCaCert = "";

      var compilerFlags = [];

      if (target==Platform.JSPRIME)
      {
         // nothing
      }
      else if (target==Platform.CPPIA)
      {
         if (expandCppia())
            compilerFlags.push('-resource $inBuildDir/nme/scriptassets.txt@haxe/nme/scriptassets.txt');
      }
      else
      {
         compilerFlags.push('-resource $inBuildDir/nme/assets.txt@haxe/nme/assets.txt');
      }

      for(haxelib in haxelibs) 
      {
         haxelib.addLibraryFlags(compilerFlags);
         Reflect.setField(context, "LIB_" + haxelib.name.toUpperCase(), true);
      }

      //for(cp in classPaths) 
      //   compilerFlags.push("-cp " + PathHelper.relocatePath(cp, inBuildDir) );
      for(cp in classPaths) 
         compilerFlags.push("-cp " + cp );

      compilerFlags.push("-cp " + inBuildDir );

      if (megaTrace)
         haxedefs.set("HXCPP_DEBUGGER","");

      for(key in haxedefs.keys()) 
      {
         var value = haxedefs.get(key);

         if (value == null || value == "") 
            compilerFlags.push("-D " + key);
         else
            compilerFlags.push("-D " + key + "=" + value);
      }

      if (target != Platform.FLASH) 
      {
         compilerFlags.push("-D " + Std.string(target).toLowerCase());
      }

      compilerFlags.push("-D " + platformType.toLowerCase());

      compilerFlags = compilerFlags.concat(haxeflags);
      compilerFlags = compilerFlags.concat(macros);

      if (compilerFlags.length == 0) 
         context.HAXE_FLAGS = "";
      else
         context.HAXE_FLAGS = "\n" + compilerFlags.join("\n");

      var main = app.main;

      var indexOfPeriod = main.lastIndexOf(".");

      context.APP_MAIN_PACKAGE = main.substr(0, indexOfPeriod + 1);
      context.APP_MAIN_CLASS = main.substr(indexOfPeriod + 1);

      context.DEBUG = debug;
      context.MEGATRACE = megaTrace;
      context.SWF_VERSION = app.swfVersion;
      if (app.preloader!=null && app.preloader!="")
         context.PRELOADER_NAME = app.preloader;
      context.WIN_BACKGROUND = window.background;
      context.HTML_BACKGROUND = "#" + StringTools.hex(window.background,6);
      context.WIN_FULLSCREEN = window.fullscreen;
      context.WIN_ORIENTATION = "";

      if (window.orientation == Orientation.LANDSCAPE || window.orientation == Orientation.PORTRAIT) 
         context.WIN_ORIENTATION = Std.string(window.orientation).toLowerCase();

      context.WIN_ALLOW_SHADERS = window.allowShaders;
      context.WIN_REQUIRE_SHADERS = window.requireShaders;
      context.WIN_DEPTH_BUFFER = window.depthBuffer;
      context.WIN_STENCIL_BUFFER = window.stencilBuffer;
      context.WIN_ALPHA_BUFFER = window.alphaBuffer;

      if (certificate != null) 
      {
         context.KEY_STORE = PathHelper.tryFullPath(certificate.path);

         if (certificate.password != null) 
            context.KEY_STORE_PASSWORD = certificate.password;

         if (certificate.alias != null) 
            context.KEY_STORE_ALIAS = certificate.alias;
         else if (certificate.path != null) 
            context.KEY_STORE_ALIAS = Path.withoutExtension(Path.withoutDirectory(certificate.path));

         if (certificate.aliasPassword != null) 
            context.KEY_STORE_ALIAS_PASSWORD = certificate.aliasPassword;
         else if (certificate.password != null) 
            context.KEY_STORE_ALIAS_PASSWORD = certificate.password;
      }
      return context;
   }
}
