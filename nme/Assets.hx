package nme;
#if (!nme_install_tool || nme_document)


import nme.display.BitmapData;
import nme.media.Sound;
import nme.text.Font;
import nme.utils.ByteArray;


/**
 * ...
 * @author Joshua Granick
 */

class Assets {

	
	public static function getBitmapData (id:String):BitmapData {
		
		return null;
		
	}
	
	
	public static function getBytes (id:String):ByteArray {
		
		return null;
		
	}
	
	
	public static function getFont (id:String):Font {
		
		return null;
		
	}
	
	
	public static function getSound (id:String):Sound {
		
		return null;
		
	}
	
	
	public static function getText (id:String):String {
		
		return null;
		
	}
	
	
}


#else
typedef Assets = nme.installer.Assets;
#end