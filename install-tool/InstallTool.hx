import format.swf.Data;
import format.swf.Constants;
import format.mp3.Data;
import format.wav.Data;

using StringTools;

class Asset
{
   public var name:String;
   public var dest:String;
   public var type:String;
   public var id:String;
   public var flatName:String;
   public var hash:String;
   public var flashClass:String;
   public var embed:Bool;

   static var usedRes = new Hash<Bool>();


   public function new(inName:String, inDest:String, inType:String,inID:String,
         inEmbed:String)
   {
      name = inName;
      dest = inDest;
      type = inType;
      embed = inEmbed=="" || inEmbed=="1" || inEmbed=="true";
      hash = InstallTool.getID();
      id = inID=="" ? name : inID;
      var chars = id.toLowerCase();
      flatName ="";
      for(i in 0...chars.length)
      {
         var code = chars.charCodeAt(i);
         if ( (i>0 && code >= "0".charCodeAt(0) && code<="9".charCodeAt(0) ) ||
              (code >= "a".charCodeAt(0) && code<="z".charCodeAt(0) ) ||
                (code=="_".charCodeAt(0)) )
             flatName += chars.charAt(i);
         else
             flatName += "_";
      }
      if (flatName=="")
         flatName="_";
      while( usedRes.exists(flatName) )
         flatName += "_";
      usedRes.set(flatName,true);
      if (type=="music" || type=="sound")
         flashClass = "flash.media.Sound";
      else if (type=="image")
         flashClass = "flash.display.BitmapData";
      else
         flashClass = "flash.utils.ByteArray";
   }

   function getExtension()
   {
      return "." + neko.io.Path.extension(name);
   }

   public function getSrc()
   {
      return name;
   }

   public function getDest(inBase:String,inTarget:String)
   {
      if (inTarget=="android")
      {
         switch(type)
         {
            case "sound":
              return inBase + "/" + dest + "/res/raw/" + flatName + getExtension();
            case "music":
              return inBase + "/" + dest + "/res/raw/" + flatName + getExtension();
            default:
              return inBase + "/" + dest + "/assets/" + id;
         }
      }

      if (inTarget=="iphone")
         return inBase + "/" + dest + "/assets/" + id;

      return inBase + "/" + dest + "/" + id;
   }

   static var swfAddetID = 1000;
   function nextAssetID()
   {
      return swfAddetID++;
   }

   public function toSwf(outTags:Array<SWFTag>)
   {
      if (!embed)
         return false;
      var id=nextAssetID( );
      var bytes = neko.io.File.getBytes(name);

      if (type=="music" || type=="sound")
      {
         var src = name;
         var ext = neko.io.Path.extension(src);
         if (ext!="mp3" && ext!="wav")
         {
            for( e in ["wav", "mp3"] )
            {
               src = name.substr(0, name.length - ext.length) + e;
               if (neko.FileSystem.exists(src))
                  break;
            }
         }
         if (!neko.FileSystem.exists(src))
            throw "Could not find mp3/wav source: " + src;
         var ext = neko.io.Path.extension(src);

         var input = neko.io.File.read(src, true);
         if (ext=="mp3")
         {
            // Code lifted from "samhaxe"
            var r = new format.mp3.Reader(input);
            var mp3 = r.read();
            if (mp3.frames.length == 0)
               throw "No frames found in mp3: " + src;

            // Guess about the format based on the header of the first frame found
            var fr0 = mp3.frames[0];
            var hdr0 = fr0.header;

            // Verify Layer3-ness
            if (hdr0.layer != Layer.Layer3)
               throw "Only Layer-III mp3 files are supported by flash. File " +
                    src + " is: " + format.mp3.Tools.getFrameInfo(fr0);

            // Check sampling rate
            var flashRate = switch (hdr0.samplingRate)
            {
               case SR_11025: SR11k;
               case SR_22050: SR22k;
               case SR_44100: SR44k;
               default:
                  throw "Only 11025, 22050 and 44100 Hz mp3 files are supported by flash. File " +
                     src + " is: " + format.mp3.Tools.getFrameInfo(fr0);
            }

            var isStereo = switch (hdr0.channelMode)
            {
               case Stereo, JointStereo, DualChannel: true;
               case Mono: false;
            };

            // Should we do this? For now, let's do.
            var write_id3v2 = true;

            var rawdata = new haxe.io.BytesOutput();
            (new format.mp3.Writer(rawdata)).write(mp3, write_id3v2);
            var dataBytes = rawdata.getBytes();

            var snd =
            {
                sid : id,
                format : SFMP3,
                rate : flashRate,
                is16bit : true,
                isStereo : isStereo,
                samples : haxe.Int32.ofInt(mp3.sampleCount),
                data : SDMp3(0, dataBytes)
            };
      
            outTags.push( TSound(snd) );
         }
         else
         {
            var r = new format.wav.Reader(input);
            var wav = r.read();
            var hdr = wav.header;

            if (hdr.format != WF_PCM) 
               throw "Only PCM (uncompressed) wav files can be imported.";

            // Check sampling rate
            var flashRate = switch (hdr.samplingRate)
            {
               case  5512: SR5k;
               case 11025: SR11k;
               case 22050: SR22k;
                     case 44100: SR44k;
               default:
                  throw "Only 5512, 11025, 22050 and 44100 Hz wav files are supported by flash. Sampling rate of '" + src + "' is: " + hdr.samplingRate;
            }

            var isStereo = switch(hdr.channels)
            {
               case 1: false;
               case 2: true;
               default: throw "Number of channels should be 1 or 2, but for '" + src + "' it is " + hdr.channels;
            }
       
            var is16bit = switch(hdr.bitsPerSample)
            {
               case 8: false;
               case 16: true;
               default: throw "Bits per sample should be 8 or 16, but for '" + src + "' it is " + hdr.bitsPerSample;
            }

            var sampleCount = Std.int(wav.data.length / (hdr.bitsPerSample / 8));


            var snd : format.swf.Sound =
            {
               sid : id,
               format : SFLittleEndianUncompressed,
               rate : flashRate,
               is16bit : is16bit,
               isStereo : isStereo,
               samples : haxe.Int32.ofInt(sampleCount),
               data : SDRaw(wav.data)
            }

            outTags.push(TSound(snd));
         }
         input.close();
      }
      else if (type=="image")
      {
         var src = name;
         var ext = neko.io.Path.extension(src).toLowerCase();
         if (ext=="jpg" || ext=="png")
         {
             id = nextAssetID();
             var bytes: haxe.io.Bytes;
             try { bytes = neko.io.File.read(src, true).readAll(); }
             catch (e : Dynamic) { throw "Could not load image file: " + src; }

             outTags.push( TBitsJPEG(id,JDJPEG2(bytes)) );

         }
         else
            throw("Unknown image type:" + src );
      }
      else
      {
         outTags.push( TBinaryData(id,bytes) );
      }

      outTags.push( TSymbolClass( [ {cid:id, className:"NME_" + flatName} ] ) );
      return true;
   }
}



class NDLL
{
   public var name:String;
   public var haxelib:String;
   public var srcDir:String;
   public var needsNekoApi:Bool;
   public var hash:String;

   public function new(inName:String, inHaxelib:String,inNeedsNekoApi:Bool)
   {
      name = inName;
      haxelib = inHaxelib;
      srcDir = "";
      hash = InstallTool.getID();
      needsNekoApi = inNeedsNekoApi;

      if (haxelib!="")
         srcDir = getHaxelib(haxelib);
   }

   static public function getHaxelib(inLibrary:String)
   {
      var proc = new neko.io.Process("haxelib", ["path", inLibrary ]);
      var result = "";
      try{
         while(true)
         {
            var line = proc.stdout.readLine();
            if (line.substr(0,1)!="-")
               result = line;
      }
      } catch (e:Dynamic) { };
      proc.close();
      //trace("Found " + haxelib + " at " + srcDir );
      if (result=="")
         throw("Could not find haxelib path  " + inLibrary + " - perhaps you need to install it?");
      return result;
   }

   public function copy(inPrefix:String, inDir:String, inCPP:Bool, inVerbose:Bool, ioAllFiles:Array<String>,?inOS:String)
   {
      var src=srcDir;
      var suffix = ".ndll";
      if (src=="")
      {
         if (inCPP)
         {
            src = getHaxelib("hxcpp") + "/bin/" +inPrefix;
            suffix = switch(inOS==null ? InstallTool.mOS : inOS)
               {
                  case "Windows","Windows64" : ".dll";
                  case "Linux","Linux64" : ".dso";
                  case "Mac","Mac64" : ".dylib";
                  default: ".so";
               };
            if (inOS=="iphoneos" || inOS=="iphonesim")
               src += "lib";
         }
         else
            src = InstallTool.getNeko();
      }
      else
      {
         src += "/ndll/" + inPrefix;
         if (inOS=="android") suffix = ".so";
      }

      if (inOS=="iphoneos" || inOS=="iphonesim")
         suffix = "." + inOS + ".a";

      src = src + name + suffix;
      if (!neko.FileSystem.exists(src))
      {
         throw ("Could not find ndll " + src + " required by project" );
      }
      var slash = src.lastIndexOf("/");
      var dest = inDir + "/" + src.substr(slash+1);
      InstallTool.copyIfNewer(src,dest,ioAllFiles,inVerbose);
   }
}

class InstallTool
{
   var mDefines : Hash<String>;
   var mContext : Dynamic;
   var mIncludePath:Array<String>;
   var mHaxeFlags:Array<String>;
   var mCommand:String;
   var mTarget:String;
   var mNDLLs : Array<NDLL>;
   var mAssets : Array<Asset>;
   var mAllFiles :Array<String>;
   var NME:String;
   var mVerbose:Bool;
   var mDebug:Bool;
   var mFullClassPaths:Bool;
   var mInstallBase:String;

   static var mID = 1;
   public static var mOS:String = neko.Sys.systemName();

   var mBuildDir:String;

   public function new(inNME:String,
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
      setDefault("APP_ICON","");
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
         switch(inTarget)
         {
            case "android":
               uninstallAndroid();
         }
      }
      else
      {
         mContext.HAXE_FLAGS = mHaxeFlags.length==0 ? "" : "\n" + mHaxeFlags.join("\n");

         if (inCommand=="test" || inCommand=="build" || inCommand=="rerun" ||inCommand=="installer" 
              || inCommand=="update" )
         {
            var build = inCommand=="build" || inCommand=="test" || inCommand=="installer";
            var do_run = (inCommand=="rerun" || inCommand=="test");
            var update = inCommand!="rerun";

            var hxml = mBuildDir + "/" + inTarget + "/haxe/" + (mDebug ? "debug" : "release") + ".hxml";
            var Target = inTarget.substr(0,1).toUpperCase() + inTarget.substr(1);
            if (update)
            {
                var update_func = Reflect.field(this,"update" + Target);
                if (update_func==null)
                   trace("Could not find update function for target " + Target );
                else
                   Reflect.callMethod(this,update_func,[]);

                if (build)
                {
                    run("", "haxe", [hxml]);
                    if (build)
                    {
                       var build_func = Reflect.field(this,"build" + Target);
                       if (build_func==null)
                          trace("Could not find build function for target " + Target );
                       else
                          Reflect.callMethod(this,build_func,[]);
                    }
                }
            }
            if (do_run)
            {
               var run_func = Reflect.field(this,"run" + Target);
               Reflect.callMethod(this,run_func,[]);
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

   static public function getID()
   {
      return StringTools.hex(mID++,8);
   }
 
   static public function getNeko()
   {
      var n = neko.Sys.getEnv("NEKO_INSTPATH");
      if (n==null || n=="")
         n = neko.Sys.getEnv("NEKO_INSTALL_PATH");
      if (n==null || n=="")
         n = neko.Sys.getEnv("NEKOPATH");
      if (n==null || n=="")
      {
         if (isWindows())
           n = "C:/Motion-Twin/neko";
         else
           n = "/usr/lib/neko";
      }
      return n + "/";
   }

   function Print(inString)
   {
      if (mVerbose)
        neko.Lib.println(inString);
   }

   public static function isMac() { return mOS.substr(0,3)=="Mac"; }
   public static function isLinux() { return mOS.substr(0,5)=="Linux"; }
   public static function isWindows() { return mOS.substr(0,3)=="Win"; }
   public static function dotSlash() { return isWindows() ? ".\\" : "./"; }

   // ----- Android ---------------------------------------------------------------------------

   function updateAndroid()
   {
      var dest = mBuildDir + "/android/project";

      mkdir(dest);
      cp_recurse(NME + "/install-tool/android/template",dest);

      var pkg = mDefines.get("APP_PACKAGE");
      var parts = pkg.split(".");
      var dir = dest + "/src/" + parts.join("/");
      mkdir(dir);
      cp_file(NME + "/install-tool/android/MainActivity.java", dir + "/MainActivity.java");

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/android/haxe");
      cp_recurse(NME + "/install-tool/android/hxml",mBuildDir + "/android/haxe");

      for(ndll in mNDLLs)
         ndll.copy("Android/lib", dest + "/libs/armeabi", true, mVerbose, mAllFiles, "android");

      var icon = mDefines.get("APP_ICON");
      if (icon!="")
         copyIfNewer(icon, dest + "/res/drawable-mdpi/icon.png",mAllFiles,mVerbose);

   }

   function buildAndroid()
   {
      var ant:String = mDefines.get("ANT_HOME");
      if (ant=="" || ant==null)
      {
         //throw("ANT_HOME not defined.");
         ant = "ant";
      }
      else
         ant += "/bin/ant";

      var dest = mBuildDir + "/android/project";

      addAssets(dest,"android");

      var build = mDefines.exists("KEY_STORE") ? "release" : "debug";
      run(dest, ant, [build] );
   }


   function getAdb()
   {
      var adb = mDefines.get("ANDROID_SDK") + "/tools/adb";
      if (mDefines.exists("windows_host"))
         adb += ".exe";
      if (!neko.FileSystem.exists(adb) )
      {
         adb = mDefines.get("ANDROID_SDK") + "/platform-tools/adb";
         if (mDefines.exists("windows_host"))
            adb += ".exe";
      }
      return adb;
   }

   function runAndroid()
   {
      var build = mDefines.exists("KEY_STORE") ? "release" : "debug";
      var apk = mBuildDir + "/android/project/bin/" + mDefines.get("APP_FILE")+ "-" + build+".apk";
      var adb = getAdb();

      run("", adb, ["install", "-r", apk] );

      var pak = mDefines.get("APP_PACKAGE");
      run("", adb, ["shell", "am start -a android.intent.action.MAIN -n " + pak + "/" +
          pak +".MainActivity" ]);
      run("", adb, ["logcat", "*"] );
   }


   function uninstallAndroid()
   {
      var adb = getAdb();
      var pak = mDefines.get("APP_PACKAGE");

      run("", adb, ["uninstall", pak] );
   }

   // --- Neko -----------------------------------------------------------

   function updateNeko()
   {
      var dest = mBuildDir + "/neko/" + mOS + "/";
      var dot_n = dest+"/"+mDefines.get("APP_FILE")+".n";
      mContext.NEKO_FILE = dot_n;

      mkdir(dest);

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/neko/haxe");
      cp_recurse(NME + "/install-tool/neko/hxml",mBuildDir + "/neko/haxe");

      var needsNekoApi = false;
      for(ndll in mNDLLs)
      {
         ndll.copy( mOS + "/", dest, false, mVerbose, mAllFiles );
         if (ndll.needsNekoApi)
            needsNekoApi = true;
      }
      if (needsNekoApi)
      {
         var src = NDLL.getHaxelib("hxcpp") + "/bin/" + mOS + "/nekoapi.ndll";
         InstallTool.copyIfNewer(src,dest + "/nekoapi.ndll",mAllFiles,mVerbose);
      }

      var icon = mDefines.get("APP_ICON");
      if (icon!="")
         copyIfNewer(icon, dest + "/icon.png",mAllFiles,mVerbose);

      var neko = getNeko();
      if (mOS=="Windows")
      {
         copyIfNewer(neko + "gc.dll", dest + "/gc.dll",mAllFiles,mVerbose);
         copyIfNewer(neko + "neko.dll", dest + "/neko.dll",mAllFiles,mVerbose);
      }

      addAssets(dest,"neko");
   }


   function buildNeko()
   {
      var dest = mBuildDir + "/neko/" + neko.Sys.systemName()  + "/";
      run(dest,"nekotools",["boot",mDefines.get("APP_FILE")+".n"]);
   }

   function runNeko()
   {
      var dest = mBuildDir + "/neko/" + neko.Sys.systemName() + "/";

      run(dest, "neko" , [ mDefines.get("APP_FILE") + ".n"  ] );
   }

   // --- Cpp ---------------------------------------------------------------

   function getCppContentDest()
   {
      return isMac() ? getCppDest() + "/Contents" : getCppDest();
   }

   function getCppDest()
   {
      if (isMac())
         return mBuildDir + "/cpp/" + mOS + "/" + mDefines.get("APP_FILE") + ".app";

      return mBuildDir + "/cpp/" + mOS + "/" + mDefines.get("APP_FILE");
   }

   function updateCpp()
   {
      mInstallBase = mBuildDir + "/cpp/" + mOS + "/";

      var dest = getCppDest();
      mContext.CPP_DIR = mBuildDir + "/cpp/bin";

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/cpp/haxe");
      cp_recurse(NME + "/install-tool/cpp/hxml",mBuildDir + "/cpp/haxe");

      var content_dest = getCppContentDest();
      var exe_dest = content_dest + (isMac() ? "/MacOS" : "" );
      mkdir(exe_dest);

      for(ndll in mNDLLs)
         ndll.copy( mOS + "/", exe_dest, true, mVerbose, mAllFiles );

      var icon = mDefines.get("APP_ICON");
      if (isMac())
      {
         cp_file(NME + "/install-tool/mac/Info.plist", content_dest + "/Info.plist",true);

         var resource_dest = content_dest + "/Resources";
         mkdir(resource_dest);
         if (icon!="")
            copyIfNewer(icon, resource_dest + "/icon.incs",mAllFiles,mVerbose);
         addAssets(resource_dest,"cpp");
      }
      else
      {
         if (icon!="")
         {
            mAllFiles.push(dest + "/icon.png");
            copyIfNewer(icon, dest + "/icon.png",mAllFiles,mVerbose);
         }
         addAssets(content_dest,"cpp");
      }
   }

   function getExt()
   {
      return mOS=="Windows" ? ".exe" : "";
   }


   function buildCpp()
   {
      var ext = getExt();
      var exe_dest = isMac() ? getCppDest() + "/Contents/MacOS" : getCppDest();
      mkdir(exe_dest);

      var file = exe_dest + "/" + mDefines.get("APP_FILE")+ ext;
      var dbg = mDebug ? "-debug" : "";
      copyIfNewer(mBuildDir+"/cpp/bin/ApplicationMain"+dbg+ext, file, mAllFiles,mVerbose);
      if (isMac() || isLinux())
         run("","chmod", [ "755", file ]);
   }

   function runCpp()
   {
      var exe_dest = isMac() ? getCppDest() + "/Contents/MacOS" : getCppDest();
      run(exe_dest, dotSlash() + mDefines.get("APP_FILE"), [] );
   }

   // --- GPH ---------------------------------------------------------------

   function updateGph()
   {
      var dest = mBuildDir + "/gph/game/" + mDefines.get("APP_FILE") + "/";
      mContext.CPP_DIR = mBuildDir + "/gph/bin";

      mkdir(dest);

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/gph/haxe");
      cp_recurse(NME + "/install-tool/gph/hxml",mBuildDir + "/gph/haxe");
      cp_file(NME + "/install-tool/gph/game.ini",mBuildDir + "/gph/game/"  + mDefines.get("APP_FILE") + ".ini" );
      var boot = mDebug ? "Boot-debug.gpe" : "Boot-release.gpe";
      cp_file(NME + "/install-tool/gph/" + boot,mBuildDir + "/gph/game/"  + mDefines.get("APP_FILE") + "/Boot.gpe" );

      for(ndll in mNDLLs)
         ndll.copy("GPH/", dest, true, mVerbose, mAllFiles, "gph");

      var icon = mDefines.get("APP_ICON");
      if (icon!="")
      {
         copyIfNewer(icon, dest + "/icon.png", mAllFiles,mVerbose);
      }

      addAssets(dest,"cpp");
   }

   function buildGph()
   {
      var file = mDefines.get("APP_FILE");
      var dest = mBuildDir + "/gph/game/" + file + "/" + file + ".gpe";
      var gpe = mDebug ? "ApplicationMain-debug.gpe" : "ApplicationMain.gpe";
      copyIfNewer(mBuildDir+"/gph/bin/" + gpe, dest, mAllFiles, mVerbose);
   }

   function runGph()
   {
      if (!mDefines.exists("DRIVE"))
         throw "Please specify DRIVE=f:/ or similar on the command line.";
      var drive = mDefines.get("DRIVE");
      if (!neko.FileSystem.exists(drive + "/game"))
         throw "Drive " + drive + " does not appear to be a Caanoo drive.";
      cp_recurse(mBuildDir + "/gph/game", drive + "/game",false);

   }

   // --- iPhone ---------------------------------------------------------------

   function updateIphone()
   {
      var dest = mBuildDir + "/iphone/";

      mkdir(dest);

      cp_recurse(NME + "/install-tool/iphone/haxe", dest + "/haxe");

      var proj = mDefines.get("APP_FILE");

      cp_recurse(NME + "/install-tool/iphone/Classes", dest+"Classes");

      cp_recurse(NME + "/install-tool/iphone/PROJ.xcodeproj", dest + proj + ".xcodeproj");

      cp_file(NME + "/install-tool/iphone/PROJ-Info.plist", dest + proj + "-Info.plist");

      var lib = dest + "lib/";
      mkdir(lib);

      for(ndll in mNDLLs)
      {
         ndll.copy("iPhone/", lib, true, mVerbose, mAllFiles, "iphoneos");
         ndll.copy("iPhone/", lib, true, mVerbose, mAllFiles, "iphonesim");
      }

      addAssets(dest,"iphone");
   }

   function buildIphone()
   {
/*
      var file = mDefines.get("APP_FILE");
      var dest = mBuildDir + "/gph/game/" + file + "/" + file + ".gpe";
      var gpe = mDebug ? "ApplicationMain-debug.gpe" : "ApplicationMain.gpe";
      copyIfNewer(mBuildDir+"/gph/bin/" + gpe, dest, mVerbose);
*/
   }

   function runIphone()
   {
/*
      if (!mDefines.exists("DRIVE"))
         throw "Please specify DRIVE=f:/ or similar on the command line.";
      var drive = mDefines.get("DRIVE");
      if (!neko.FileSystem.exists(drive + "/game"))
         throw "Drive " + drive + " does not appear to be a Caanoo drive.";
      cp_recurse(mBuildDir + "/gph/game", drive + "/game",false);
*/
   }

   // --- Flash ---------------------------------------------------------------

   function updateFlash()
   {
      var dest = mBuildDir + "/flash/";
      var bin = dest + "bin";

      mkdir(dest);
      mkdir(dest+"/bin");

      cp_recurse(NME + "/install-tool/flash/hxml",dest + "haxe");
      cp_recurse(NME + "/install-tool/flash/template",dest + "haxe");

      var icon = mDefines.get("APP_ICON");
      if (icon!="")
      {
         copyIfNewer(icon, bin + "/icon.png",mAllFiles,mVerbose);
      }

      // addAssets(bin,"flash");
   }


   function buildFlash()
   {
      var dest = mBuildDir + "/flash/bin";
      var file = mDefines.get("APP_FILE") + ".swf";
      var input = neko.io.File.read(dest+"/"+file,true);
      var reader = new format.swf.Reader(input);
      var swf = reader.read();
      input.close();

      var new_tags = new Array<SWFTag>();
      var inserted = false;
      for(tag in swf.tags)
      {
         var name = Type.enumConstructor(tag);
         //trace(name);
         //if (name=="TSymbolClass") trace(tag);

         if (name=="TShowFrame" && !inserted && mAssets.length>0 )
         {
            new_tags.push(TShowFrame);
            for(asset in mAssets)
               if (asset.toSwf(new_tags) )
                  inserted = true;
         }
         new_tags.push(tag);
      }

      if (inserted)
      {
         swf.tags = new_tags;
         var output = neko.io.File.write(dest+"/"+file,true);
         var writer = new format.swf.Writer(output);
         writer.write(swf);
         output.close();
      }
   }

   function runFlash()
   {
      var dest = mBuildDir + "/flash/bin";

      var player = neko.Sys.getEnv("FLASH_PLAYER_EXE");
      if (player==null)
      {
         if (isMac())
           player = "/Applications/Flash Player Debugger.app/Contents/MacOS/Flash Player Debugger";
      }

      if (player==null || player=="")
         // Launch on windows
         run(dest, dotSlash() + mDefines.get("APP_FILE") + ".swf", [] );
      else
         run(dest, player, [ mDefines.get("APP_FILE") + ".swf" ] );
   }

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
                   mNDLLs.push(new NDLL(substitute(el.att.name),
                      el.has.haxelib ? substitute(el.att.haxelib) : "",
                      el.has.nekoapi ? substitute(el.att.nekoapi)!="" : false ) );

                case "classpath" : 
                   mHaxeFlags.push("-cp " + convertPath( substitute(el.att.name) ) );

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
      var dest:String = inXML.has.dest ? substitute(inXML.att.dest) : "";
      var type:String = inXML.has.type ? substitute(inXML.att.type) : "";
      for(el in inXML.elements)
      {
         var d = el.has.dest ? substitute(el.att.dest) : dest;
         var id= el.has.id ? substitute(el.att.id) : "";
         var embed= el.has.embed ? substitute(el.att.embed) : "";
         switch(el.name)
         {
            case "asset":
               var t = el.has.type ? substitute(el.att.type) : type;
               mAssets.push( new Asset( substitute(el.att.name),d,t,id, embed ) );
            case "sound":
               mAssets.push( new Asset( substitute(el.att.name),d,"sound",id, embed ) );
            case "music":
               mAssets.push( new Asset( substitute(el.att.name),d,"music",id, embed ) );
            case "image":
               mAssets.push( new Asset( substitute(el.att.name),d,"image",id, embed ) );

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

   public static function copyIfNewer(inFrom:String, inTo:String, ioAllFiles:Array<String>,inVerbose:Bool)
   {
      ioAllFiles.push(inTo);
      if (!neko.FileSystem.exists(inFrom))
      {
         neko.Lib.println("Error: " + inFrom + " does not exist");
         return;
      }

      if (neko.FileSystem.exists(inTo))
      {
         if (neko.FileSystem.stat(inFrom).mtime.getTime() <
             neko.FileSystem.stat(inTo).mtime.getTime() )
           return;
      }

      if (inVerbose)
         neko.Lib.println("Copy " + inFrom + " to " + inTo );
      neko.io.File.copy(inFrom, inTo);
   }

   static function usage()
   {
      neko.Lib.println("Usage :  haxelib run nme [-v] COMMAND ...");
      neko.Lib.println(" COMMAND : copy-if-newer from to");
      neko.Lib.println(" COMMAND : update build.nmml [-DFLAG -Dname=val... ]");
      neko.Lib.println(" COMMAND : (update|build|run) [-debug] build.nmml target");
      neko.Lib.println(" COMMAND : uninstall build.nmml target");
   }


   
   public static function main()
   {
      var words = new Array<String>();
      var defines = new Hash<String>();
      var include_path = new Array<String>();
      var command:String="";
      var verbose = false;
      var debug = false;

      include_path.push(".");

      var args = neko.Sys.args();
      var NME = "";
      // Check for calling from haxelib ...
      if (args.length>0)
      {
         var last:String = (new neko.io.Path(args[args.length-1])).toString();
         var slash = last.substr(-1);
         if (slash=="/"|| slash=="\\") 
            last = last.substr(0,last.length-1);
         if (neko.FileSystem.exists(last) && neko.FileSystem.isDirectory(last))
         {
            // When called from haxelib, the last arg is the original directory, and
            //  the current direcory is the library directory.
            NME = neko.Sys.getCwd();
            defines.set("NME",NME);
            args.pop();
            neko.Sys.setCwd(last);
         }
      }

      var os = neko.Sys.systemName();
      if ( (new EReg("window","i")).match(os) )
      {
         defines.set("windows", "1");
         defines.set("windows_host", "1");
         defines.set("HOST", "windows");
      }
      else if ( (new EReg("linux","i")).match(os) )
      {
         defines.set("linux","1");
         defines.set("HOST","linux");
      }
      else if ( (new EReg("mac","i")).match(os) )
      {
         defines.set("macos","1");
         defines.set("HOST","darwin-x86");
      }


      for(arg in args)
      {
         var equals = arg.indexOf("=");
         if (equals>0)
            defines.set(arg.substr(0,equals),arg.substr(equals+1));
         else if (arg=="-64")
            defines.set("NME_64","1");
         else if (arg.substr(0,2)=="-D")
            defines.set(arg.substr(2),"");
         else if (arg.substr(0,2)=="-I")
            include_path.push(arg.substr(2));
         else if (arg=="-v")
            verbose = true;
         else if (arg=="-debug")
            debug = true;
         else if (command.length==0)
            command = arg;
         else
            words.push(arg);
      }

      include_path.push(".");
      var env = neko.Sys.environment();
      if (env.exists("HOME"))
        include_path.push(env.get("HOME"));
      if (env.exists("USERPROFILE"))
        include_path.push(env.get("USERPROFILE"));
      include_path.push(NME + "/install-tool");


      var valid_commands = ["copy-if-newer", "rerun", "update", "test", "build", "installer", "uninstall"];
      if (!Lambda.exists(valid_commands,function(c) return command==c))
      {
         if (command!="")
            neko.Lib.println("Unknown command : " + command);
         usage();
         return;
      }

      if (command=="copy-if-newer")
      {
         if (words.length!=2)
         {
            neko.Lib.println("wrong number of arguements");
            usage();
            return;
         }
         copyIfNewer(words[0], words[1],[],verbose);
      }
      else
      {
         if (words.length!=2)
         {
            neko.Lib.println("wrong number of arguements");
            usage();
            return;
         }
 
         if (!neko.FileSystem.exists(words[0]))
         {
            neko.Lib.println("Error : " + command + ", .nmml file must be specified");
            usage();
            return;
         }

         for(e in env.keys())
            defines.set(e, neko.Sys.getEnv(e) );

         if ( !defines.exists("NME_CONFIG") )
            defines.set("NME_CONFIG",".hxcpp_config.xml");

         new InstallTool(NME,command,defines,include_path,words[0],words[1],verbose,debug);
      }
   }

}



