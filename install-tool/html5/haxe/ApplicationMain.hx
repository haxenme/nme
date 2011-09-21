import ::APP_MAIN_PACKAGE::::APP_MAIN_CLASS::;
import nme.display.Loader;
import nme.media.Sound;
import nme.net.URLRequest;


class ApplicationMain {
	
	
	public static function main () {
		
		::APP_MAIN_CLASS::.main ();
		
	}
	

   public static function getAsset(inName:String):Dynamic {
	   
		::foreach assets::
		if (inName=="::id::") {
			::if (type=="image")::
			var loader:Loader = new Loader ();
			loader.load (new URLRequest ("::resourceName::"));
			return loader;
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
   
   
}