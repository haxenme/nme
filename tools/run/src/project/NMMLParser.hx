package;

import haxe.io.Path;
import haxe.xml.Fast;
import sys.io.File;
import sys.FileSystem;
import NMEProject;
import platforms.Platform;

class NMMLParser
{
   var project:NMEProject;
   var defaultLib:Haxelib;

   static var varMatch = new EReg("\\${(.*?)}", "");

   public function new(inProject:NMEProject, path:String,?inDefaultLib:Haxelib)
   {
      project = inProject;
      defaultLib = inDefaultLib;
      process(path);
   }

   private function filter(text:String, include:Array<String> = null, exclude:Array<String> = null):Bool 
   {
      if (include == null) 
         include = [ "*" ];

      if (exclude == null) 
         exclude = [];

      for(filter in exclude) 
      {
         if (filter != "") 
         {
            filter = StringTools.replace(filter, ".", "\\.");
            filter = StringTools.replace(filter, "*", ".*");

            var regexp = new EReg("^" + filter, "i");

            if (regexp.match(text)) 
            {
               return false;
            }
         }
      }

      for(filter in include) 
      {
         if (filter != "") 
         {
            filter = StringTools.replace(filter, ".", "\\.");
            filter = StringTools.replace(filter, "*", ".*");

            var regexp = new EReg("^" + filter, "i");

            if (regexp.match(text)) 
               return true;
         }
      }

      return false;
   }


   public function path(value:String):Void 
   {
      if (PlatformHelper.hostPlatform == Platform.WINDOWS) 
         setenv("PATH", value + ";" + Sys.getEnv("PATH"));
      else
         setenv("PATH", value + ":" + Sys.getEnv("PATH"));
   }

   public function setenv(name:String, value:String):Void 
   {
      Sys.putEnv(name, value);
   }


   function parseBool(value:String):Bool 
   {
      var v = substitute(value);
      return v=="1" || v=="true" || v=="TRUE";
   }

   private function isValidElement(element:Fast, section:String):Bool 
   {
      if (element.x.get("if") != null) 
      {
         var value = element.x.get("if");
         var optionalDefines = value.split("||");
         var isValid = true;

         for(optional in optionalDefines) 
         {
            var requiredDefines = optional.split(" ");

            for(required in requiredDefines) 
            {
               var check = StringTools.trim(required);

               if (check != "" && !project.localDefines.exists(check)) 
               {
                  isValid = false;
               }
            }
         }

         return isValid;
      }

      if (element.has.unless) 
      {
         var value = element.att.unless;
         var optionalDefines = value.split("||");
         var isValid = true;

         for(optional in optionalDefines) 
         {
            var requiredDefines = optional.split(" ");

            for(required in requiredDefines) 
            {
               var check = StringTools.trim(required);

               if (check != "" && project.localDefines.exists(check)) 
               {
                  isValid = false;
               }
            }
         }

         return isValid;
      }

      if (section != "") 
      {
         if (element.name != "section") 
            return false;

         if (!element.has.id) 
            return false;

         if (element.att.id != section) 
            return false;
      }

      return true;
   }

   private function findIncludeFile(base:String):String 
   {
      if (base == "") 
         return "";

      if (base.substr(0, 1) != "/" && base.substr(0, 1) != "\\") 
      {
         if (base.substr(1, 1) != ":") 
         {
            for(path in project.includePaths) 
            {
               var includePath = path + "/" + base;

               if (FileSystem.exists(includePath)) 
               {
                  if (FileSystem.exists(includePath + "/include.xml")) 
                     return includePath + "/include.xml";
                  else
                     return includePath;
               }
            }
         }
      }

      if (FileSystem.exists(base)) 
      {
         if (FileSystem.exists(base + "/include.xml")) 
            return base + "/include.xml";
         else
            return base;
      }

      return "";
   }

   private function formatAttributeName(name:String):String 
   {
      var segments = name.split("_").join("-").toLowerCase().split("-");
      if (segments.length==1)
         return name;

      for(i in 1...segments.length) 
         segments[i] = segments[i].substr(0, 1).toUpperCase() + segments[i].substr(1);

      return segments.join("");
   }

   private function parseAppElement(element:Fast):Void 
   {
      for(attribute in element.x.attributes()) 
      {
         switch(attribute) 
         {
            case "path":
               project.app.binDir = substitute(element.att.path);
            case "bin":
               project.app.binDir = substitute(element.att.bin);

            case "min-swf-version":
               var version = Std.parseFloat(substitute(element.att.resolve("min-swf-version")));

               if (version > project.app.swfVersion) 
                  project.app.swfVersion = version;

            case "swf-version":
               project.app.swfVersion = Std.parseFloat(substitute(element.att.resolve("swf-version")));

            case "preloader":
               project.app.preloader = substitute(element.att.preloader);

            case "package", "packageName", "package-name":
               project.app.packageName = substitute(element.att.resolve(attribute));

            case "title", "description", "version", "company", "company-id", "build-number", "companyId", "buildNumber":

               var value = substitute(element.att.resolve(attribute));

               project.localDefines.set("APP_" + StringTools.replace(attribute, "-", "_").toUpperCase(), value);

               var name = formatAttributeName(attribute);

               Reflect.setField(project.app, name, value);

            default:

               // if we are happy with this spec, we can tighten up this parsing a bit, later
               var name = formatAttributeName(attribute);
               var value = substitute(element.att.resolve(attribute));

               if (Reflect.hasField(project.app, name)) 
                  Reflect.setField(project.app, name, value);
         }
      }
   }

   private function parseAssetsElement(element:Fast, basePath:String = ""):Void 
   {
      var path = basePath;
      var embed = project.embedAssets;
      var targetPath = "";
      var glyphs = null;
      var type = null;
      var recurse = true;

      if (element.has.path) 
      {
         path = basePath + substitute(element.att.path);

         if (element.has.rename) 
            targetPath = substitute(element.att.rename);
         else
            targetPath = path;
      }
      else if (element.has.from)
      {
         path = basePath + substitute(element.att.from);

         if (element.has.rename) 
            targetPath = substitute(element.att.rename);
         else
            targetPath = "";
      }

      if (element.has.embed) 
         embed = embed || parseBool(substitute(element.att.embed));

      Log.verbose("Assets from " + path + " to virtual directory '" + targetPath + "'");

      if (element.has.glyphs) 
         glyphs = substitute(element.att.glyphs);

      if (element.has.recurse) 
         recurse = parseBool(element.att.recurse);

      if (element.has.type) 
         type = Reflect.field(AssetType, substitute(element.att.type).toUpperCase());


      if (path=="" && (element.has.include || element.has.exclude || type!=null )) 
      {
         Log.error("In order to use 'include' or 'exclude' on <asset /> nodes, you must specify also specify a 'path' attribute");
         return;

      }
      else if (!element.elements.hasNext()) 
      {
         // Empty element
         if (path == "") 
            return;

         if (!FileSystem.exists(path)) 
         {
            Log.error("Could not find asset path \"" + path + "\"");
            return;
         }

         if (!FileSystem.isDirectory(path)) 
         {
            var id = "";

            if (element.has.id) 
               id = substitute(element.att.id);

            var asset = new Asset(path, targetPath, type, embed);
            asset.id = id;

            if (glyphs != null) 
               asset.glyphs = glyphs;

            project.assets.push(asset);
            Log.verbose("  " + asset);
         }
         else
         {
            var exclude = ".*|cvs|thumbs.db|desktop.ini|*.hash";
            var include = "";

            if (element.has.exclude) 
               exclude += "|" + element.att.exclude;

            if (element.has.include) 
            {
               include = element.att.include;
            }
            else
            {
               if (type == null) 
               {
                  include = "*";
               }
               else
               {
                  switch(type) 
                  {
                     case IMAGE:
                        include = "*.jpg|*.jpeg|*.png|*.gif";

                     case SOUND:
                        include = "*.wav|*.ogg";

                     case MUSIC:
                        include = "*.mp2|*.mp3";

                     case FONT:
                        include = "*.otf|*.ttf";

                     default:
                        include = "*";
                  }
               }
            }

            parseAssetsElementDirectory(path, targetPath, include, exclude, type, embed, glyphs, recurse);
         }
      }
      else
      {
         if (path != "") 
            path += "/";

         if (targetPath != "") 
            targetPath += "/";

         for(childElement in element.elements) 
         {
            var isValid = isValidElement(childElement, "");

            if (isValid) 
            {
               var childPath = substitute(childElement.has.name ? childElement.att.name : childElement.att.path);
               var childTargetPath = childPath;
               var childEmbed = embed;
               var childType = type;
               var childGlyphs = glyphs;

               if (childElement.has.rename) 
                  childTargetPath = childElement.att.rename;

               if (childElement.has.embed) 
                  childEmbed =  parseBool(substitute(childElement.att.embed)) || project.embedAssets;

               if (childElement.has.glyphs) 
                  childGlyphs = substitute(childElement.att.glyphs);

               switch(childElement.name) 
               {
                  case "image", "sound", "music", "font", "template":
                     childType = Reflect.field(AssetType, childElement.name.toUpperCase());

                  default:

                     if (childElement.has.type) 
                        childType = Reflect.field(AssetType, childElement.att.type.toUpperCase());
               }

               var id = "";
               if (childElement.has.id) 
                  id = substitute(childElement.att.id);
               else if (childElement.has.name) 
                  id = substitute(childElement.att.name);


               var asset = new Asset(path + childPath, targetPath + childTargetPath, childType, childEmbed);
               asset.id = id;

               if (childGlyphs != null) 
                  asset.glyphs = childGlyphs;

               project.assets.push(asset);
            }
         }
      }
   }

   private function parseAssetsElementDirectory(path:String, targetPath:String, include:String, exclude:String, type:AssetType, embed:Bool, glyphs:String, recursive:Bool):Void 
   {
      var files = FileSystem.readDirectory(path);

      if (targetPath != "") 
         targetPath += "/";

      for(file in files) 
      {
         if (FileSystem.isDirectory(path + "/" + file) && recursive) 
         {
            if (filter(file, [ "*" ], exclude.split("|"))) 
               parseAssetsElementDirectory(path + "/" + file, targetPath + file, include, exclude, type, embed, glyphs, true);
         }
         else
         {
            if (filter(file, include.split("|"), exclude.split("|"))) 
            {
               var asset = new Asset(path + "/" + file, targetPath + file, type, embed);

               if (glyphs != null) 
                  asset.glyphs = glyphs;

               project.assets.push(asset);
            }
         }
      }
   }

   private function parseAndroidElement(element:Fast):Void 
   {
      if (element.has.minApiLevel) 
         project.androidConfig.minApiLevel = Std.parseInt(substitute(element.att.minApiLevel));

      if (element.has.targetApiLevel) 
         project.androidConfig.targetApiLevel = Std.parseInt(substitute(element.att.targetApiLevel));

      if (element.has.buildApiLevel) 
         project.androidConfig.buildApiLevel = Std.parseInt(substitute(element.att.buildApiLevel));

      if (element.has.installLocation) 
         project.androidConfig.installLocation = substitute(element.att.installLocation);

      for(childElement in element.elements) 
      {
         if (isValidElement(childElement, ""))
         {
            var value = substitute(childElement.att.value);
            switch(childElement.name) 
            {
               case "appHeader":
                  project.androidConfig.appHeader.push(value);

               case "appActivity":
                  project.androidConfig.appActivity.push(value);

               case "appPermission":
                  project.androidConfig.appPermission.push(value);

               case "appIntent":
                  project.androidConfig.appIntent.push(value);

               default:
                  Log.error("Unknown android attribute " + childElement.name);
            }
         }
      }
   }



   private function parseOutputElement(element:Fast):Void 
   {
      if (element.has.name) 
         project.app.file = substitute(element.att.name);

      if (element.has.path) 
         project.app.binDir = substitute(element.att.path);

      if (element.has.resolve("swf-version")) 
         project.app.swfVersion = Std.parseFloat(substitute(element.att.resolve("swf-version")));
   }

   private function parseXML(xml:Fast, section:String, extensionPath:String = ""):Void 
   {
      for(element in xml.elements) 
      {
         var isValid = isValidElement(element, section);
         if (isValid) 
         {
            switch(element.name) 
            {
               case "set":

                  var name = element.att.name;
                  var value = "";

                  if (element.has.value) 
                  {
                     value = substitute(element.att.value);
                  }

                  switch(name) 
                  {
                     case "BUILD_DIR": project.app.binDir = value;
                     case "SWF_VERSION": project.app.swfVersion = Std.parseFloat(value);
                     case "PRERENDERED_ICON": project.iosConfig.prerenderedIcon = (value == "true");
                     case "ANDROID_INSTALL_LOCATION": project.androidConfig.installLocation = value;
                  }

                  project.localDefines.set(name, value);
                  project.environment.set(name, value);

               case "unset":

                  project.localDefines.remove(element.att.name);
                  project.environment.remove(element.att.name);

               case "setenv":
                  var value = "";

                  if (element.has.value) 
                     value = substitute(element.att.value);
                  else
                     value = "1";

                  var name = element.att.name;

                  project.localDefines.set(name, value);
                  project.environment.set(name, value);
                  setenv(name, value);

               case "error":
                  Log.error(substitute(element.att.value));

               case "echo":
                  Sys.println(substitute(element.att.value));

               case "path":
                  var value = "";

                  if (element.has.value) 
                     value = substitute(element.att.value);
                  else
                     value = substitute(element.att.name);

                  /*if (defines.get("HOST") == "windows") {
                     Sys.putEnv("PATH", value + ";" + Sys.getEnv("PATH"));
                  }
                  else
                  {
                     Sys.putEnv("PATH", value + ":" + Sys.getEnv("PATH"));

                  }*/

                  path(value);

               case "include":

                  var path = "";

                  if (element.has.path) 
                  {
                     var subPath = substitute(element.att.path);
                     if (subPath == "") subPath = element.att.path;
                     path = findIncludeFile(PathHelper.combine(extensionPath, subPath));
                  }
                  else
                  {
                     path = findIncludeFile(PathHelper.combine(extensionPath, substitute(element.att.name)));
                  }

                  if (path != null && path != "" && FileSystem.exists(path)) 
                  {
                     new NMMLParser(project,path);
                     var dir = Path.directory(path);
                     if (dir != "")
                        project.classPaths.push(dir);
                  }
                  else if (!element.has.noerror) 
                  {
                     Log.error("Could not find include file \"" + path + "\"");
                  }

               case "app", "meta":
                  parseAppElement(element);


               case "java":
                  project.javaPaths.push(PathHelper.combine(extensionPath, substitute(element.att.path)));

               case "haxelib":

                  /*var name:String = substitute(element.att.name);
                  compilerFlags.push("-lib " + name);

                  var path = Utils.getHaxelib(name);

                  if (FileSystem.exists(path + "/include.xml")) 
                  {
                     var xml:Fast = new Fast(Xml.parse(File.getContent(path + "/include.xml")).firstElement());
                     parseXML(xml, "", path + "/");

                  }*/

                  var name = substitute(element.att.name);
                  var version = "";

                  if (element.has.version) 
                  {
                     version = substitute(element.att.version);
                  }

                  var haxelib = new Haxelib(name, version);
                  var path = PathHelper.getHaxelib(haxelib);

                  if (FileSystem.exists(path + "/include.xml")) 
                  {
                     new NMMLParser(project, path + "/include.xml", haxelib);
                     project.classPaths.push(path);
                  }

                  project.haxelibs.push(haxelib);

               case "ndll":

                  var name = substitute(element.att.name);
                  if (!Lambda.exists(project.ndlls,function(n) return n.name==name))
                  {
                     var haxelib = null;

                     if (element.has.haxelib) 
                        haxelib = new Haxelib(substitute(element.att.haxelib));

                     if (haxelib == null && (name == "std" || name == "regexp" || name == "zlib")) 
                        haxelib = new Haxelib("hxcpp");

                     if (haxelib==null)
                        haxelib = defaultLib;

                     var register = !element.has.register || substitute(element.att.register)!="false";
                     var ndll = new NDLL(name, haxelib,register);
                     ndll.extensionPath = extensionPath;
                     project.ndlls.push(ndll);
                  }

               case "launchImage":

                  /*var name:String = "";
                  if (element.has.path) 
                  {
                     name = substitute(element.att.path);
                  }
                  else
                  {
                     name = substitute(element.att.name);
                  }

                  var width:String = "";
                  var height:String = "";

                  if (element.has.width) 
                  {
                     width = substitute(element.att.width);
                  }

                  if (element.has.height) 
                  {
                     height = substitute(element.att.height);
                  }

                  launchImages.push(new LaunchImage(name, width, height));*/

                  var name:String = "";
                  if (element.has.path) 
                     name = substitute(element.att.path);
                  else
                     name = substitute(element.att.name);

                  var splashScreen = new SplashScreen(name);

                  if (element.has.width) 
                     splashScreen.width = Std.parseInt(substitute(element.att.width));

                  if (element.has.height) 
                     splashScreen.height = Std.parseInt(substitute(element.att.height));

                  project.splashScreens.push(splashScreen);

               case "icon":

                  /*var name:String = "";
                  if (element.has.path) 
                  {
                     name = substitute(element.att.path);
                  }
                  else
                  {
                     name = substitute(element.att.name);
                  }

                  var width:String = "";
                  var height:String = "";

                  if (element.has.size) 
                  {
                     width = height = substitute(element.att.size);
                  }

                  if (element.has.width) 
                  {
                     width = substitute(element.att.width);
                  }

                  if (element.has.height) 
                  {
                     height = substitute(element.att.height);
                  }

                  icons.add(new Icon(name, width, height));*/

                  var name = "";

                  if (element.has.path) 
                     name = substitute(element.att.path);
                  else
                     name = substitute(element.att.name);

                  var icon = new Icon(name);

                  if (element.has.size) 
                     icon.size = icon.width = icon.height = Std.parseInt(substitute(element.att.size));

                  if (element.has.width) 
                     icon.width = Std.parseInt(substitute(element.att.width));

                  if (element.has.height) 
                     icon.height = Std.parseInt(substitute(element.att.height));

                  project.icons.push(icon);

               case "source", "classpath":
                  var path = "";

                  if (element.has.path) 
                     path = PathHelper.combine(extensionPath, substitute(element.att.path));
                  else
                     path = PathHelper.combine(extensionPath, substitute(element.att.name));
                  project.classPaths.push(path);

               case "extension":

                  // deprecated
               case "haxedef":
                  var name = substitute(element.att.name);
                  var value = "";
                  if (element.has.value) 
                     value = substitute(element.att.value);
                  project.haxedefs.set(name, value);

               case "haxeflag", "compilerflag":
                  var flag = substitute(element.att.name);
                  if (element.has.value) 
                     flag += " " + substitute(element.att.value);
                  project.haxeflags.push(substitute(flag));

               case "window":
                  parseWindowElement(element);

               case "assets":
                  parseAssetsElement(element, extensionPath);

               case "ssl":

                  //if (wantSslCertificate())
                     //parseSsl(element);
               case "template", "templatePath":

                  var path = PathHelper.combine(extensionPath, substitute(element.att.name));

                  project.templatePaths.remove(path);
                  project.templatePaths.push(path);

               case "preloader":
                  // deprecated
                  project.app.preloader = substitute(element.att.name);

               case "android":
                  parseAndroidElement(element);

               case "output":
                  parseOutputElement(element);

               case "section":
                  parseXML(element, "");

               case "certificate":
                  project.certificate = new Keystore(substitute(element.att.path));

                  if (element.has.type) 
                     project.certificate.type = substitute(element.att.type);

                  if (element.has.password) 
                     project.certificate.password = substitute(element.att.password);

                  if (element.has.alias) 
                     project.certificate.alias = substitute(element.att.alias);

                  if (element.has.resolve("alias-password")) 
                     project.certificate.aliasPassword = substitute(element.att.resolve("alias-password"));
                  else if (element.has.alias_password) 
                     project.certificate.aliasPassword = substitute(element.att.alias_password);

               case "dependency":
                  project.dependencies.push(substitute(element.att.name));

               case "ios":
                  if (project.target == Platform.IOS || project.target == Platform.IOSVIEW ) 
                  {
                     if (element.has.deployment) 
                     {
                        var deployment = Std.parseFloat(substitute(element.att.deployment));

                        // If it is specified, assume the dev knows what he is doing!
                        project.iosConfig.deployment = deployment;
                     }

                     if (element.has.binaries) 
                     {
                        var binaries = substitute(element.att.binaries);

                        switch(binaries) 
                        {
                           case "fat":
                              ArrayHelper.addUnique(project.architectures, Architecture.ARMV6);
                              ArrayHelper.addUnique(project.architectures, Architecture.ARMV7);

                           case "armv6":
                              ArrayHelper.addUnique(project.architectures, Architecture.ARMV6);
                              project.architectures.remove(Architecture.ARMV7);

                           case "armv7":
                              ArrayHelper.addUnique(project.architectures, Architecture.ARMV7);
                              project.architectures.remove(Architecture.ARMV6);
                        }
                     }

                     if (element.has.devices) 
                     {
                        switch(substitute(element.att.devices).toUpperCase())
                        {
                           case "UNIVERSAL" : project.iosConfig.deviceConfig = IOSConfig.UNIVERSAL;
                           case "IPHONE" : project.iosConfig.deviceConfig = IOSConfig.IPHONE;
                           case "IPAD" : project.iosConfig.deviceConfig = IOSConfig.IPAD;
                        }
                     }

                     if (element.has.compiler) 
                        project.iosConfig.compiler = substitute(element.att.compiler);

                     if (element.has.resolve("prerendered-icon")) 
                        project.iosConfig.prerenderedIcon = (substitute(element.att.resolve("prerendered-icon")) == "true");

                     if (element.has.resolve("linker-flags")) 
                        project.iosConfig.linkerFlags = substitute(element.att.resolve("linker-flags"));
                  }
            }
         }
      }
   }

   private function parseWindowElement(element:Fast):Void 
   {
      for(attribute in element.x.attributes()) 
      {
         var name = formatAttributeName(attribute);
         var value = substitute(element.att.resolve(attribute));

         switch(name) 
         {
            case "background":
               value = StringTools.replace(value, "#", "");
               if (value.indexOf("0x") == -1) 
                  value = "0x" + value;
               project.window.background = Std.parseInt(value);

            case "orientation":
               var orientation = Reflect.field(Orientation, Std.string(value).toUpperCase());
               if (orientation != null) 
                  project.window.orientation = orientation;

            case "height", "width", "fps", "antialiasing":
               if (Reflect.hasField(project.window, name)) 
                  Reflect.setField(project.window, name, Std.parseInt(value));

            case "parameters":
               if (Reflect.hasField(project.window, name)) 
                  Reflect.setField(project.window, name, Std.string(value));

            default:
               if (Reflect.hasField(project.window, name)) 
                  Reflect.setField(project.window, name, value == "true");
               else
               {
                  //Log.error("Unknown window field: " + name);
               }
         }
      }
   }

   public function process(projectFile:String):Void 
   {
      var xml = null;
      var extensionPath = "";

      try 
      {
         xml = new Fast(Xml.parse(File.getContent(projectFile)).firstElement());
         extensionPath = Path.directory(projectFile);

      } catch(e:Dynamic) 
      {
         Log.error("\"" + projectFile + "\" contains invalid XML data", e);
      }

      parseXML(xml, "", extensionPath);
   }

   private function substitute(string:String):String 
   {
      var newString = string;

      while(varMatch.match(newString)) 
      {
         newString = project.localDefines.get(varMatch.matched(1));

         if (newString == null) 
         {
            newString = "";
         }

         newString = varMatch.matchedLeft() + newString + varMatch.matchedRight();
      }

      return newString;
   }
}
