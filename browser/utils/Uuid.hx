package browser.utils;
#if js


class Uuid {
	
	
	//private static inline var UID_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-=[]();.,/?";
	private static inline var UID_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	
	
	private static inline function random(?size:Int):String {
		
		if (size == null) size = 32;
		
		var nchars = UID_CHARS.length;
		var uid = new StringBuf();
		
		for (i in 0 ... size) {
			
			uid.add(UID_CHARS.charAt(Std.int(Math.random() * nchars)));
			
		}
		
		return uid.toString();
		
	}
	
	
	public static function uuid():String {
		
		return random(8) + '-' + random(4) + '-' + random(4) + '-' + random(4) + '-' + random(12);
		
	}
	
	
}


#end