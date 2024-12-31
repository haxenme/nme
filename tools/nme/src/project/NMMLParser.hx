package;

import Lambda;
import haxe.xml.Fast;
import haxe.io.Path;
// Can't really use haxe_ver becaise it has been at 4 for over a year
#if !force_xml_access  // (haxe_ver < 4)
import haxe.xml.Fast in Access;
#else
import haxe.xml.Access;
#end
import sys.io.File;
import sys.FileSystem;
import NMEProject;
import IconType;
import platforms.Platform;
import nme.AlphaMode;
import BootType;

using StringTools;

class NMMLParser
{
   var project:NMEProject;
   var thisFile:String;
   var thisDir:String;

   static var gitVersion:String = null;

   static var varMatch = new EReg("\\${(.*?)}", "");

   static var TOOL_VERSION = 3;

   public function new(inProject:NMEProject, path:String, inWarnUnknown:Bool, ?xml:Access )
   {
      thisFile = path;
      project = inProject;
      process(path,inWarnUnknown,xml);
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

   function parseAnd(condition:String)
   {
      var someMatched = false;
      for(part in condition.split(" "))
      {
         var check = StringTools.trim(part);
         if (check!="")
         {
            if (!parseBool(part) && !project.hasDef(check))
               return false;
            someMatched = true;
         }
      }
      return someMatched;
   }

   function parseCondition(condition:String)
   {
      var good = false;
      for(part in condition.split("||"))
         if ( parseAnd(part) )
            return true;
      return false;
   }

   private function isValidElement(element:Access, section:String):Bool 
   {
      var ifVal = element.x.get("if");
      if (ifVal!=null)
         ifVal =substitute(ifVal);
      if (ifVal!=null && !parseCondition(ifVal))
         return false;

      var unlessVal = element.x.get("unless");
      if (unlessVal!=null)
         unlessVal = substitute(unlessVal);
      if (unlessVal!=null && parseCondition(unlessVal))
         return false;

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

   private function parseAppElement(element:Access):Void 
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

            case "bootType":
               var types = ["auto", "main", "new", "addStage", "mainCommandLine" ];
               var type = substitute(element.att.bootType);
               var typeId = types.indexOf(type);
               if (typeId<0)
                  Log.error('Invalid bootType "$type". Should be one of $types.');
               project.app.bootType = Type.createEnumIndex( BootType, typeId );


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

   private function parseWatchOSElement(element:Access, extensionPath:String):Void 
   {
      var watchOs = project.makeWatchOSConfig();

      new NMMLParser(watchOs, extensionPath, false, element);
   }


   public static function parseAlphaMode(alphaMode:String) : AlphaMode
   {
      switch(alphaMode.toLowerCase())
      {
         case "unmultiplied": return AlphaUnmultiplied;
         case "premultiplied": return AlphaIsPremultiplied;
         case "postprocess": return AlphaPostprocess;
         case "preprocess": return AlphaPreprocess;
         case "default": return AlphaDefault;
         default:
            throw "Invalid alpha mode : should be premultiplied/postprocess/preprocess/unmultiplied/default";
      }
      return null;
   }


   function getElementAlpha(element:Access, inDefault:AlphaMode)
   {
      if (element.has.alpha)
         return parseAlphaMode(substitute(element.att.alpha));
      return inDefault;
   }


   private function parseAssetsElement(element:Access, basePath:String = ""):Void 
   {
      var path = basePath;
      var targetPath = "";
      var glyphs = null;
      var type = null;
      var recurse = true;

      if (element.has.path) 
      {
         var namedPath = substitute(element.att.path);
         path = PathHelper.combine(basePath,namedPath);

         if (element.has.rename) 
            targetPath = substitute(element.att.rename);
         else
            targetPath = namedPath;
      }
      else if (element.has.from)
      {
         path = PathHelper.combine(basePath,substitute(element.att.from));

         if (element.has.rename) 
            targetPath = substitute(element.att.rename);
         else
            targetPath = "";
      }

      var assetsAlpha = getElementAlpha(element,AlphaDefault);

      path = project.relocatePath(path);

      var embed = project.defaultEmbedAssets;
      if (project.forceEmbedAssets)
         embed = true;
      else if (element.has.embed)
         embed = parseBool(substitute(element.att.embed));

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

            var asset = new Asset(path, targetPath, type, embed, assetsAlpha);
            asset.setId(id);

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

            parseAssetsElementDirectory(path, targetPath, include, exclude, type, embed, assetsAlpha, glyphs, recurse);
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
               var childType = type;
               var childGlyphs = glyphs;

               var childAlpha = getElementAlpha(childElement, assetsAlpha);

               if (childElement.has.rename) 
                  childTargetPath = childElement.att.rename;

               var childEmbed = embed;
               if (project.forceEmbedAssets)
                  childEmbed = true;
               else if (childElement.has.embed)
                  childEmbed = parseBool(substitute(childElement.att.embed));

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


               var asset = new Asset(path + childPath, targetPath + childTargetPath, childType, childEmbed, childAlpha);
               asset.setId(id);

               if (childGlyphs != null) 
                  asset.glyphs = childGlyphs;

               project.assets.push(asset);
            }
         }
      }
   }

   private function parseAssetsElementDirectory(path:String, targetPath:String, include:String, exclude:String, type:AssetType, embed:Bool, assetsAlpha:AlphaMode, glyphs:String, recursive:Bool):Void 
   {
      var files = FileSystem.readDirectory(path);

      if (targetPath != "") 
         targetPath += "/";

      for(file in files) 
      {
         if (FileSystem.isDirectory(path + "/" + file) && recursive) 
         {
            if (filter(file, [ "*" ], exclude.split("|"))) 
               parseAssetsElementDirectory(path + "/" + file, targetPath + file, include, exclude, type, embed, assetsAlpha, glyphs, true);
         }
         else
         {
            if (filter(file, include.split("|"), exclude.split("|"))) 
            {
               var asset = new Asset(path + "/" + file, targetPath + file, type, embed, assetsAlpha);

               if (glyphs != null) 
                  asset.glyphs = glyphs;

               project.assets.push(asset);
            }
         }
      }
   }

   private function parseAndroidElement(element:Access):Void 
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

      if (element.has.addV4Compat)
         project.androidConfig.addV4Compat = parseBool(element.att.addV4Compat);

      if (element.has.universalApk)
         project.androidConfig.universalApk = parseBool(element.att.universalApk);
 
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
                  var permission = new AndroidPermission(value);
                  if (childElement.has.required)
                      permission.required = substitute(childElement.att.required);
                  if (childElement.has.maxSdkVersion)
                      permission.maxSdkVersion = substitute(childElement.att.maxSdkVersion);
                  if (childElement.has.usesPermissionFlags)
                      permission.usesPermissionFlags = substitute(childElement.att.usesPermissionFlags);
                  permission.update();

                  project.androidConfig.appPermission.push(permission);

               case "appFeature":
                  project.androidConfig.appFeature.push(
                      new AndroidFeature(value, childElement.has.required ? substitute(childElement.att.required) : "") );
               case "appIntent":
                  project.androidConfig.appIntent.push(value);

               case "gameActivityViewBase":
                  project.androidConfig.gameActivityViewBase = value;

               case "gameActivityBase":
                  project.androidConfig.gameActivityBase = value;
               
               case "abi":
                  project.androidConfig.ABIs.push(value);

               default:
                  Log.error("Unknown android attribute " + childElement.name);
            }
         }
      }
   }

   private function parseWinrtElement(element:Access):Void 
   {
      for(childElement in element.elements) 
      {
         if (isValidElement(childElement, ""))
         {
            var value = substitute(childElement.att.value);
            switch(childElement.name) 
            {
               case "appCapability":
                  project.winrtConfig.appCapability.push(
                      new WinrtCapability(value, childElement.has.namespace  ? substitute(childElement.att.namespace) : "") );
               case "packageDependency":
                  project.winrtConfig.packageDependency.push(
                      new WinrtPackageDependency(value, substitute(childElement.att.minversion), substitute(childElement.att.publisher) ) );
               default:
                  Log.error("Unknown winrt attribute " + childElement.name);
            }
         }
      }
   }


   private function parseOutputElement(element:Access):Void 
   {
      if (element.has.name) 
         project.app.file = substitute(element.att.name);

      if (element.has.path) 
         project.app.binDir = substitute(element.att.path);

      if (element.has.resolve("swf-version")) 
         project.app.swfVersion = Std.parseFloat(substitute(element.att.resolve("swf-version")));
   }

   private function parseXML(xml:Access, section:String, extensionPath:String, inWarnUnknown):Void
   {
      parseRelationally(xml, section, extensionPath);
      parseSequentially(xml, section, extensionPath, inWarnUnknown);
   }

   function parseRelationally(xml:Access, section:String, extensionPath:String):Void
   {
      for(element in xml.elements)
         if (isTemplate(element,section))
             parseTemplate(element,extensionPath);

      /*
      var elements:Array<Access> = [for(element in xml.elements) element];
      
      var templates:List<Access> = Lambda.filter(elements, function(element) {
         return isTemplate(element, section);
      });
      
      Lambda.iter(templates, function(element) {
         return parseTemplate(element,extensionPath);
      });
      */
   }

   private function isTemplate(element:Access, section:String):Bool {
      if(isValidElement(element, section)) {
         if(element.name == "template"
         || element.name == "templatePath"
         || element.name == "templateCopy") {
            return true;
         }
      }
      return false;
   }

   function parseTemplate(element:Access, extensionPath:String):Void {
      var path = "";
      if (element.has.name)
         path = combine(extensionPath, substitute(element.att.name));
      else if (element.has.path)
         path = combine(extensionPath, substitute(element.att.path));
      else
         Log.error("Template should have either a 'name' or a 'path'");

      if (element.has.to)
      {
         project.templateCopies.push( new TemplateCopy(path, substitute(element.att.to) ) );
      }
      else if (element.has.rename)
      {
         project.templateCopies.push( new TemplateCopy(path, substitute(element.att.rename) ) );
      }
      else if (element.name=="templateCopy")
      {
         if (!element.has.name)
            Log.error("templateCopy should a 'name' attribute");
         project.templateCopies.push( new TemplateCopy(path, substitute(element.att.name) ) );
      }
      else
      {
         project.templatePaths.remove(path);
         project.templatePaths.push(path);
      }
   }

   function dumpVars(title:String, values:Map<String,String>)
   {
      Sys.println(title);
      for(k in values.keys())
         Sys.println("  " + k + "=" + values.get(k) );
   }

   private function parseSequentially(xml:Access, section:String, extensionPath:String, inWarnUnknown):Void 
   {
      for(element in xml.elements) 
      {
         var isValid = isValidElement(element, section);
         if (isValid) 
         {
            switch(element.name) 
            {
               case "set":
                  if (!element.has.name)
                  {
                     dumpVars("HaxeDefs",project.haxedefs);
                     dumpVars("LocalDefs",project.localDefines);
                     dumpVars("Environment",project.environment);
                  }
                  else
                  {
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
                  }

               case "unset":

                  project.haxedefs.remove(element.att.name);
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

               case "UIStageViewHead":
                  project.iosConfig.stageViewHead += substitute(element.att.value) + "\n";

               case "UIStageViewInit":
                  project.iosConfig.stageViewInit += substitute(element.att.value) + "\n";


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

                  var path = substitute(element.has.path ? element.att.path : element.att.name); 

                  var include = findIncludeFile(combine(extensionPath, path));

                  if (include != null && include != "" && FileSystem.exists(include)) 
                  {
                     new NMMLParser(project,include, inWarnUnknown);
                     var dir = Path.directory(include);
                     if (dir != "")
                        project.classPaths.push(include);
                  }
                  else if (!element.has.noerror) 
                  {
                     Log.error("Could not find include file \"" + path + "\"");
                  }

               case "buildExtra":
                  var path = substitute(element.has.path ? element.att.path : element.att.name); 
                  project.buildExtraFiles.push( combine(extensionPath, path) );


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
                 var nocopy = element.has.nocopy && parseBool(substitute(element.att.nocopy));

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
                     else if(extensionPath == "")
                         haxelib = name;
                 }
                 var base = extensionPath;
                 if (haxelib!="")
                 {
                    var lib = project.addLib(haxelib,version,nocopy,isStatic);
                    base = lib.getBase();
                 }
                 if (name!="lime" && name!="openfl")
                    project.addNdll(name, base, isStatic, haxelib, nocopy);



               case "lib", "haxelib":
                  var name = substitute(element.att.name);

                  var version = "";
                  if (element.has.version) 
                     version = substitute(element.att.version);

                  var isStatic:Null<Bool> = element.x.exists("static") ? parseBool(substitute(element.x.get("static"))) : null;

                  var nocopy = element.has.nocopy && parseBool(substitute(element.att.nocopy));
                  project.addLib(name,version,nocopy,isStatic);
 

               case "launchImage", "splashScreen":

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

                  if (element.has.type) 
                  {
                     var type = substitute(element.att.type);
                     switch(type)
                     {
                        case "normal": icon.type = IconNormal;
                        case "fg": icon.type = IconFg;
                        case "bg": icon.type = IconBg;
                        case "mono": icon.type = IconMono;
                        default:
                           throw "Icon type should ne normal/fg/bg/mono";
                     }
                  }

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

               case "fileAssociation":
                  if (!element.has.extension) 
                     Log.error("fileAssociation element should have extension attribute");
                  if (!element.has.description) 
                     Log.error("fileAssociation element should have description attribute");
                  project.addFileAssociation(
                       substitute(element.att.extension), substitute(element.att.description) );

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
                  if(!project.skipAssets)
                     parseAssetsElement(element, extensionPath);

               case "watchos":
                  parseWatchOSElement(element, extensionPath);

               case "library":
                  if (element.has.path)
                  {
                     var name = substitute(element.att.path);
                     var id = element.has.id ? substitute(element.att.id) : new Path(name).file;
                     var path = project.relocatePath(name);
                     var embed = project.defaultEmbedAssets;
                     if (project.forceEmbedAssets)
                        embed = true;
                     else if (element.has.embed)
                        embed = parseBool(substitute(element.att.embed));

                     var asset = new Asset(path, id, null, embed);
                     //asset.id = id;
                     project.assets.push(asset);
                  }
                  else
                  {
                     Log.verbose("Ignoring library handler definition.");
                  }

               case "ssl":

                  //if (wantSslCertificate())
                     //parseSsl(element);

               case "preloader":
                  // deprecated
                  project.app.preloader = substitute(element.att.name);

               case "android":
                  parseAndroidElement(element);

               case "winrt":
                  parseWinrtElement(element);

               case "output":
                  parseOutputElement(element);

               case "section":
                  parseXML(element, "", extensionPath, inWarnUnknown);

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
                     var sourceTree = element.has.sourceTree ? substitute(element.att.sourceTree) : "";
                     var key = name!="" ? name : path;
                     if (key=="")
                        Log.error("dependency node should have a name and/or a path");
                      var dependency = new Dependency(name, path, extensionPath);
                      dependency.sourceTree = sourceTree;
                      project.dependencies.set(key, dependency);
                  }

                case "otherLinkerFlags":
                    var value = element.has.value ? substitute(element.att.value) : "";
                    project.otherLinkerFlags.push(value);
                case "customIOSProperty":
                    var key = element.has.key ? substitute(element.att.key) : "";
                    var value = element.has.value ? substitute(element.att.value) : "";
                    project.customIOSproperties.set(key, value);

                case "customIOSBlock":
                    var value = element.has.value ? substitute(element.att.value) : "";
                    project.customIOSBlock.push(value);
                case "frameworkSearchPaths":
                    var value = element.has.value ? substitute(element.att.value) : "";
                    var full = FileSystem.fullPath(value);
                    project.frameworkSearchPaths.push(full);

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
                        project.haxedefs.set("HXCPP_IOS_MIN_VERSION", deployment);

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

                     if (element.has.sourceFlavour) 
                        project.iosConfig.sourceFlavour = substitute(element.att.sourceFlavour);

                     if (element.has.sourceFlavor) 
                        project.iosConfig.sourceFlavour = substitute(element.att.sourceFlavor);

                     if (element.has.compiler) 
                        project.iosConfig.compiler = substitute(element.att.compiler);

                     if (element.has.resolve("prerendered-icon")) 
                        project.iosConfig.prerenderedIcon = (substitute(element.att.resolve("prerendered-icon")) == "true");

                     if (element.has.resolve("linker-flags")) 
                        project.iosConfig.linkerFlags = project.iosConfig.linkerFlags.concat(substitute(element.att.resolve("linker-flags")).split(" "));
                     if (element.has.useLaunchScreen) 
                        project.iosConfig.useLaunchScreen = parseBool(element.att.useLaunchScreen);

                  }
               default:
                  if (inWarnUnknown && !isTemplate(element,section))
                     Log.verbose("UNKNOWN project element " + element.name );
            }
         }
      }
   }

   private function parseWindowElement(element:Access):Void 
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

            case "foreground":
               value = StringTools.replace(value, "#", "");
               if (value.indexOf("0x") == -1) 
                  value = "0x" + value;
               project.window.foreground = Std.parseInt(value);


            case "orientation":
               var orientation = Reflect.field(Orientation, Std.string(value).toUpperCase());
               if (orientation != null) 
                  project.window.orientation = orientation;

            case "scaleMode":
               switch(value.toLowerCase())
               {
                  case "native" : project.window.scaleMode = ScaleNative;
                  case "game" : project.window.scaleMode = ScaleGame;
                  case "ui" : project.window.scaleMode = ScaleUiScaled;
                  case "pixels" : project.window.scaleMode = ScaleGamePixels;
                  case "stretch" : project.window.scaleMode = ScaleGameStretch;
                  case "centre","center" : project.window.scaleMode = ScaleCentre;
                  default:
                      throw "Window scaleMode should be native/centre/game/ui/pixels or stretch";
               }

            case "height", "width", "fps", "antialiasing":
               if (Reflect.hasField(project.window, name)) 
                  Reflect.setField(project.window, name, Std.parseInt(value));

            case "parameters", "ui":
               if (name=="ui" && value=="spritekit")
                  project.haxedefs.set("nme_spritekit", "1");
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

   public function process(projectFile:String, inWarnUnkown:Bool,inXml:Access):Void 
   {
      var xml = inXml;
      var extensionPath = "";

      if (xml==null)
      {
         try 
         {
            xml = new Access(Xml.parse(File.getContent(projectFile)).firstElement());
   
         }
         catch(e:Dynamic) 
         {
            Log.error("\"" + projectFile + "\" contains invalid XML data", e);
         }
      }

      extensionPath = Path.directory(projectFile);

      parseXML(xml, "", extensionPath, inWarnUnkown);
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
         else if (newString=="this_dir")
         {
            var d  = Path.directory(thisFile);
            if (!PathHelper.isAbsolute(d))
                newString = Path.normalize( Sys.getCwd() +"/" + d);
            else
                newString = d;
         }
         else if (newString.startsWith("toolversion:"))
         {
            var requiredVersion = Std.parseInt( newString.substr(12) );
            newString = requiredVersion <= TOOL_VERSION ? "true" : "false";
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
