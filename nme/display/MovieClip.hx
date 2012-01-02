package nme.display;
#if (cpp || neko)


import nme.events.Event;
import nme.format.swf.Frame;
import nme.format.swf.MorphObject;
import nme.display.Shape;
import nme.text.TextField;


class MovieClip extends nme.display.Sprite
{
	
	private static var count = 0;
	private static var mMovieID = 0;
	private static var mIDBase = 1;
	
	public var currentFrame(nmeGetCurrentFrame, null):Int;
	public var enabled:Bool;
	public var framesLoaded(nmeGetTotalFrames, null):Int;
	public var totalFrames(nmeGetTotalFrames, null):Int;
	
	private var mActive:ActiveObjects;
	private var mCurrentFrame:Int;
	private var mFrames:Frames;
	private var mObjectPool:ObjectPool;
	private var mPlaying: Bool;
	private var mTotalFrames:Int;
	

	public function new()
	{
		super();
		
		mCurrentFrame = 0;
		mTotalFrames = 0;
		
		mObjectPool = new ObjectPool();
		mMovieID = mIDBase++;
		mPlaying = false;
		
		addEventListener(Event.ENTER_FRAME, this_onEnterFrame);
	}
	
	
	public function gotoAndPlay(frame:Dynamic, ?scene:String):Void
	{
		mCurrentFrame = frame;
		updateActive();
		mPlaying = true;
	}
	
	
	public function gotoAndStop(frame:Dynamic, ?scene:String):Void
	{
		mCurrentFrame = frame;
		updateActive();
		mPlaying = false;
	}
	
	
	/**
	 * @private
	 */
	public function nmeCreateFromSWF(inSprite:nme.format.swf.Sprite):Void
	{
		mTotalFrames = mCurrentFrame = inSprite.GetFrameCount();
		
		//mSWF = inSprite.mSWF;
		mFrames= inSprite.mFrames;
		mActive = new ActiveObjects();
		
		gotoAndPlay(1);
	}
	
	
	override function nmeGetType()
	{
		return "MovieClip";
	}
	
	
	public function play():Void
	{
		mPlaying = true;
	}
	
	
	public function stop():Void
	{
		mPlaying = false;
	}
	
	
	private function updateActive():Void
	{
		if (mFrames != null)
		{
			var frame = mFrames[mCurrentFrame];
			var depth_changed = false;
			var waiting_loader = false;
			
			if (frame != null)
			{
				var frame_objs = frame.CopyObjectSet();
				
				// Remove or update child frames in the existing list ...
				var new_active = new ActiveObjects();
				
				for (a in mActive)
				{
					var depth_slot = frame_objs.get(a.mDepth);
					
					if (depth_slot == null || depth_slot.mID != a.mID || a.mWaitingLoader)
					{
						// Add object to pool - if it's complete.
						if (!a.mWaitingLoader)
						{
							var pool = mObjectPool.get(a.mID);
							
							if (pool == null)
							{
								pool = new ObjectList();
								mObjectPool.set(a.mID, pool);
							}
							
							pool.push(a.mObj);
						}
						// todo - disconnect event handlers ?
						removeChild(a.mObj);
					}
					else
					{
						// remove from our "todo" list
						frame_objs.remove(a.mDepth);
						
						a.mIndex = depth_slot.FindClosestFrame(a.mIndex, mCurrentFrame);
						var attrib = depth_slot.mAttribs[a.mIndex];
						attrib.Apply(a.mObj);
						new_active.push(a);
					}
				}
				
				// Now add missing characters in unfilled depth slots
				for (depth in frame_objs.keys())
				{
					var slot = frame_objs.get(depth);
					var disp_object:DisplayObject = null;
					var pool = mObjectPool.get(slot.mID);
					
					if (pool != null && pool.length > 0)
					{
						disp_object = pool.pop();
						switch(slot.mCharacter)
						{
							case charSprite(sprite):
								var clip:MovieClip = untyped disp_object;
								clip.gotoAndPlay(1);
							
							default:
						}
					}
					else
					{               
						//trace(count++);
						switch(slot.mCharacter)
						{
							case charSprite(sprite):
								var movie = new MovieClip();
								movie.nmeCreateFromSWF(sprite);
								disp_object = movie;
							
							case charShape(shape):
								var s = new Shape();
								//trace( s );
								//shape.Render(new nme.display.DebugGfx());
								waiting_loader = shape.Render(s.graphics);
								disp_object = s;
							
							case charMorphShape(morph_data):
								var morph = new MorphObject(morph_data);
								//morph_data.Render(new nme.display.DebugGfx(),0.5);
								disp_object = morph;
							
							case charStaticText(text):
								var s = new Shape();
								text.Render(s.graphics);
								disp_object = s;
							
							case charEditText(text):
								var t = new TextField();
								text.Apply(t);
								disp_object = t;
							
							case charBitmap(shape):
								throw("Adding bitmap?");
							
							case charFont(font):
								throw("Adding font?");
							
						}
					}
					
					#if have_swf_depth
					// On neko, we can z-sort by using our special field ...
					disp_object.__swf_depth = depth;
					#end
					
					var added = false;
					// todo : binary converge ?
					for(cid in 0...numChildren)
					{
						#if have_swf_depth
						
						var child_depth = getChildAt(cid).__swf_depth;
						
						#else
						
						var child_depth = -1;
						var sought = getChildAt(cid);
						
						for (child in new_active)
							if (child.mObj == sought)
							{
								child_depth = child.mDepth;
								break;
							}
						#end
						
						if (child_depth > depth)
						{
							addChildAt(disp_object, cid);
							added = true;
							break;
						}
					}
					
					if (!added)
						addChild(disp_object);
					
					var idx = slot.FindClosestFrame(0, mCurrentFrame);
					slot.mAttribs[idx].Apply(disp_object);
					
					var act = { mObj: disp_object, mDepth: depth, mIndex: idx, mID: slot.mID, mWaitingLoader: waiting_loader };
					
					new_active.push(act);
					depth_changed = true;
				}
				
				mActive = new_active;
			}
			
		}
		
	}
	
	
	
	
	// Event Listeners
	
	
	
	
	private function this_onEnterFrame(event:Event):Void
	{
		if (mPlaying)
		{
			mCurrentFrame++;
			if (mCurrentFrame > mTotalFrames)
			mCurrentFrame = 1;
			// trace(mMovieID + "  OnEnterFrame " + mCurrentFrame);
			updateActive();
		}
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetCurrentFrame() { return mCurrentFrame; }
	private function nmeGetTotalFrames() { return mTotalFrames; }

}



typedef ActiveObject =
{
   var mObj:flash.display.DisplayObject;
   var mDepth : Int;
   var mID: Int;
   var mIndex : Int;
   var mWaitingLoader : Bool;
}

typedef ActiveObjects = Array<ActiveObject>;

typedef ObjectList = List<DisplayObject>;
typedef ObjectPool = IntHash<ObjectList>;


#else
typedef MovieClip = flash.display.MovieClip;
#end