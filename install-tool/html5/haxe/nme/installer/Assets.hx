package nme.installer;


import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;


/**
 * ...
 * @author Joshua Granick
 */

class Assets {

	
	public static function getBitmapData (id:String):BitmapData {
		
		switch (id) {
			
			//::foreach assets::::if (type == "image")::case "::id::": return BitmapData.load ("::resourceName::");
			//::end::::end::
		}
		
		return null;
		
	}
	
	
	public static function getBytes (id:String):ByteArray {
		
		switch (id) {
			
			//::foreach assets::case "::id::": return ByteArray.readFile ("::resourceName::");
			//::end::
		}
		
		return null;
		
	}
	
	
	public static function getFont (id:String):Font {
		
		switch (id) {
			
			//::foreach assets::::if (type == "font")::case "::id::": return new Font ("::resourceName::"); 
			//::end::::end::
		}
		
		return null;
		
	}
	
	
	public static function getSound (id:String):Sound {
		
		switch (id) {
			
			::foreach assets::::if (type == "sound")::case "::id::": return new Sound (new URLRequest ("::resourceName::"));::elseif (type == "music")::case "::id::": return new Sound (new URLRequest ("::resourceName::"));
			::end::::end::
		}
		
		return null;
		
	}
	
	
	public static function getText (id:String):String {
		
		var bytes:ByteArray = getBytes (id);
		
		if (bytes == null) {
			
			return null;
			
		} else {
			
			return bytes.readUTFBytes (bytes.length);
			
		}
		
	}
	
	
}