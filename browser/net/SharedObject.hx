package browser.net;


import browser.errors.Error;
import browser.events.EventDispatcher;
import browser.net.SharedObjectFlushedStatus;
import haxe.io.Bytes;
import haxe.Serializer;
import haxe.Unserializer;
import js.Storage;


class SharedObject extends EventDispatcher {
	
	
	public var data (default, null):Dynamic;
	public var size (get_size, never):Int;
	
	private var nmeKey:String;
	

	private function new () {
		
		super ();
		
	}
	
	
	public function clear ():Void {
		
		data = {};
		nmeGetLocalStorage ().removeItem (nmeKey);
		flush ();
		
	}
	
	
	public function flush ():SharedObjectFlushedStatus {
		
		var data = Serializer.run (data);
		nmeGetLocalStorage ().setItem (nmeKey, data);
		return SharedObjectFlushedStatus.FLUSHED;
		
	}
	
	
	public static function getLocal (name:String, localPath:String = null, secure:Bool = false /* note: unsupported */) {
		
		if (localPath == null) localPath = js.Lib.window.location.href;
		
		var so = new SharedObject ();
		so.nmeKey = localPath + ":" + name;
		var rawData = nmeGetLocalStorage ().getItem (so.nmeKey);
		
		so.data = { };
		
		if (rawData != null && rawData != "") {
			
			so.data = Unserializer.run (rawData);
			
		}
		
		return so;
		
	}
	
	
	private static function nmeGetLocalStorage ():Storage {
		
		var res = Storage.getLocal ();
		if (res == null) throw new Error ("SharedObject not supported");
		return res;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_size ():Int {
		
		var d = Serializer.run (data);
		return Bytes.ofString (d).length;
		
	}
	
	
}