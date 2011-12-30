package nme.format.swf;

import nme.display.DisplayObject;
import nme.display.Shape;
import nme.events.Event;
import nme.text.TextField;

import nme.format.swf.SWF;
import nme.format.swf.Sprite;
import nme.format.swf.Frame;

#if flash

typedef MovieClipBase = flash.display.Sprite;

#else

typedef MovieClipBase = nme.display.MovieClip;

#end


typedef ActiveObject =
{
   var mObj: flash.display.DisplayObject;
   var mDepth : Int;
   var mID: Int;
   var mIndex : Int;
   var mWaitingLoader : Bool;
}

typedef ActiveObjects = Array<ActiveObject>;

typedef ObjectList = List<DisplayObject>;
typedef ObjectPool = IntHash<ObjectList>;


// Available for both flash and neko.
// For neko, this is the actual movie clip, for flash this is an
//  extension that allows a "data driven" swf, since there does not seem
//  to be any other easy way to setup a timeline.

class MovieClip extends MovieClipBase
{
   var mSWF    : SWF;
   var mFrames : nme.format.swf.Frames;
   var mActive : ActiveObjects;
   var mPlaying: Bool;
   var mObjectPool:ObjectPool;

   
   static var mMovieID = 0;
   static var mIDBase = 1;

#if flash
   var mCurrentFrame:Int;
   var mTotalFrames:Int;
#end

   public function new()
   {
      super();

#if flash
      mCurrentFrame = 1;
      mTotalFrames = 1;
#end

      mObjectPool = new ObjectPool();
      mMovieID = mIDBase++;
      mPlaying = false;
      addEventListener(Event.ENTER_FRAME, MyOnEnterFrame);
   }

   public function MyOnEnterFrame(inEvent:Event)
   {
      if (mPlaying)
      {
         mCurrentFrame++;
         if (mCurrentFrame > mTotalFrames)
           mCurrentFrame = 1;
         // trace(mMovieID + "  OnEnterFrame " + mCurrentFrame);
         UpdateActive();
      }
   }

   #if !flash override #end
   public function gotoAndPlay(frame:Dynamic, ?scene:String):Void
   {
      mCurrentFrame = frame;
      UpdateActive();
      mPlaying = true;
   }

   #if !flash override #end
   public function gotoAndStop(frame:Dynamic, ?scene:String):Void
   {
      mCurrentFrame = frame;
      UpdateActive();
      mPlaying = false;
   }

   #if !flash override #end
   public function play( ) : Void { mPlaying = true; }

   #if !flash override #end
   public function stop( ) : Void { mPlaying = false; }


   static var count = 0;
   function UpdateActive()
   {
      if (mFrames!=null)
      {
         var frame = mFrames[mCurrentFrame];
         var depth_changed = false;
         var waiting_loader = false;


         if (frame!=null)
         {
            var frame_objs = frame.CopyObjectSet();

            // Remove or update child frames in the existing list ...
            var new_active = new ActiveObjects();
            for(a in mActive)
            {
               var depth_slot = frame_objs.get( a.mDepth );

               if (depth_slot==null || depth_slot.mID != a.mID || a.mWaitingLoader)
               {
                  // Add object to pool - if it's complete.
                  if (!a.mWaitingLoader)
                  {
                     var pool = mObjectPool.get(a.mID);
                     if (pool == null)
                     {
                        pool = new ObjectList();
                        mObjectPool.set(a.mID, pool );
                     }
                     pool.push( a.mObj );
                  }
                  // todo - disconnect event handlers ?
                  removeChild(a.mObj);
               }
               else
               {
                  // remove from our "todo" list
                  frame_objs.remove(a.mDepth);

                  a.mIndex = depth_slot.FindClosestFrame(a.mIndex,mCurrentFrame);
                  var attrib = depth_slot.mAttribs[a.mIndex];
                  attrib.Apply(a.mObj);
                  new_active.push(a);
               }
            }


            // Now add missing characters in unfilled depth slots
            for(depth in frame_objs.keys())
            {
               var slot = frame_objs.get(depth);
               var disp_object:flash.display.DisplayObject = null;
               var pool = mObjectPool.get(slot.mID);
               if (pool != null && pool.length > 0)
               {
                   disp_object = pool.pop();
                   switch(slot.mCharacter)
                   {
                      case charSprite(sprite):
                         var clip:nme.format.swf.MovieClip = untyped disp_object;
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
                         var movie = new nme.format.swf.MovieClip();
                         movie.CreateFromSWF(sprite);
                         disp_object = movie;

                      case charShape(shape):
                         var s = new flash.display.Shape();
                          //trace( s );
                         //shape.Render(new nme.display.DebugGfx());
                         waiting_loader = shape.Render(s.graphics);
                         disp_object = s;

                      case charMorphShape(morph_data):
                         var morph = new nme.format.swf.MorphObject(morph_data);
                         //morph_data.Render(new nme.display.DebugGfx(),0.5);
                         disp_object = morph;

                      case charStaticText(text):
                         var s = new flash.display.Shape();
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
                  for(child in new_active)
                     if (child.mObj==sought)
                     {
                        child_depth = child.mDepth;
                        break;
                     }
                  #end

                  if (child_depth > depth)
                  {
                     addChildAt(disp_object,cid);
                     added = true;
                     break;
                  }
               }
               if (!added)
                  addChild(disp_object);

               var idx = slot.FindClosestFrame(0,mCurrentFrame);
               slot.mAttribs[idx].Apply(disp_object);

               var act =
                  { mObj:disp_object, mDepth:depth, mIndex:idx, mID:slot.mID, 
                          mWaitingLoader:waiting_loader };

               new_active.push(act);
               depth_changed = true;
            }

            mActive = new_active;
         }
      }
   }

   public function CreateFromSWF(inSprite:nme.format.swf.Sprite)
   {
      mTotalFrames = mCurrentFrame = inSprite.GetFrameCount();

      mSWF = inSprite.mSWF;
      mFrames= inSprite.mFrames;
      mActive = new ActiveObjects();

      gotoAndPlay(1);
   }
}


