package;

import haxe.io.Path;
import haxe.xml.Fast;
import sys.io.File;
import sys.FileSystem;
import NMEProject;
import platforms.Platform;

using StringTools;

class NMMLParser
{
   var project:NMEProject;
   static var gitVersion:String = null;

   static var varMatch = new EReg("\\${(.*?)}", "");

   public function new(inProject:NMEProject, path:String )
   {
      project = inProject;
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

   function combine(a:String, b:String)
   {
      return PathHelper.combine(a,b);
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

               if (check != "" && !project.hasDef(check)) 
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

   public static function formatAttributeName(name:String):String 
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
         var namedPath = substitute(element.att.path);
         path = basePath + namedPath;

         if (element.has.rename) 
            targetPath = substitute(element.att.rename);
         else
            targetPath = namedPath;
      }
      else if (element.has.from)
      {
         path = basePath + substitute(element.att.from);

         if (element.has.rename) 
            targetPath = substitute(element.att.rename);
         else
            targetPath = "";
      }

      path = project.relocatePath(path);

      if (element.has.embed) 
         embed = embed || parseBool(substitute(element.att.embed));

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
            if (id!="")
               asset.id = id;

            if (glyphs != null) 
               asset.glyphs = glyphs;

            project.assets.push(asset);
            Log.verbose("Asset from " + path + " " + asset.type);
         }
         else
         {
            Log.verbose("Assets from " + path + " to virtual directory '" + targetPath + "'");

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

      if (element.has.extension)
         project.androidConfig.extensions.set(substitute(element.att.extension),true);


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
                  project.androidConfig.appPermission.push(
                      new AndroidPermission(value, childElement.has.required ? substitute(childElement.att.required) : "") );

               case "appFeature":
                  project.androidConfig.appFeature.push(
                      new AndroidFeature(value, childElement.has.required ? substitute(childElement.att.required) : "") );
               case "appIntent":
                  project.androidConfig.appIntent.push(value);

               case "gameActivityViewBase":
                  project.androidConfig.gameActivityViewBase = value;

               case "gameActivityBase":
                  project.androidConfig.gameActivityBase = value;

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

   private function parseXML(xml:Fast, section:String, extensionPath:String):Void 
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

               case "iosViewTestDir":
                  project.iosConfig.viewTestDir = substitute(element.att.name);

               case "androidViewTestDir":
                  project.androidConfig.viewTestDir = substitute(element.att.name);

               case "androidViewPackageName":
                  project.androidConfig.viewPackageName = substitute(element.att.name);

               case "error":
                  Log.error(substitute(element.att.value));

               case "mkdir":
                  var dir = substitute(element.att.name);
                  if (dir!=null && dir!="")
                  {
                     Log.verbose('mkdir $dir');
                     PathHelper.mkdir(dir);
                  }

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
                     path = findIncludeFile(combine(extensionPath, subPath));
                  }
                  else
                  {
                     path = findIncludeFile(combine(extensionPath, substitute(element.att.name)));
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

               case "staticlink":
                  if (project.optionalStaticLink)
                     project.staticLink = element.has.value ? parseBool(substitute(element.att.value)) : true;

               case "stdlibs":
                  project.stdLibs = element.has.value ? parseBool(substitute(element.att.value)) : true;

               case "macro":
                  project.macros.push("--macro " + substitute(element.att.value));

               case "export":
                  if (element.has.name)
                     project.export = substitute(element.att.name);
                  if (element.has.filter)
                     project.exportFilter = substitute(element.att.filter);
                  if (element.has.sourceDir)
                     project.exportSourceDir = substitute(element.att.sourceDir);

               case "java":
                  project.javaPaths.push(combine(extensionPath, substitute(element.att.path)));

               case "ndll":
                  var isStatic:Null<Bool> = null;
                  if (element.has.resolve("static"))
                      isStatic = parseBool(element.att.resolve("static"));
                 var name = substitute(element.att.name);

                 var haxelib = "";
                 var version = "";
                 if (element.has.haxelib)
                 {
                    haxelib = substitute(element.att.haxelib);
                    if (element.has.version) 
                       version = substitute(element.att.version);
                 }

                 if (haxelib == "")
                 {
                     if ( (name == "std" || name == "regexp" || name == "zlib" ||
                          name=="sqlite" || name=="mysql5")) 
                        haxelib = "hxcpp";
                 }
                 var base = extensionPath;
                 if (haxelib!="")
                 {
                    var lib = project.addLib(haxelib,version);
                    base = lib.getBase();
                 }
                 if (name!="lime" && name!="openfl")
                    project.addNdll(name, base, isStatic, haxelib);



               case "lib", "haxelib":
                  var name = substitute(element.att.name);

                  var version = "";
                  if (element.has.version) 
                     version = substitute(element.att.version);

                  project.addLib(name,version);
 

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

               case "icon", "banner":
                  var name = "";

                  if (element.has.path) 
                     name = substitute(element.att.path);
                  else
                     name = substitute(element.att.name);

                  name = project.relocatePath(combine(extensionPath,name));

                  var icon = new Icon(name);

                  if (element.has.size) 
                     icon.size = icon.width = icon.height = Std.parseInt(substitute(element.att.size));

                  if (element.has.width) 
                     icon.width = Std.parseInt(substitute(element.att.width));

                  if (element.has.height) 
                     icon.height = Std.parseInt(substitute(element.att.height));

                  if (element.name=="banner")
                     project.banners.push(icon);
                  else
                     project.icons.push(icon);

               case "source", "classpath", "cp", "classPath":
                  var path = "";

                  if (element.has.path) 
                     path = combine(extensionPath, substitute(element.att.path));
                  else
                     path = combine(extensionPath, substitute(element.att.name));
                  var fullPath = project.relocatePath(path);
                  project.classPaths.push( fullPath );
                  Log.verbose("Adding class path " + fullPath);

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

                  var path = "";
                  if (element.has.name)
                     path = combine(extensionPath, substitute(element.att.name));
                  else if (element.has.path)
                     path = combine(extensionPath, substitute(element.att.path));
                  else
                     Log.error("Template should have either a 'name' or a 'path'");

                  if (element.has.rename)
                  {
                     project.templateCopies.push( new TemplateCopy(path, substitute(element.att.rename) ) );
                  }
                  else
                  {
                     project.templatePaths.remove(path);
                     project.templatePaths.push(path);
                  }

               case "preloader":
                  // deprecated
                  project.app.preloader = substitute(element.att.name);

               case "android":
                  parseAndroidElement(element);

               case "output":
                  parseOutputElement(element);

               case "section":
                  parseXML(element, "", extensionPath);

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
                  var name = element.has.name ? substitute(element.att.name) : "";
                  if (name!="QuartzCore.framework")
                  {
                     var path = element.has.path ? substitute(element.att.path) : "";
                     var key = name!="" ? name : path;
                     if (key=="")
                        Log.error("dependency node should have a name and/or a path");
                     project.dependencies.set(key, new Dependency(name,path,extensionPath));
                  }

               case "engine":
                  project.engines.set(substitute(element.att.name),
                                      substitute(element.att.version));
               case "arch":
                  var arch = substitute(element.att.value);
                  switch(arch)
                  {
                     case "armv5":
                         project.addArch( Architecture.ARMV5);
                     case "armv6":
                         project.addArch( Architecture.ARMV6);
                     case "armv7":
                         project.addArch( Architecture.ARMV7);
                     case "arm64":
                         project.addArch( Architecture.ARM64);
                     case "x86":
                         project.addArch( Architecture.X86);
                     case "i386":
                         project.addArch( Architecture.I386);
                     case "x86_64":
                         project.addArch( Architecture.X86_64);
                     default:
                         Log.error("Unvalid architecture : " + arch);
                  }

               case "ios":
                  if (project.target == Platform.IOS || project.target == Platform.IOSVIEW ) 
                  {
                     if (element.has.deployment) 
                     {
                        var deployment = substitute(element.att.deployment);

                        // If it is specified, assume the dev knows what he is doing!
                        project.iosConfig.deployment = deployment;
                     }

                     if (element.has.binaries) 
                     {
                        var binaries = substitute(element.att.binaries);

                        switch(binaries) 
                        {
                           case "fat":
                              //project.addArch( Architecture.ARMV6);
                              project.addArch( Architecture.ARMV7);
                              project.addArch( Architecture.ARM64);

                           case "armv6":
                              project.addArch( Architecture.ARMV6);

                           case "armv7":
                              project.addArch( Architecture.ARMV7);

                           case "arm64":
                              project.addArch( Architecture.ARM64);
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
      Log.verbose("Parse " + projectFile + "...");
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

   public function gitver()
   {
      if (gitVersion==null)
      {
         var output = ProcessHelper.getOutput("git", [ "rev-list", "HEAD", "--count" ]);
         if (output.length!=1)
            Log.error("Could not identify git version: " + output );
         gitVersion = output[0];
      }
      
      return gitVersion;
   }

   private function substitute(string:String):String 
   {
      var newString = string;

      while(varMatch.match(newString)) 
      {
         newString = varMatch.matched(1);

         if (newString=="gitver:")
            newString = gitver();
         else if (newString.startsWith("haxelib:"))
         {
            newString = PathHelper.getHaxelib(new Haxelib(newString.substr(8)));
         }
         else
         {
            if (newString.indexOf(":")>=0)
               Log.error('Unknown function $newString');
            newString = project.getDef(newString);
         }

         if (newString == null) 
            newString = "";


         newString = varMatch.matchedLeft() + newString + varMatch.matchedRight();
      }

      return newString;
   }
}
