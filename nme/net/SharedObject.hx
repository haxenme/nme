package nme.net;
#if cpp || neko


import haxe.Serializer;
import haxe.Unserializer;
import nme.events.EventDispatcher;


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
		
		return SharedObjectFlushStatus.FLUSHED;
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


#else
typedef SharedObject = flash.net.SharedObject;
#end