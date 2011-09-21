import ::APP_MAIN_PACKAGE::::APP_MAIN_CLASS::;
import nme.display.Bitmap;
import nme.display.Loader;
import nme.events.Event;
import nme.media.Sound;
import nme.net.URLRequest;


class ApplicationMain {
	
	
	private static var completed:Int;
	public static var loaders:Hash <Loader>;
	private static var total:Int;
	
	
	public static function main () {
		
		completed = 0;
		loaders = new Hash <Loader> ();
		total = 0;
		
		::foreach assets::
		::if (type=="image")::
		var loader:Loader = new Loader ();
		loaders.set ("::resourceName::", loader);
		total ++;
		
		::end::::end::
		
		if (total == 0) {
			
			begin ();
			
		} else {
			
			for (path in loaders.keys ()) {
				
				var loader:Loader = loaders.get (path);
				loader.contentLoaderInfo.addEventListener ("complete", loader_onComplete);
				loader.load (new URLRequest (path));
				
			}
			
		}
		
	}
	
	
	private static function begin ():Void {
		
		::APP_MAIN_CLASS::.main ();
		
	}
	

   public static function getAsset(inName:String):Dynamic {
	   
		::foreach assets::
		if (inName=="::id::") {
			::if (type == "image")::
			return cast (loaders.get ("::resourceName::").contentLoaderInfo.content, Bitmap).bitmapData.clone ();
			::elseif (type=="sound")::
			return new Sound (new URLRequest ("::resourceName::"));
			::elseif (type=="music")::
			return new Sound (new URLRequest ("::resourceName::"));
			::else::
			//return nme.utils.ByteArray.readFile(inName);
			::end::
		}
		::end::
		return null;
		
   }
   
   
   
   
   // Event Handlers
   
   
   
   
	private static function loader_onComplete (event:Event):Void {
	   
		completed ++;
		
		if (completed == total) {
			
			begin ();
			
		}
	   
	}
   
   
}