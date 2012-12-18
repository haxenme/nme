package browser;


class RGB {
	
	
	public static inline var ONE:Int = 1;
	public static inline var ZERO:Int = 0;

	public static var CLEAR = 0x00000000;
	public static var BLACK = 0xff000000;
	public static var WHITE = 0xffffffff;
	public static var RED = 0xffff0000;
	public static var GREEN = 0xff00ff00;
	public static var BLUE = 0xff0000ff;
	
	
	public static function Alpha (inRGBA:Int):Int {
		
		return (inRGBA >> 24) & 0xff;
		
	}
	
	
	public static function Blue (inRGBA:Int):Int {
		
		return inRGBA & 0xff;
		
	}
	
	
	public static function Green (inRGBA:Int):Int {
		
		return (inRGBA >> 8) & 0xff;
		
	}
	
	
	public static function IRGB (inRGBA:Int):Int {
		
		return inRGBA & 0xffffff;
		
	}
	
	
	public static function Red (inRGBA:Int):Int {
		
		return (inRGBA >> 16) & 0xff;
		
	}
	
	
	public static function RGB (inR:Int, inG:Int, inB:Int):Int {
		
		return (inR << 16) | (inG << 8) | inB;
		
	}
	
	
	public static function RGBA (inR:Int, inG:Int, inB:Int, inA:Int = 255):Int {
		
		return (inA << 24) | (inR << 16) | (inG << 8) | inB;
		
	}
	
	
}