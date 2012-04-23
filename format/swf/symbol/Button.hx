package format.swf.symbol;


import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.filters.BitmapFilter;
import flash.text.TextField;
import format.swf.data.Filters;
import format.swf.data.SWFStream;
import format.SWF;


class Button {
	
	
	private var buttonRecords:Array <ButtonRecord>;
	private var filters:Array <BitmapFilter>;
	private var swf:SWF;
	
	
	public function new (swf:SWF, stream:SWFStream, version:Int) {
		
		this.swf = swf;
		
		if (version == 2) {
			
			stream.readBits (7);
			
			var trackAsMenu = stream.readBool ();
			var actionOffset = stream.readUInt16 ();
			
		}
		
		buttonRecords = new Array <ButtonRecord> ();
		
		while (stream.readByte () != 0) {
			
			stream.position --;
			
			var blank = stream.readBits (2);
			
			var hasBlendMode = stream.readBool ();
			var hasFilterList = stream.readBool ();
			
			var stateHitTest = stream.readBool ();
			var stateDown = stream.readBool ();
			var stateOver = stream.readBool ();
			var stateUp = stream.readBool ();
			
			var characterID = stream.readUInt16 ();
			
			var state:ButtonState = UP;
			if (stateHitTest) state = HIT_TEST;
			if (stateDown) state = DOWN;
			if (stateOver) state = OVER;
			if (stateUp) state = UP;
			
			buttonRecords.push (new ButtonRecord (characterID, state));
			
			var placeDepth = stream.readUInt16 ();
			var placeMatrix = stream.readMatrix ();
			
			if (version == 2) {
				
				var colorTransform = stream.readColorTransform (true);
				
				if (hasFilterList) {
					
					filters = Filters.readFilters (stream);
					
				}
				
				if (hasBlendMode) {
					
					stream.readByte ();
					
					/*blendMode = switch (stream.readByte ()) {
						case 2 : BlendMode.LAYER;
						case 3 : BlendMode.MULTIPLY;
						case 4 : BlendMode.SCREEN;
						case 5 : BlendMode.LIGHTEN;
						case 6 : BlendMode.DARKEN;
						case 7 : BlendMode.DIFFERENCE;
						case 8 : BlendMode.ADD;
						case 9 : BlendMode.SUBTRACT;
						case 10 : BlendMode.INVERT;
						case 11 : BlendMode.ALPHA;
						case 12 : BlendMode.ERASE;
						case 13 : BlendMode.OVERLAY;
						case 14 : BlendMode.HARDLIGHT;
						default: BlendMode.NORMAL;
					}*/
					
				}
				
			}
			
		}
		
	}
	
	
	public function apply (simpleButton:SimpleButton):Void {
		
		for (buttonRecord in buttonRecords) {
			
			var displayObject:DisplayObject = null;
			
			switch (swf.getSymbol (buttonRecord.id)) {
				
				case spriteSymbol (sprite):
					
					var movie = new MovieClip (sprite);
					displayObject = movie;
				
				case shapeSymbol (shape):
					
					var s = new Shape ();
					s.cacheAsBitmap = true; // temp fix
					//shape.Render(new nme.display.DebugGfx());
					shape.render (s.graphics);
					displayObject = s;
				
				case morphShapeSymbol (morphData):
					
					var morph = new MorphObject (morphData);
					//morph_data.Render(new nme.display.DebugGfx(),0.5);
					displayObject = morph;
				
				case staticTextSymbol (text):
					
					var s = new Shape();
					s.cacheAsBitmap = true; // temp fix
					text.render (s.graphics);
					displayObject = s;
				
				case editTextSymbol (text):
					
					var t = new TextField ();
					text.apply (t);
					displayObject = t;
				
				case bitmapSymbol (shape):
					
					throw("Adding bitmap?");
				
				case fontSymbol (font):
					
					throw("Adding font?");
				
				case buttonSymbol (button):
					
					var b = new SimpleButton ();
					button.apply (b);
					displayObject = b;
				
			}
			
			switch (buttonRecord.state) {
				
				case UP:
					
					simpleButton.upState = displayObject;
				
				case OVER:
					
					simpleButton.overState = displayObject;
				
				case DOWN:
					
					simpleButton.downState = displayObject;
				
				case HIT_TEST:
					
					simpleButton.hitTestState = displayObject;
				
				case NONE:
				
			}
			
			if (simpleButton.hitTestState == null) {
				
				simpleButton.hitTestState = simpleButton.upState;
				
			}
			
			simpleButton.filters = filters;
			
		}
		
	}
	
	
}


class ButtonRecord {
	
	
	public var id:Int;
	public var state:ButtonState;
	
	
	public function new (id:Int, state:ButtonState) {
		
		this.id = id;
		this.state = state;
		
	}
	
	
}


enum ButtonState {
	
	UP;
	OVER;
	DOWN;
	HIT_TEST;
	NONE;
	
}