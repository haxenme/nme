package nme;


#if flash
class Lib {

	public static var current : nme.display.MovieClip;

	public inline static function getTimer() : Int {
		return untyped __global__["flash.utils.getTimer"]();
	}

	public static function eval( path : String ) : Dynamic {
		var p = path.split(".");
		var fields = new Array();
		var o : Dynamic = null;
		while( p.length > 0 ) {
			try {
				o = untyped __global__["flash.utils.getDefinitionByName"](p.join("."));
			} catch( e : Dynamic ) {
				fields.unshift(p.pop());
			}
			if( o != null )
				break;
		}
		for( f in fields ) {
			if( o == null ) return null;
			o = untyped o[f];
		}
		return o;
	}

	public static function getURL( url : nme.net.URLRequest, ?target : String ) {
		var f = untyped __global__["flash.net.navigateToURL"];
		if( target == null )
			f(url);
		else
			(cast f)(url,target);
	}

	public static function fscommand( cmd : String, ?param : String ) {
		untyped __global__["flash.system.fscommand"](cmd,if( param == null ) "" else param);
	}

	public static function trace( arg : Dynamic ) {
		untyped __global__["trace"](arg);
	}

	public static function attach( name : String ) : nme.display.MovieClip {
		var cl = untyped __as__(__global__["flash.utils.getDefinitionByName"](name),Class);
		return untyped __new__(cl);
	}

	public inline static function as<T>( v : Dynamic, c : Class<T> ) : Null<T> {
		return untyped __as__(v,c);
	}

}
#else



import nme.net.URLRequest;

class Lib
{
   static public var FULLSCREEN = 0x0001;
   static public var BORDERLESS = 0x0002;
   static public var RESIZABLE  = 0x0004;
   static public var HARDWARE   = 0x0008;
   static public var VSYNC      = 0x0010;
   static public var HW_AA      = 0x0020;
   static public var HW_AA_HIRES= 0x0060;

   static var nmeMainFrame: Dynamic = null;
   static var nmeCurrent: nme.display.MovieClip = null;
   static var nmeStage: nme.display.Stage = null;

	public static var initWidth(default,null):Int;
	public static var initHeight(default,null):Int;

   public static var stage(nmeGetStage,null): nme.display.Stage;
   public static var current(nmeGetCurrent,null): nme.display.MovieClip;
   static var sIsInit = false;


   public static function create(inOnLoaded:Void->Void,inWidth:Int, inHeight:Int,
                      inFrameRate:Float = 60.0,  inColour:Int = 0xffffff,
                      inFlags:Int = 0x0f, inTitle:String = "NME", inPackage:String = "", ?inIcon : nme.display.BitmapData)
   {
      if (sIsInit)
      {
          throw("nme.Lib.create called multiple times.  " +
                "This function is automatically called by the project code.");
      }
      sIsInit = true;
	   initWidth = inWidth;
	   initHeight = inHeight;
      var create_main_frame = nme.Loader.load("nme_create_main_frame",-1);
      create_main_frame(
        function(inFrameHandle:Dynamic) {
            #if android try { #end
            nmeMainFrame = inFrameHandle;
            var stage_handle = nme_get_frame_stage(nmeMainFrame);
            nme.Lib.nmeStage = new nme.display.Stage(stage_handle,inWidth,inHeight);
            nme.Lib.nmeStage.frameRate = inFrameRate;
            nme.Lib.nmeStage.opaqueBackground = inColour;
            nme.Lib.nmeStage.onQuit = close;
            if (nmeCurrent!=null) // Already created...
               nme.Lib.nmeStage.addChild(nmeCurrent);
            inOnLoaded();
            #if android } catch (e:Dynamic) { trace("ERROR: " +  e); } #end
        },
        inWidth,inHeight,inFlags,inTitle,inPackage,inIcon==null?null:inIcon.nmeHandle );
   }


   public static function createManagedStage(inWidth:Int, inHeight:Int)
   {
	   initWidth = inWidth;
	   initHeight = inHeight;
      nmeStage = new nme.display.ManagedStage(inWidth,inHeight);
      return nmeStage;
   }


   static function nmeGetStage()
   {
      if (nmeStage==null)
         throw("Error : stage can't be accessed until init is called");
      return nmeStage;
   }

   public static function getURL (url : URLRequest, ?target : String) : Void {

           nme_get_url (url.url);

   }

   // Be careful not to blow precision, since storing ms since 1970 can overflow...
   static public function getTimer() : Int
   {
      return Std.int(nme.Timer.stamp() * 1000.0);
   }


   public static function close()
   {
      var close = nme.Loader.load("nme_close",0);
      close();
   }

   static public function setAssetBase(inBase:String)
   {
      nme_set_asset_base(inBase);
   }


   static function nmeGetCurrent() : nme.display.MovieClip
   {
      if (nmeCurrent==null)
      {
         nmeCurrent = new nme.display.MovieClip();
         if (nmeStage!=null)
            nmeStage.addChild(nmeCurrent);
      }
      return nmeCurrent;
   }


   static var nme_get_frame_stage = nme.Loader.load("nme_get_frame_stage",1);
   static var nme_set_asset_base = nme.Loader.load("nme_set_asset_base",1);
   static var nme_get_url = nme.Loader.load("nme_get_url",1);

}
#end