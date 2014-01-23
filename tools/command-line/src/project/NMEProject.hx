package;

import haxe.io.Path;
import haxe.Serializer;
import haxe.Unserializer;
import sys.FileSystem;
import platforms.Platform;

typedef StringMap<T> = Map<String, T>;
typedef IntMap<T> = Map<Int, T>;

class NMEProject 
{
   public var window:Window;
   public var app:ApplicationData;

   public var architectures:Array<Architecture>;
   public var assets:Array<Asset>;
   public var certificate:Keystore;
   public var command:String;
   public var config:PlatformConfig;
   public var debug:Bool;
   public var megaTrace:Bool;
   public var dependencies:Array<String>;
   public var environment:StringMap<String>;
   public var haxedefs:StringMap<Dynamic>;
   public var haxeflags:Array<String>;
   public var macros:Array<String>;
   public var haxelibs:Array<Haxelib>;
   public var host(get_host, null):String;
   public var icons:Array<Icon>;
   public var javaPaths:Array<String>;
   public var libraries:Array<Library>;
   public var ndlls:Array<NDLL>;
   public var platformType:String;
   public var sources:Array<String>;
   public var splashScreens:Array<SplashScreen>;
   public var target:String;
   public var targetFlags:StringMap<String>;
   public var templateContext(get_templateContext, null):Dynamic;
   public var templatePaths:Array<String>;
   public var component:String;
   public var embedAssets:Bool;
   public var openflCompat:Bool;

   private var baseTemplateContext:Dynamic;

   public var localDefines:haxe.ds.StringMap<Dynamic>;
   public var includePaths:Array<String>;


   public function new() 
   {
      baseTemplateContext = {};
      component = null;
      embedAssets = false;
      openflCompat = true;
      config = new PlatformConfig();

      debug = false;
      megaTrace = false;
      target = "";
      targetFlags = new StringMap<String>();
      templatePaths = [];

      environment = Sys.environment();
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
      libraries = new Array<Library>();
      ndlls = new Array<NDLL>();
      sources = new Array<String>();
      splashScreens = new Array<SplashScreen>();
   }

   public function setCommand(inCommand:String)
   {
      command = inCommand;
      if (command != null) 
         localDefines.set(command.toLowerCase(), "1");
   }

   public function setPlatform(inPlatform:String):Void 
   {
      platformType = inPlatform;
      switch(platformType) 
      {
         case Platform.TYPE_MOBILE:
            localDefines.set("mobile", "1");
         case Platform.TYPE_DESKTOP:
            localDefines.set("desktop", "1");
         case Platform.TYPE_WEB:
            localDefines.set("web", "1");
      }

      if (targetFlags.exists("cpp")) 
         localDefines.set("cpp", "1");
      else if (targetFlags.exists("neko")) 
         localDefines.set("neko", "1");

      if (target==Platform.IOSVIEW)
         localDefines.set("ios", "1");

      localDefines.set("haxe3", "1");

      localDefines.set(target.toLowerCase(), "1");
   }

   public function setTarget(inTargetName:String)
   {
      switch(inTargetName) 
      {
         case "cpp":
            target = host;
            targetFlags.set("cpp", "");

         case "neko":
            target = host;
            targetFlags.set("neko", "");

         case "iphone", "iphoneos":
            target = Platform.IOS;

         case "iosview":
            targetFlags.set("ios", "");
            targetFlags.set("iosview", "");
            targetFlags.set("nativeview", "");
            haxedefs.set("nativeview","1");
            target = Platform.IOSVIEW;

         case "androidview":
            targetFlags.set("android", "");
            targetFlags.set("androidview", "");
            targetFlags.set("nativeview", "");
            haxedefs.set("nativeview","1");
            target = Platform.ANDROIDVIEW;

         case "iphonesim":
            target = Platform.IOS;
            targetFlags.set("simulator", "");

         default:
            target = inTargetName.toUpperCase();
      }


      switch(target) 
      {
         case Platform.FLASH:

            platformType = Platform.TYPE_WEB;
            architectures = [];

         case Platform.HTML5:

            platformType = Platform.TYPE_WEB;
            architectures = [];

            window.fps = 0;

         case Platform.ANDROID, Platform.BLACKBERRY, Platform.IOS,
              Platform.IOSVIEW, Platform.WEBOS, Platform.ANDROIDVIEW:

            platformType = Platform.TYPE_MOBILE;

            if (target == Platform.IOS || target==Platform.IOSVIEW) 
            {
               architectures = [ Architecture.ARMV7 ];
            }
            else
            {
               architectures = [ Architecture.ARMV6 ];
            }

            if (target==Platform.IOSVIEW || target==Platform.ANDROIDVIEW) 
               embedAssets = true;

            window.width = 0;
            window.height = 0;
            window.fullscreen = true;

         case Platform.WINDOWS, Platform.MAC, Platform.LINUX:

            platformType = Platform.TYPE_DESKTOP;

            if (target == Platform.LINUX) 
            {
               architectures = [ PlatformHelper.hostArchitecture ];
            }
            else
            {
               architectures = [ Architecture.X86 ];
            }
      }
   }

   public function include(path:String):Void 
   {
      // extend project file somehow?
   }


   // Getters & Setters
   private function get_host():String 
   {
      return PlatformHelper.hostPlatform;
   }

   public function getComponent()
   {
      if (component==null)
         return app.file;
      return component;
   }

   private function get_templateContext():Dynamic 
   {
      var context:Dynamic = baseTemplateContext;


       for(key in localDefines.keys())
         Reflect.setField(context, key, localDefines.get(key));

      config.populate();

      for(field in Reflect.fields(app)) 
      {
         Reflect.setField(context, "APP_" + StringHelper.formatUppercaseVariable(field), Reflect.field(app, field));
      }

      context.BUILD_DIR = app.path;
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
         {
            Reflect.setField(context, "LIB_" + haxeflag.substr(5).toUpperCase(), "true");
         }
      }

      context.assets = new Array<Dynamic>();

      for(asset in assets) 
      {
         if (embedAssets)
         {
            asset.resourceName = asset.flatName;
            var absPath = sys.FileSystem.fullPath(asset.sourcePath);
            haxeflags.push("-resource " + absPath  + "@" + asset.flatName );
         }

         context.assets.push(asset);
      }

      context.libraries = new Array<Dynamic>();

      for(library in libraries) 
      {
         var libraryData:Dynamic = { };
         ObjectHelper.copyFields(library, libraryData);
         libraryData.type = Std.string(library.type).toLowerCase();
         context.libraries.push(libraryData);
      }

      Reflect.setField(context, "ndlls", ndlls);
      //Reflect.setField(context, "sslCaCert", sslCaCert);
      context.sslCaCert = "";

      var compilerFlags = [];

      for(haxelib in haxelibs) 
      {
         var name = haxelib.name;

         if (haxelib.version != "") 
         {
            name += ":" + haxelib.version;
         }

         compilerFlags.push("-lib " + name);

         Reflect.setField(context, "LIB_" + haxelib.name.toUpperCase(), true);
      }

      for(source in sources) 
      {
         compilerFlags.push("-cp " + source);
      }

      if (megaTrace)
         haxedefs.set("HXCPP_DEBUGGER","");

      for(key in haxedefs.keys()) 
      {
         var value = haxedefs.get(key);

         if (#if !haxe3 true || #end value == null || value == "") 
         {
            compilerFlags.push("-D " + key);
         }
         else
         {
            compilerFlags.push("-D " + key + "=" + value);
         }
      }

      if (target != Platform.FLASH) 
      {
         compilerFlags.push("-D " + Std.string(target).toLowerCase());
      }

      compilerFlags.push("-D " + platformType.toLowerCase());
      compilerFlags = compilerFlags.concat(haxeflags);
      compilerFlags = compilerFlags.concat(macros);

      if (compilerFlags.length == 0) 
      {
         context.HAXE_FLAGS = "";
      }
      else
      {
         context.HAXE_FLAGS = "\n" + compilerFlags.join("\n");
      }

      var main = app.main;

      var indexOfPeriod = main.lastIndexOf(".");

      context.APP_MAIN_PACKAGE = main.substr(0, indexOfPeriod + 1);
      context.APP_MAIN_CLASS = main.substr(indexOfPeriod + 1);

      var hxml = Std.string(target).toLowerCase() + "/hxml/" + (debug ? "debug" : "release") + ".hxml";

      for(templatePath in templatePaths) 
      {
         var path = PathHelper.combine(templatePath, hxml);

         if (FileSystem.exists(path)) 
         {
            context.HXML_PATH = path;
         }
      }

      for(field in Reflect.fields(context)) 
      {
         //Sys.println("context." + field + " = " + Reflect.field(context, field));
      }

      context.DEBUG = debug;
      context.MEGATRACE = megaTrace;
      context.SWF_VERSION = app.swfVersion;
      context.PRELOADER_NAME = app.preloader;
      context.WIN_BACKGROUND = window.background;
      context.WIN_FULLSCREEN = window.fullscreen;
      context.WIN_ORIENTATION = "";

      if (window.orientation == Orientation.LANDSCAPE || window.orientation == Orientation.PORTRAIT) 
      {
         context.WIN_ORIENTATION = Std.string(window.orientation).toLowerCase();
      }

      context.WIN_ALLOW_SHADERS = window.allowShaders;
      context.WIN_REQUIRE_SHADERS = window.requireShaders;
      context.WIN_DEPTH_BUFFER = window.depthBuffer;
      context.WIN_STENCIL_BUFFER = window.stencilBuffer;
      context.WIN_ALPHA_BUFFER = window.alphaBuffer;
      context.COMPONENT = getComponent();

      if (certificate != null) 
      {
         context.KEY_STORE = PathHelper.tryFullPath(certificate.path);

         if (certificate.password != null) 
         {
            context.KEY_STORE_PASSWORD = certificate.password;
         }

         if (certificate.alias != null) 
         {
            context.KEY_STORE_ALIAS = certificate.alias;

         } else if (certificate.path != null) 
         {
            context.KEY_STORE_ALIAS = Path.withoutExtension(Path.withoutDirectory(certificate.path));
         }

         if (certificate.aliasPassword != null) 
         {
            context.KEY_STORE_ALIAS_PASSWORD = certificate.aliasPassword;

         } else if (certificate.password != null) 
         {
            context.KEY_STORE_ALIAS_PASSWORD = certificate.password;
         }
      }

      return context;
   }
}
