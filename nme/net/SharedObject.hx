#if flash


package flash.net;

extern class SharedObject extends nme.events.EventDispatcher {
	var client : Dynamic;
	var data(default,null) : Dynamic;
	var fps(null,default) : Float;
	var objectEncoding : UInt;
	var size(default,null) : UInt;
	function new() : Void;
	function clear() : Void;
	function close() : Void;
	function connect(myConnection : NetConnection, ?params : String) : Void;
	function flush(minDiskSpace : Int = 0) : SharedObjectFlushStatus;
	function send(?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic) : Void;
	function setDirty(propertyName : String) : Void;
	function setProperty(propertyName : String, ?value : Dynamic) : Void;
	static var defaultObjectEncoding : UInt;
	static function deleteAll(url : String) : Int;
	static function getDiskUsage(url : String) : Int;
	static function getLocal(name : String, ?localPath : String, secure : Bool = false) : SharedObject;
	static function getRemote(name : String, ?remotePath : String, persistence : Dynamic = false, secure : Bool = false) : SharedObject;
}


#else


package nme.net;
import haxe.Serializer;
import haxe.Unserializer;
import nme.events.EventDispatcher;

@:fakeEnum(String) enum SharedObjectFlushStatus 
{
	FLUSHED;
	PENDING;
}

/** SharedObject */
class SharedObject extends EventDispatcher
{
	//
	// Definitions
	//

	//
	// Instance Variables
	//
	
	/** Data */
	public var data(default,null):Dynamic;
	
	/** ID */
	private var id:String;

	//
	// Public Methods
	//

	/** Create New SharedObject */
	private function new(id:String,data:Dynamic) 
	{
		super();
		this.id=id;
		this.data=data;
	}
	
	/** Clear */
	public function clear():Void
	{
		untyped nme_clear_user_preference(id);
	}
	
	/** Flush */
	public function flush(?minDiskSpace:Int=0):SharedObjectFlushStatus
	{
		var encodedData:String=Serializer.run(data);
		untyped nme_set_user_preference(id,encodedData);
		
		return FLUSHED;
	}
	
	//
	// Static Methods
	//
	
	/** Get Local */
	public static function getLocal(name:String,?localPath:String,secure:Bool=false):SharedObject
	{
		var rawData:String=untyped nme_get_user_preference(name);

		var loadedData:Dynamic={};

		if (rawData=="" || rawData==null)
		{
			loadedData={};
		}
		else
		{
			loadedData=Unserializer.run(rawData);
		}
		
		var so:SharedObject=new SharedObject(name,loadedData);
		return so;
	}
	
	//
	// Implementation
	//
	
	//
	// NME Interface
	//
	
	static var nme_get_user_preference=nme.Loader.load("nme_get_user_preference",1);
	static var nme_set_user_preference=nme.Loader.load("nme_set_user_preference",2);
	static var nme_clear_user_preference=nme.Loader.load("nme_clear_user_preference",1);
	
}


#end