package format.swf;


import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.text.TextField;
import format.swf.data.Frame;
import format.SWF;


class MovieClip extends Sprite {
	
	
	public var currentFrame (default, null):Int;
	public var currentFrameLabel (default, null):String;
	public var currentLabel (default, null):String;
	public var currentLabels (default, null):Array <FrameLabel>;
	//public var currentScene (default, null):Scene;
	public var enabled:Bool;
	public var framesLoaded (default, null):Int;
	//public var scenes (default, null):Array <Scene>;
	public var totalFrames (default, null):Int;
	public var trackAsMenu:Bool;
	
	private var activeObjects:Array <ActiveObject>;
	private var frames:Array <Frame>;
	private var objectPool:IntHash <List <DisplayObject>>;
	private var playing:Bool;
	private var swf:SWF;
	
	
	public function new (data:format.swf.symbol.Sprite = null) {
		
		super ();
		
		objectPool = new IntHash <List <DisplayObject>> ();
		
		enabled = true;
		playing = false;
		
		currentFrameLabel = null;
		currentLabel = null;
		currentLabels = new Array <FrameLabel> ();
		
		if (data != null) {
			
			totalFrames = data.frameCount;
			currentFrame = totalFrames;
			framesLoaded = totalFrames;
			
			swf = data.swf;
			frames = data.frames;
			
			for (label in data.frameLabels.keys ()) {
				
				var frameLabel = new FrameLabel (data.frameLabels.get (label), label);
				currentLabels.push (frameLabel);
				
			}
			
			activeObjects = new Array <ActiveObject> ();
			
			gotoAndPlay (1);
			
		} else {
			
			currentFrame = 1;
			totalFrames = 1;
			framesLoaded = 1;
			
		}
		
	}
	
	
	public function gotoAndPlay (frame:Dynamic, scene:String = null):Void {
		
		if (Std.is (frame, String)) {
			
			for (frameLabel in currentLabels) {
				
				if (frameLabel.name == frame) {
					
					currentFrame = frameLabel.frame;
					break;
					
				}
				
			}
			
		} else {
			
			currentFrame = frame;
			
		}
		
		updateObjects ();
		play ();
		
	}
	
	
	public function gotoAndStop (frame:Dynamic, scene:String = null):Void {
		
		if (Std.is (frame, String)) {
			
			for (frameLabel in currentLabels) {
				
				if (frameLabel.name == frame) {
					
					currentFrame = frameLabel.frame;
					break;
					
				}
				
			}
			
		} else {
			
			currentFrame = frame;
			
		}
		
		updateObjects ();
		stop ();
		
	}
	
	
	public function nextFrame ():Void {
		
		var next = currentFrame + 1;
		
		if (next > totalFrames) {
			
			next = totalFrames;
			
		}
		
		gotoAndStop (next);
		
	}
	
	
	/*public function nextScene ():Void {
		
		
		
	}*/
	
	
	public function play ():Void {
		
		if (totalFrames > 1) {
			
			playing = true;
			removeEventListener (Event.ENTER_FRAME, this_onEnterFrame);
			addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
			
		} else {
			
			stop ();
			
		}
		
	}
	
	
	public function prevFrame ():Void {
		
		var previous = currentFrame - 1;
		
		if (previous < 1) {
			
			previous = 1;
			
		}
		
		gotoAndStop (previous);
		
	}
	
	
	public function stop ():Void {
		
		playing = false;
		removeEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
	}
	
	
	private function updateObjects ():Void {
		
		if (frames != null) {
			
			var frame = frames[currentFrame];
			var depthChanged = false;
			var waitingLoader = false;
			
			if (frame != null) {
				
				var frameObjects = frame.copyObjectSet ();
				var newActiveObjects = new Array <ActiveObject> ();
				
				for (activeObject in activeObjects) {
					
					var depthSlot = frameObjects.get (activeObject.depth);
					
					if (depthSlot == null || depthSlot.symbolID != activeObject.symbolID || activeObject.waitingLoader) {
						
						// Add object to pool - if it's complete.
						
						if (!activeObject.waitingLoader) {
							
							var pool = objectPool.get (activeObject.symbolID);
							
							if (pool == null) {
								
								pool = new List <DisplayObject> ();
								objectPool.set (activeObject.symbolID, pool);
								
							}
							
							pool.push (activeObject.object);
							
						}
						
						// todo - disconnect event handlers ?
						removeChild (activeObject.object);
						
					} else {
						
						// remove from our "todo" list
						frameObjects.remove (activeObject.depth);
						
						activeObject.index = depthSlot.findClosestFrame (activeObject.index, currentFrame);
						var attributes = depthSlot.attributes[activeObject.index];
						attributes.apply (activeObject.object);
						
						newActiveObjects.push (activeObject);
						
					}
					
				}
				
				// Now add missing characters in unfilled depth slots
				for (depth in frameObjects.keys ()) {
					
					var slot = frameObjects.get (depth);
					var displayObject:DisplayObject = null;
					var pool = objectPool.get (slot.symbolID);
					
					if (pool != null && pool.length > 0) {
						
						displayObject = pool.pop ();
						
						switch (slot.symbol) {
							
							case spriteSymbol (data):
								
								var clip:MovieClip = cast displayObject;
								clip.gotoAndPlay (1);
							
							default:
								
							
						}
						
					} else {               
						
						switch (slot.symbol) {
							
							case spriteSymbol (sprite):
								
								var movie = new MovieClip (sprite);
								displayObject = movie;
							
							case shapeSymbol (shape):
								
								var s = new Shape ();
								s.cacheAsBitmap = true; // temp fix
								//shape.Render(new nme.display.DebugGfx());
								waitingLoader = shape.render (s.graphics);
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
						
					}
					
					#if have_swf_depth
					// On neko, we can z-sort by using our special field ...
					displayObject.__swf_depth = depth;
					#end
					
					var added = false;
					
					// todo : binary converge ?
					
					for (cid in 0...numChildren) {
						
						#if have_swf_depth
						
						var childDepth = getChildAt (cid).__swf_depth;
						
						#else
						
						var childDepth = -1;
						var sought = getChildAt (cid);
						
						for (child in newActiveObjects) {
							
							if (child.object == sought) {
								
								childDepth = child.depth;
								break;
								
							}
							
						}
						
						#end
						
						if (childDepth > depth) {
							
							addChildAt (displayObject, cid);
							added = true;
							break;
							
						}
						
					}
					
					if (!added) {
						
						addChild (displayObject);
						
					}
					
					var idx = slot.findClosestFrame (0, currentFrame);
					slot.attributes[idx].apply (displayObject);
					
					var act = { object: displayObject, depth: depth, index: idx, symbolID: slot.symbolID, waitingLoader: waitingLoader };
					
					newActiveObjects.push (act);
					depthChanged = true;
					
				}
				
				activeObjects = newActiveObjects;
				
				currentFrameLabel = null;
				
				for (frameLabel in currentLabels) {
					
					if (frameLabel.frame < frame.frame) {
						
						currentLabel = frameLabel.name;
						
					} else if (frameLabel.frame == frame.frame) {
						
						currentFrameLabel = frameLabel.name;
						currentLabel = currentFrameLabel;
						
						break;
						
					} else {
						
						break;
						
					}
					
				}
				
			}
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function this_onEnterFrame (event:Event):Void {
		
		if (playing) {
			
			currentFrame ++;
			
			if (currentFrame > totalFrames) {
				
				currentFrame = 1;
				
			}
			
			updateObjects ();
			
		}
		
	}
	
	
}


typedef ActiveObject = {
	
	var object:DisplayObject;
	var depth:Int;
	var symbolID:Int;
	var index:Int;
	var waitingLoader:Bool;
	
}