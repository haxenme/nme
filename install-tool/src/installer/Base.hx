package installer;

using StringTools;
import format.swf.Data;
import format.swf.Constants;
import format.mp3.Data;
import format.wav.Data;
import nme.text.Font;



import nme.display.BitmapData;



class Base
{
   var mDefines : Hash<String>;
   var mContext : Dynamic;
   var mIncludePath:Array<String>;
   var mHaxeFlags:Array<String>;
   var mCommand:String;
   var mTarget:String;
   var mNDLLs : Array<NDLL>;
   var mAssets : Array<Asset>;
   var mIcons : Array<Icon>;
   var mAllFiles :Array<String>;
   var NME:String;
   var mVerbose:Bool;
   var mDebug:Bool;
   var mFullClassPaths:Bool;
   var mInstallBase:String;


   var mBuildDir:String;
   var mOS:String;

   public function new()
   {
      mOS = neko.Sys.systemName();
   }

   public function process(inNME:String,
                       inCommand:String,
                       inDefines:Hash<String>,
                       inIncludePath:Array<String>,
                       inProjectFile:String,
                       inTarget:String,
                       inVerbose:Bool,
                       inDebug:Bool
                       )
   {
      if (inTarget=="iphone" && inCommand!="update")
      {
         trace("Command should be 'update' for iphone target");
         inCommand = "update";
      }
      NME = inNME;
      mDefines = inDefines;
      mIncludePath = inIncludePath;
      mTarget = inTarget;
      mHaxeFlags = [ "-D nme_install_tool" ];
      mCommand = inCommand;
      mVerbose = inVerbose;
      mDebug = inDebug;
      mNDLLs = [];
      mAssets = [];
      mAllFiles = [];
      mIcons = [];
      mInstallBase = "";

      // trace(NME);
      // trace(inCommand);

      setDefault("WIN_WIDTH","640");
      setDefault("WIN_HEIGHT","480");
      setDefault("WIN_ORIENTATION","");
      setDefault("WIN_FPS","60");
      setDefault("WIN_BACKGROUND","0xffffff");
      setDefault("WIN_HARDWARE","true");
      setDefault("WIN_RESIZEABLE","true");

      setDefault("APP_FILE","MyAplication");
      setDefault("APP_PACKAGE","com.example.myapp");
      setDefault("APP_VERSION","1.0");
      setDefault("APP_COMPANY","Example Inc.");

      setDefault("SWF_VERSION","9");

      setDefault("PRELOADER_NAME", "NMEPreloader");

      setDefault("BUILD_DIR","bin");

      mDefines.set("target_" + inTarget, "1");
      mDefines.set("target" , inTarget);

      var make_contents = neko.io.File.getContent(inProjectFile);
      var xml_slow = Xml.parse(make_contents);
      var xml = new haxe.xml.Fast(xml_slow.firstElement());
      mFullClassPaths = inTarget=="iphone";

      if (mFullClassPaths)
          mHaxeFlags.push("-cp " + neko.FileSystem.fullPath(".") );

      parseXML(xml,"");

      // Strip off 0x ....
      setDefault("WIN_FLASHBACKGROUND", mDefines.get("WIN_BACKGROUND").substr(2));
      setDefault("APP_VERSION_SHORT", mDefines.get("APP_VERSION").substr(2));

      if (mDefines.exists("NME_64"))
      {
         mHaxeFlags.push("-D HXCPP_M64");
         if (mOS=="Linux")
            mOS += "64";
      }

      mBuildDir = mDefines.get("BUILD_DIR");

      mContext = {};
      for(key in mDefines.keys())
         Reflect.setField(mContext,key, mDefines.get(key) );
      Reflect.setField(mContext,"ndlls", mNDLLs );
      Reflect.setField(mContext,"assets", mAssets );
      //trace(mDefines);

      if (inCommand=="uninstall")
      {
         uninstall();
      }
      else
      {
         mContext.HAXE_FLAGS = mHaxeFlags.length==0 ? "" : "\n" + mHaxeFlags.join("\n");

         if (inCommand=="test" || inCommand=="build" || inCommand=="rerun" ||inCommand=="installer" 
              || inCommand=="update" )
         {
            var do_build = inCommand=="build" || inCommand=="test" || inCommand=="installer";
            var do_run = (inCommand=="rerun" || inCommand=="test");
            var do_update = inCommand!="rerun";

            var hxml = mBuildDir + "/" + inTarget + "/haxe/" + (mDebug ? "debug" : "release") + ".hxml";
            var Target = inTarget.substr(0,1).toUpperCase() + inTarget.substr(1);
            if (do_update)
            {
                update();

                if (do_build)
                {
                   run("", "haxe", [hxml]);
                   build();
                }
            }
            if (do_run)
            {
               test();
            }

            if (inCommand=="installer")
            {
               var l = mInstallBase.length;
               if (l==0)
                  throw "Target does not support install_base for 'installer' option.";
               var files = new Array<String>();

               for(file in mAllFiles)
                  if (file.substr(0,l)==mInstallBase)
                     files.push(file.substr(l));

               run(mInstallBase, "tar", ["cvzf", mDefines.get("APP_FILE") + ".tgz"].concat(files) );
            }
         }
      }
   }

   function test() { throw "Test : Not implemented"; }
   function update() { throw "Update : Not implemented"; }
   function build() { throw "Build : Not implemented"; }
   function uninstall() { throw "Uninstall : Not implemented"; }

   public function isNewer(inFrom:String, inTo:String, inVerbose:Bool) : Bool
   {
      return InstallTool.isNewer(inFrom,inTo,inVerbose);
   }

   function Print(inString)
   {
      if (mVerbose)
        neko.Lib.println(inString);
   }

   public function copyIfNewer(inFrom:String, inTo:String, ioAllFiles:Array<String>,inVerbose:Bool)
   {
      InstallTool.copyIfNewer(inFrom, inTo, ioAllFiles, inVerbose);
   }


   function createIcon(inWidth:Int, inHeight:Int, inDest:String, inAddToAllFiles:Bool,
           inAddToAssets:String = "") : Bool
   {
      // Look for exact match ...
      for(icon in mIcons)
         if (icon.isSize(inWidth,inHeight))
         {
            var ext =  neko.io.Path.extension(icon.name).toLowerCase();
            if (ext=="png" )
            {
               mContext.HAS_ICON = true;
               if (inAddToAllFiles)
                  mAllFiles.push(inDest);
               if (inAddToAssets!="")
                  mAssets.push( new Asset(inDest, "image", inAddToAssets, "", mTarget) );
               copyIfNewer(icon.name,inDest,inAddToAllFiles?mAllFiles:[],mVerbose);
               return true;
            }
         }

      var bmp = getIconBitmap(inWidth,inHeight,inDest);
      if (bmp==null)
      {
         if (!neko.FileSystem.exists(inDest))
            return false;
      }
      else
      {
         var bytes = bmp.encode("png",0.95);
         bytes.writeFile(inDest);
      }

      if (inAddToAllFiles)
         mAllFiles.push(inDest);
      if (inAddToAssets!="")
        mAssets.push( new Asset(inDest, "image", inAddToAssets, "", mTarget) );
      mContext.HAS_ICON = true;
      return true;
   }


   function getIconBitmap(inWidth:Int, inHeight:Int, inTimedFile:String="", ?inBackground ) : BitmapData
   {
      var found:Icon = null;

      // Look for exact match ...
      for(icon in mIcons)
         if (icon.isSize(inWidth,inHeight))
         {
            mContext.HAS_ICON = true;
            if (inTimedFile!="" && !isNewer(icon.name,inTimedFile,mVerbose))
               return null;

            var bmp = nme.display.BitmapData.load(icon.name);
            // TODO: resize if required
            return bmp;
         }

      // Look for possible match ...
      if (found==null)
      {
         for(icon in mIcons)
            if (icon.matches(inWidth,inHeight))
            {
               found = icon;
               mContext.HAS_ICON = true;
               if (inTimedFile!="" && !isNewer(icon.name,inTimedFile,mVerbose))
                  return null;




               break;
            }
      }

      if (found==null)
         return null;

      var ext =  neko.io.Path.extension(found.name).toLowerCase();

      if (ext=="svg")
      {
         var bytes = nme.utils.ByteArray.readFile(found.name);
         var svg = new gm2d.svg.SVG2Gfx( Xml.parse(bytes.asString()) );

	      var shape = svg.CreateShape();
         var scale = inHeight/32;

         Print("Creating " + inWidth + "x" + inHeight + " icon from " + found.name );

         shape.scaleX = scale;
         shape.scaleY = scale;
         shape.x = (inWidth - 32*scale)/2;

         var bmp = new nme.display.BitmapData(inWidth,inHeight, true,
                           inBackground==null ? {a:0, rgb:0xffffff} : inBackground );

         bmp.draw(shape);

         return bmp;
      }
      else
      {
          throw "Unknown icon format : " + found.name;
      }
 
      return null;
   }

   public function isMac() { return InstallTool.isMac(); }
   public function isLinux() { return InstallTool.isLinux(); }
   public function isWindows() { return InstallTool.isWindows(); }
   public function isIphone() { return mTarget.substr(0,6)=="iphone"; }
   public function dotSlash() { return InstallTool.dotSlash(); }

   // ----- Android ---------------------------------------------------------------------------

   // --- Neko -----------------------------------------------------------

   // --- Cpp ---------------------------------------------------------------

   function PackBits(data:nme.utils.ByteArray,offset:Int, len:Int) : haxe.io.Bytes
   {
      var out = new haxe.io.BytesOutput();
      var idx = 0;
      while(idx<len)
      {
         var val = data[idx*4+offset];
         var same = 1;
         /*
          Hmmmm...
         while( ((idx+same) < len) && (data[ (idx+same)*4 + offset ]==val) && (same < 2) )
            same++;
         */
         if (same==1)
         {
            var raw = idx+120 < len ? 120 : len-idx;
            out.writeByte(raw-1);
            for(i in 0...raw)
            {
               out.writeByte( data[idx*4+offset] );
               idx++;
            }
         }
         else
         {
            out.writeByte( 257-same );
            out.writeByte(val);
            idx+=same;
         }
      }
      return out.getBytes();
   }
   function ExtractBits(data:nme.utils.ByteArray,offset:Int, len:Int) : haxe.io.Bytes
   {
      var out = new haxe.io.BytesOutput();
      for(i in 0...len)
         out.writeByte( data[i*4+offset] );
      return out.getBytes();
   }



   function createMacIcon(resource_dest:String)
   {
         var out = new haxe.io.BytesOutput();
         out.bigEndian = true;
         for(i in 0...2)
         {
            var s =  ([ 32, 48 ])[i];
            var code =  (["il32","ih32"])[i];
            var bmp = getIconBitmap(s,s);
            if (bmp!=null)
            {
               for(c in 0...4)
                  out.writeByte(code.charCodeAt(c));
               var n = s*s;
               var pixels = bmp.getPixels(new nme.geom.Rectangle(0,0,s,s));

               var bytes_r = PackBits(pixels,1,s*s);
               var bytes_g = PackBits(pixels,2,s*s);
               var bytes_b = PackBits(pixels,3,s*s);

               out.writeInt31(bytes_r.length + bytes_g.length + bytes_b.length + 8);
               out.writeBytes(bytes_r,0,bytes_r.length);
               out.writeBytes(bytes_g,0,bytes_g.length);
               out.writeBytes(bytes_b,0,bytes_b.length);

               var code =  (["l8mk","h8mk" ])[i];
               for(c in 0...4)
                  out.writeByte(code.charCodeAt(c));
               var bytes_a = ExtractBits(pixels,0,s*s);
               out.writeInt31(bytes_a.length + 8);
               out.writeBytes(bytes_a,0,bytes_a.length);
            }
         }
         var bytes = out.getBytes();
         if (bytes.length>0)
         {
            var filename = resource_dest + "/icon.icns";
            trace(filename);
            var file = neko.io.File.write( filename,true);
            file.bigEndian = true;
            for(c in 0...4)
               file.writeByte("icns".charCodeAt(c));
            file.writeInt31(bytes.length+8);
            file.writeBytes(bytes,0,bytes.length);
            file.close();
            mAllFiles.push(filename);
         }
 
   }

   function setWindowsIcon(inTmp:String, inExeName:String)
   {
      var name:String="";
      if (mDefines.exists("APP_ICO"))
         name = mDefines.get("APP_ICO");
      else
      {
         // Not quite working yet....
         return;

         var ico = new nme.utils.ByteArray();
         ico.bigEndian = false;
         ico.writeShort(0);
         ico.writeShort(1);
         ico.writeShort(1);

         for(size in [ 32 ])
         {
            var bmp = getIconBitmap(size,size);
            if (bmp==null)
               break;
            ico.writeByte(size);
            ico.writeByte(size);
            ico.writeByte(0); // palette
            ico.writeByte(0); // reserved
            ico.writeShort(1); // planes
            ico.writeShort(32); // bits per pixel
            ico.writeInt(108 + 4*size*size); // Data size
            var here = ico.length;
            ico.writeInt(here + 4); // Data offset

            ico.writeInt(108); // size (bytes)
            ico.writeInt(size);
            ico.writeInt(size);
            ico.writeShort(1);
            ico.writeShort(32);
            ico.writeInt(3); // Bit fields...
            ico.writeInt(size*size*4); // SIze...
            ico.writeInt(0); // res-x
            ico.writeInt(0); // res-y
            ico.writeInt(0); // cols
            ico.writeInt(0); // important
            // Red
            ico.writeByte(0); 
            ico.writeByte(0);
            ico.writeByte(0xff);
            ico.writeByte(0);
            // Green
            ico.writeByte(0); 
            ico.writeByte(0xff);
            ico.writeByte(0);
            ico.writeByte(0);
            // Blue
            ico.writeByte(0xff);
            ico.writeByte(0); 
            ico.writeByte(0);
            ico.writeByte(0);
            // Alpha
            ico.writeByte(0); 
            ico.writeByte(0);
            ico.writeByte(0);
            ico.writeByte(0xff);

            //LCS_WINDOWS_COLOR_SPACE
            ico.writeByte(0x20); 
            ico.writeByte(0x6e);
            ico.writeByte(0x69);
            ico.writeByte(0x57);

            for(j in 0...36)
               ico.writeByte(0);
            ico.writeInt(0);
            ico.writeInt(0);
            ico.writeInt(0);

            var bits = bmp.getPixels( new nme.geom.Rectangle(0,0,size,size) );
            ico.writeBytes(bits);
         }

         name = inTmp + "/icon.ico";
         neko.io.File.write(name,true);

         var file = neko.io.File.write( name,true);
         file.writeBytes(ico,0,ico.length);
         file.close();
      }

      run(".", NME + "\\ndll\\Windows\\ReplaceVistaIcon.exe", [ inExeName, name] );
   }



   function getExt()
   {
      return mOS=="Windows" ? ".exe" : "";
   }



   // --- GPH ---------------------------------------------------------------


   // --- iPhone ---------------------------------------------------------------


   // --- webOS ---------------------------------------------------------------

	
   // --- Flash ---------------------------------------------------------------

   // -------------------------------------------------

   function addAssets(inDest:String,inTarget:String)
   {
      // Make sure dir is there - even if empty
      if (inTarget=="iphone")
      {
         mkdir(inDest + "/assets");
      }

      for(asset in mAssets)
      {
         var src = asset.getSrc();
         var dest = asset.getDest(inDest,inTarget);
         mkdir(neko.io.Path.directory(dest));
         copyIfNewer(src,dest,mAllFiles,mVerbose);
         mAllFiles.push(dest);
      }
   }


   function run(inPath:String, inCommand:String, inArgs:Array<String>)
   {
      var where = inPath=="" ? "" : (" in " + inPath);
      var old = "";
      if (inPath!="")
      {
         Print("cd " + inPath);
         old = neko.Sys.getCwd();
         neko.Sys.setCwd(inPath);
      }

      Print(inCommand + " " + inArgs.join(" "));
      var result = neko.Sys.command(inCommand, inArgs);
      if (result==0 && mVerbose)
         neko.Lib.println("Ok.");

      if (old!="")
         neko.Sys.setCwd(old);

      if (result!=0)
         throw("Error running:" + inCommand + " " + inArgs.join(" ") + where );


   }

   static var mVarMatch = new EReg("\\${(.*?)}","");
   public function substitute(str:String) : String
   {
      while( mVarMatch.match(str) )
      {
         var sub = mDefines.get( mVarMatch.matched(1) );
         if (sub==null) sub="";
         str = mVarMatch.matchedLeft() + sub + mVarMatch.matchedRight();
      }

      return str;
   }
   public function substitutei(str:String) : Int
   {
      return Std.parseInt( substitute(str) );
   }

   public function substituteb(str:String) : Bool
   {
      var s = substitute(str);
      return s=="true" || s=="1";
   }




   function findIncludeFile(inBase:String) : String
   {
      if (inBase=="") return "";
     var c0 = inBase.substr(0,1);
     if (c0!="/" && c0!="\\")
     {
        var c1 = inBase.substr(1,1);
        if (c1!=":")
        {
           for(p in mIncludePath)
           {
              var name = p + "/" + inBase;
              if (neko.FileSystem.exists(name))
                 return name;
           }
           return "";
        }
     }
     if (neko.FileSystem.exists(inBase))
        return inBase;
      return "";
   }


   public function valid(inEl:haxe.xml.Fast,inSection:String) : Bool
   {
      if (inEl.x.get("if")!=null)
         if (!defined(inEl.x.get("if"))) return false;

      if (inEl.has.unless)
         if (defined(inEl.att.unless)) return false;

      if (inSection!="")
      {
         if (inEl.name!="section")
            return false;
         if (!inEl.has.id)
            return false;
         if (inEl.att.id!=inSection)
            return false;
      }

      return true;
   }

   public function defined(inString:String) : Bool
   {
      return mDefines.exists(inString);
   }
   



   function parseXML(inXML:haxe.xml.Fast,inSection :String)
   {
      for(el in inXML.elements)
      {
         if (valid(el,inSection))
         {
            switch(el.name)
            {
                case "set" : 
                   var name = el.att.name;
                   var value = substitute(el.att.value);
                   mDefines.set(name,value);
                case "unset" : 
                   var name = el.att.name;
                   mDefines.remove(name);
                case "setenv" : 
                   var name = el.att.name;
                   var value = substitute(el.att.value);
                   mDefines.set(name,value);
                   neko.Sys.putEnv(name,value);
                case "error" : 
                   var error = substitute(el.att.value);
                   throw(error);
                case "path" : 
                   var path = substitute(el.att.name);
                   var os = neko.Sys.systemName();
                   var sep = mDefines.exists("windows_host") ? ";" : ":";
                   neko.Sys.putEnv("PATH", path + sep + neko.Sys.getEnv("PATH"));
                    //trace(neko.Sys.getEnv("PATH"));

                case "include" : 
                   var name = substitute(el.att.name);
                   var full_name = findIncludeFile(name);
                   if (full_name!="")
                   {
                      var make_contents = neko.io.File.getContent(full_name);
                      var xml_slow = Xml.parse(make_contents);
                      var section = el.has.section ? el.att.section : "";

                      parseXML(new haxe.xml.Fast(xml_slow.firstElement()),section);
                   }
                   else if (!el.has.noerror)
                   {
                      throw "Could not find include file " + name;
                   }
                case "app" : 
                   appSettings(el);

                case "haxelib" : 
                   var lib =  substitute(el.att.name);
                   if (lib!="nme" || mTarget!="flash")
                      mHaxeFlags.push("-lib " + lib );

                case "ndll" : 
                   var ndll =substitute(el.att.name);
                   var haxelib = el.has.haxelib ? substitute(el.att.haxelib) : "";
                   mNDLLs.push(new NDLL(ndll, haxelib,
                      el.has.nekoapi ? substitute(el.att.nekoapi)!="" : false ) );
                   // Must statically link in some extra libs....
                   if (ndll=="nme" && isIphone())
                   {
                      for(extra in ["libcurl", "libpng", "libjpeg", "libz"] )
                         mNDLLs.push(new NDLL(extra, haxelib, false) );
                   }

                case "icon" : 
                   mIcons.push(new Icon(substitute(el.att.name),
                      el.has.width ? substitute(el.att.width) : "",
                      el.has.height ? substitute(el.att.height) : "" ) );

                case "classpath" : 
                   mHaxeFlags.push("-cp " + convertPath( substitute(el.att.name) ) );

                case "haxedef" : 
                   mHaxeFlags.push("-D " + substitute( substitute(el.att.name) ) );

                case "window" : 
                   windowSettings(el);

                case "assets" : 
                   readAssets(el);

                case "preloader" : 
                   readPreloader(el);

                case "section" : 
                   parseXML(el,"");
            }
         }
      }
   }

   function convertPath(inPath:String)
   {
      return mFullClassPaths ? neko.FileSystem.fullPath(inPath) : inPath;
   }

   function readPreloader(inXML:haxe.xml.Fast)
   {
      var name:String = substitute(inXML.att.name);
      mDefines.set("PRELOADER_NAME", name);
   }


   function readAssets(inXML:haxe.xml.Fast)
   {
      var type:String = inXML.has.type ? substitute(inXML.att.type) : "";
      for(el in inXML.elements)
      {
         var id= el.has.id ? substitute(el.att.id) : "";
         var embed= el.has.embed ? substitute(el.att.embed) : "";
         switch(el.name)
         {
            case "asset":
               var t = el.has.type ? substitute(el.att.type) : type;
               mAssets.push( new Asset( substitute(el.att.name),t,id, embed, mTarget ) );
            case "sound":
               mAssets.push( new Asset( substitute(el.att.name),"sound",id, embed, mTarget ) );
            case "music":
               mAssets.push( new Asset( substitute(el.att.name),"music",id, embed, mTarget ) );
            case "image":
               mAssets.push( new Asset( substitute(el.att.name),"image",id, embed, mTarget ) );
            case "font":
               mAssets.push( new Asset( substitute(el.att.name),"font",id, embed, mTarget ) );

         }
      }
   }
 

   function setDefault(inName:String, inValue:String)
   {
      if (!mDefines.exists(inName))
         mDefines.set(inName, inValue);
   }

   function appSettings(el:haxe.xml.Fast)
   {
      for(e in el.x.attributes())
      {
         var att = e;
         var name = "APP_" + att.toUpperCase();
         mDefines.set( name, substitute(el.att.resolve(att)) );
      }
      setDefault("APP_TITLE", mDefines.get("APP_FILE"));
      setDefault("APP_DESCRIPTION", mDefines.get("APP_TITLE"));
   }

   function windowSettings(el:haxe.xml.Fast)
   {
      for(e in el.x.attributes())
      {
         var att = e;
         var name = "WIN_" + att.toUpperCase();
         mDefines.set( name, substitute(el.att.resolve(att)) );
      }
   }



   public function cp_file(inSrcFile:String,inDestFile:String,inProcess:Bool = true)
   {
      var ext = neko.io.Path.extension(inSrcFile);
      if (inProcess && 
         (ext=="xml" || ext=="java" || ext=="hx" || ext=="hxml" || ext=="ini" || ext=="gpe" ||
             ext=="pbxproj" || ext=="plist" ) )
      {
         mAllFiles.push(inDestFile);
         Print("process " + inSrcFile + " " + inDestFile );
         var contents = neko.io.File.getContent(inSrcFile);
         var tmpl = new haxe.Template(contents);
         var result = tmpl.execute(mContext);
         var f = neko.io.File.write(inDestFile,true);
         f.writeString(result);
         f.close();
      }
      else
      {
         copyIfNewer(inSrcFile,inDestFile,mAllFiles,mVerbose);
      }
   }

   public function cp_recurse(inSrc:String,inDestDir:String,inProcess:Bool = true)
   {
      mkdir(inDestDir);

      var files = neko.FileSystem.readDirectory(inSrc);
      for(file in files)
      {
         if (file.substr(0,1)!=".")
         {
            var dest = inDestDir + "/" + file;
            var src = inSrc + "/" + file;
            if (neko.FileSystem.isDirectory(src))
               cp_recurse(src, dest, inProcess);
            else
               cp_file(src,dest, inProcess);
         }
      }
   }


   public function mkdir(inDir:String)
   {
      var parts = inDir.split("/");
      var total = "";
      for(part in parts)
      {
         if (part!="." && part!="")
         {
            if (total!="") total+="/";
            total += part;
            
            if (!neko.FileSystem.exists(total))
            {
               Print("mkdir " + total);
               neko.FileSystem.createDirectory(total);
            }
         }
      }
   }

}



