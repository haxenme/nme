package native.net;


import native.utils.ByteArray;


class URLRequest {
	
	
	public static inline var AUTH_BASIC = 0x0001;
	public static inline var AUTH_DIGEST = 0x0002;
	public static inline var AUTH_GSSNEGOTIATE = 0x0004;
	public static inline var AUTH_NTLM = 0x0008;
	public static inline var AUTH_DIGEST_IE = 0x0010;
	public static inline var AUTH_DIGEST_ANY = 0x000f;
	
	public var url:String;
	public var requestHeaders:Array<URLRequestHeader>;
	public var authType:Int;
	public var cookieString:String;
	public var verbose:Bool;
	public var method:String;
	public var contentType:String;
	public var data:Dynamic;
	public var credentials:String;

	/** @private */ public var nmeBytes:ByteArray;
	
	
	public function new (?inURL:String) {
		
		if (inURL != null)
			url = inURL;
		
		requestHeaders = [];
		method = URLRequestMethod.GET;
		
		verbose = false;
		cookieString = "";
		authType = 0;
		contentType = "application/x-www-form-urlencoded";
		credentials = "";
		
	}
	
	
	public function basicAuth (inUser:String, inPasswd:String) {
		
		authType = AUTH_BASIC;
		credentials = inUser + ":" + inPasswd;
		
	}
	
	
	public function digestAuth (inUser:String, inPasswd:String) {
		
		authType = AUTH_DIGEST;
		credentials = inUser + ":" + inPasswd;
		
	}
	
	
	/** @private */ public function nmePrepare () {
		
		if (data == null) {
			
			nmeBytes = new ByteArray ();
			
		} else if (Std.is (data, ByteArray)) {
			
			nmeBytes = data;
			
		} else if (Std.is (data, URLVariables)) {
			
			var vars:URLVariables = data;
			var str = vars.toString ();
			nmeBytes = new ByteArray ();
			nmeBytes.writeUTFBytes (str);
			
		} else if (Std.is (data, String)) {
			
			var str:String = data;
			nmeBytes = new ByteArray ();
			nmeBytes.writeUTFBytes (str);
			
		} else if (Std.is (data, Dynamic)) {
			
			var vars:URLVariables = new URLVariables ();
			
			for (i in Reflect.fields (data))
				Reflect.setField (vars, i, Reflect.field (data, i));
			
			var str = vars.toString ();
			nmeBytes = new ByteArray ();
			nmeBytes.writeUTFBytes (str);
			
		} else {
			
			throw "Unknown data type";
			
		}
		
	}
	
	
}