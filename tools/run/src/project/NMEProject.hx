package;

import haxe.io.Path;
import sys.FileSystem;
import platforms.Platform;

typedef StringMap<T> = Map<String, T>;
typedef IntMap<T> = Map<Int, T>;

class AndroidConfig
{
   public var installLocation:String;
   public var minApiLevel:Int;
   public var targetApiLevel:Null<Int>;
   public var buildApiLevel:Null<Int>;
   public var appHeader:Array<String>;
   public var appIntent:Array<String>;
   public var appActivity:Array<String>;
   public var appPermission:Array<String>;
   // Where to put source code when genrating a package
   public var viewPackageName:String;
   public var viewTestDir:String;

   public function new()
   {
      installLocation = "preferExternal";
      minApiLevel = 8;
      appHeader = [];
      appIntent = [];
      appActivity = [];
      appPermission = [];
      viewPackageName = "com.nmehost";
      viewTestDir = "";
   }
}

class IOSConfig
{
   inline public static var IPHONE     = 0x01;
   inline public static var IPAD       = 0x02;
   inline public static var UNIVERSAL  = 0x03;

   public var compiler:String;
   public var deployment:String;
   public var deviceConfig:Int;
   public var linkerFlags:String;
   public var prerenderedIcon:Bool;
   public var viewTestDir:String;

   public function new()
   {
      compiler =  "clang";
      deployment =  "5.1.1";
      deviceConfig =  UNIVERSAL;
      linkerFlags =  "";
      viewTestDir =  "";
      prerenderedIcon =  false;
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
   public var splashScreens:Array<SplashScreen>;
   public var optionalStaticLink:Bool;
   public var staticLink:Bool;
   public var stdLibs:Bool;

   // ios/android build parameters
   public var iosConfig:IOSConfig;
   public var androidConfig:AndroidConfig;

   // Defines
   public var localDefines:haxe.ds.StringMap<Dynamic>;
   public var environment:StringMap<String>;
   public var targetFlags:StringMap<String>;

   // For building haxe command line
   public var haxedefs:StringMap<Dynamic>;
   public var haxeflags:Array<String>;
   public var haxelibs:Array<Haxelib>;
   public var classPaths:Array<String>;
   public var macros:Array<String>;

   // For <include> elements
   public var includePaths:Array<String>;
   // For bulding projects
   public var templatePaths:Array<String>;

   // Currently for adding frameworks to ios project
   public var dependencies:Array<String>;
   // Additional files to be copied into andoird project
   public var javaPaths:Array<String>;
   // Android signing certificate
   public var certificate:Keystore;

   // Flags
   public var embedAssets:Bool;
   public var openflCompat:Bool;
   public var debug:Bool;
   public var megaTrace:Bool;

   // Exported into project for use in project files
   public var platformType:String;
   public var command:String;
   public var target:String;

   private var baseTemplateContext:Dynamic;



   public function new() 
   {
      baseTemplateContext = {};
      embedAssets = false;
      openflCompat = true;
      iosConfig = new IOSConfig();
      androidConfig = new AndroidConfig();

      debug = false;
      megaTrace = false;
      target = "";
      targetFlags = new StringMap<String>();
      templatePaths = [];

      environment = Sys.environment();
      if (environment.exists("ANDROID_SERIAL"))
         targetFlags.set("device", environment.get("ANDROID_SERIAL"));
      localDefines = new StringMap<String>();
      for(key in environment.keys())
         Reflect.setField(baseTemplateContext, key, environment.get(key));

      app = new ApplicationData();
      window = new Window();


      assets = new Array<Asset>();
      dependencies = new Array<String>();
      haxedefs = new StringMap<Dynamic>();
      haxeflags = new Array<String>();
      macros = new Array<String>();
      haxelibs = new Array<Haxelib>();
      icons = new Array<Icon>();
      javaPaths = new Array<String>();
      ndlls = new Array<NDLL>();
      classPaths = new Array<String>();
      splashScreens = new Array<SplashScreen>();
      architectures = [];
      staticLink = false;
      stdLibs = true;
      optionalStaticLink = true;
   }

   public function setCommand(inCommand:String)
   {
      command = inCommand;
      if (command != null) 
         localDefines.set(command.toLowerCase(), "1");
   }

   public function setTarget(inTargetName:String)
   {
      switch(inTargetName) 
      {
         case "cpp":
            target = PlatformHelper.hostPlatform;
            targetFlags.set("cpp", "");

         case "neko":
            target = PlatformHelper.hostPlatform;
            staticLink = false;
            optionalStaticLink = false;
            targetFlags.set("neko", "");

         case "ios":
            target = Platform.IOS;
            targetFlags.set("iphonesim", "");
            targetFlags.set("iphoneos", "");

         case "iphone", "iphoneos":
            target = Platform.IOS;
            targetFlags.set("iphoneos", "");

         case "iosview", "ios-view":
            targetFlags.set("ios", "");
            targetFlags.set("iosview", "");
            targetFlags.set("nativeview", "");
            haxedefs.set("nativeview","1");
            haxedefs.set("iosview","1");
            target = Platform.IOSVIEW;

         case "androidview", "android-view":
            targetFlags.set("android", "");
            targetFlags.set("androidview", "");
            targetFlags.set("nativeview", "");
            haxedefs.set("nativeview","1");
            haxedefs.set("androidview","1");
            target = Platform.ANDROIDVIEW;

         case "iphonesim":
            target = Platform.IOS;
            targetFlags.set("simulator", "");

         case "android":
            target = Platform.ANDROID;
            targetFlags.set("android", "");

         case "androidsim":
            target = Platform.ANDROID;
            targetFlags.set("android", "");
            targetFlags.set("androidsim", "");

         case "windows", "mac", "linux", "flash":
            target = inTargetName.toUpperCase();

         default:
            Log.error("Unknown target : " + inTargetName);
      }

      if (target==Platform.IOS || target==Platform.IOSVIEW || target==Platform.ANDROIDVIEW)
      {
         optionalStaticLink = false;
         staticLink = true;
      }
      if (target!=Platform.FLASH)
      {
          haxeflags.push("--remap flash:nme");
      }



      switch(target) 
      {
         case Platform.FLASH:

            platformType = Platform.TYPE_WEB;
            embedAssets = true;

         case Platform.ANDROID, Platform.IOS,
              Platform.IOSVIEW, Platform.ANDROIDVIEW:

            platformType = Platform.TYPE_MOBILE;

            if (target==Platform.IOSVIEW || target==Platform.ANDROIDVIEW) 
               embedAssets = true;

            window.width = 0;
            window.height = 0;
            window.fullscreen = true;

         case Platform.WINDOWS, Platform.MAC, Platform.LINUX:

            platformType = Platform.TYPE_DESKTOP;

            if (architectures.length==0)
            {
               if (target == Platform.LINUX) 
                  architectures = [ PlatformHelper.hostArchitecture ];
               else
                  architectures = [ Architecture.X86 ];
            }

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
      }

      Log.verbose("Platform type: " + platformType);


      for(key in targetFlags.keys())
         localDefines.set(key,targetFlags.get(key));

      localDefines.set("haxe3", "1");

      localDefines.set(target.toLowerCase(), "1");
   }

   public function addArch(arch:Architecture)
   {
      ArrayHelper.addUnique(architectures, arch);
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

   public function processStdLibs()
   {
      if (stdLibs)
      {
         for(lib in ["std", "zlib", "regexp"])
         {
            if (findNdll(lib)==null)
            {
               var haxelib = findHaxelib("hxcpp");
               if (haxelib == null)
               {
                  haxelib = new Haxelib("hxcpp");
                  haxelibs.push(haxelib);
               }

               var ndll = new NDLL(lib, haxelib, staticLink);
               ndlls.push(ndll);
            }
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

      context.BUILD_DIR = app.binDir;
      context.EMBED_ASSETS = embedAssets ? "true" : "false";
      context.OPENFL_COMPAT = openflCompat ? "true" : "false";
      if (openflCompat)
      {
         haxedefs.set("openfl","nme");
         haxeflags.push("--remap openfl:nme");
      }


      for(field in Reflect.fields(app)) 
         Reflect.setField(context, "APP_" + StringHelper.formatUppercaseVariable(field), Reflect.field(app, field));


      context.APP_PACKAGE = app.packageName;

      for(field in Reflect.fields(window)) 
         Reflect.setField(context, "WIN_" + StringHelper.formatUppercaseVariable(field), Reflect.field(window, field));


      for(haxeflag in haxeflags) 
      {
         if (StringTools.startsWith(haxeflag, "-lib")) 
            Reflect.setField(context, "LIB_" + haxeflag.substr(5).toUpperCase(), "true");
      }

      context.assets = new Array<Dynamic>();

      for(asset in assets) 
      {
         if ( (embedAssets || asset.embed) && target!=Platform.FLASH ) 
         {
            asset.resourceName = asset.flatName;
            var relPath = PathHelper.relocatePath(asset.sourcePath, inBuildDir);
            haxeflags.push("-resource " + relPath  + "@" + asset.flatName );
         }

         context.assets.push(asset);
      }

      Reflect.setField(context, "ndlls", ndlls);
      //Reflect.setField(context, "sslCaCert", sslCaCert);
      context.sslCaCert = "";

      var compilerFlags = [];

      for(haxelib in haxelibs) 
      {
         var name = haxelib.name;

         if (haxelib.version != "") 
            name += ":" + haxelib.version;

         compilerFlags.push("-lib " + name);
         Reflect.setField(context, "LIB_" + haxelib.name.toUpperCase(), true);
      }

      for(cp in classPaths) 
         compilerFlags.push("-cp " + PathHelper.relocatePath(cp, inBuildDir) );
      compilerFlags.push("-cp " + PathHelper.relocatePath(".", inBuildDir) );

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
