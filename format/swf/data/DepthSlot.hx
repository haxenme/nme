package format.swf.data;


import flash.geom.ColorTransform;
import flash.geom.Matrix;
import format.swf.symbol.Symbol;


class DepthSlot {
	
	
	public var attributes:Array <DisplayAttributes>;
	public var symbol:Symbol;
	public var symbolID:Int;
	
	private var cacheAttributes:DisplayAttributes;


	public function new (symbolID:Int, symbol:Symbol, attributes:DisplayAttributes) {
		
		this.symbolID = symbolID;
		this.symbol = symbol;
		
		this.attributes = [];
		this.attributes.push (attributes);
		
		cacheAttributes = attributes;
		
	}
	
	
	public function findClosestFrame (hintFrame:Int, frame:Int):Int {
		
		var last = hintFrame;
		
		if (last >= attributes.length) {
			
			last = 0;
			
		} else if (last > 0) {
			
			if (attributes[last - 1].frame > frame) {
				
				last = 0;
				
			}
			
		}
		
		for (i in last...attributes.length) {
			
			if (attributes[i].frame > frame) {
				
				return last;
				
			}
			
			last = i;
			
		}
		
		return last;
		
	}
	
	
	public function move (frame:Int, matrix:Matrix, colorTransform:ColorTransform, ratio:Null <Int>):Void {
		
		cacheAttributes = cacheAttributes.clone ();
		cacheAttributes.frame = frame;
		
		if (matrix != null) {
			
			cacheAttributes.matrix = matrix;
			
		}
		
		if (colorTransform != null) {
			
			cacheAttributes.colorTransform = colorTransform;
			
		}
		
		if (ratio != null) {
			
			cacheAttributes.ratio = ratio;
			
		}
		
		attributes.push (cacheAttributes);
		
	}
	
	
}