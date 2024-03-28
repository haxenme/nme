#include <Display.h>
#include <Surface.h>
#include <math.h>

#include "TextField.h"
#include "Sound.h"

#ifdef ANDROID
#include <android/log.h>
#endif


namespace nme
{

   
// --- Stage ---------------------------------------------------------------


// Helper class....
class AutoStageRender
{
   Surface *mSurface;
   Stage   *mToFlip;
   RenderTarget mTarget;
public:
   AutoStageRender(Stage *inStage,int inRGB)
   {
      mSurface = inStage->GetPrimarySurface();
      mToFlip = inStage;
      mTarget = mSurface->BeginRender( Rect(mSurface->Width(),mSurface->Height()),false );

      mSurface->Clear( (inRGB | 0xff000000) & inStage->getBackgroundMask() );
   }
   int Width() const { return mSurface->Width(); }
   int Height() const { return mSurface->Height(); }
   ~AutoStageRender()
   {
      mSurface->EndRender();
      mToFlip->Flip();
   }
   const RenderTarget &Target() { return mTarget; }
};

Stage *Stage::gCurrentStage = 0;
Stage *Stage::gPrimaryStage = 0;

Stage::Stage(bool inInitRef) : DisplayObjectContainer(inInitRef)
{
   gCurrentStage = this;
   if (!gPrimaryStage)
      gPrimaryStage = this;
   mHandler = 0;
   mHandlerData = 0;
   mMouseHandler = 0;
   mMouseHandlerData = 0;
   opaqueBackground = 0xffffffff;
   mFocusObject = 0;
   mMouseDownObject = 0;
   mSimpleButton = 0;
   focusRect = true;
   mLastMousePos = UserPoint(0,0);
   scaleMode = ssmShowAll;
   mNominalWidth = 100;
   mNominalHeight = 100;
   mNextWake = 0.0;
   displayState = sdsNormal;
   align = saTopLeft;

   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
   quality = sqLow;
   #else
   quality = sqBest;
   #endif
}

Stage::~Stage()
{
   if (gCurrentStage==this)
      gCurrentStage = 0;
   if (gPrimaryStage==this)
      gPrimaryStage = 0;
   if (mFocusObject)
      mFocusObject->DecRef();
   if (mMouseDownObject)
      mMouseDownObject->DecRef();
}

void Stage::SetNextWakeDelay(double inNextWake)
{
   mNextWake = inNextWake + GetTimeStamp();
}

HardwareRenderer *Stage::getHardwareRenderer()
{
   Surface *surface = GetPrimarySurface();
   if (!surface)
      return nullptr;
   return surface->GetHardwareRenderer();
}


bool Stage::hasHardwareLcdFonts() const
{
   HardwareRenderer *hw = (const_cast<Stage *>(this))->getHardwareRenderer();
   if (!hw)
      return false;
   return hw->supportsComponentAlpha();
}

void Stage::SetFocusObject(DisplayObject *inObj,FocusSource inSource,int inKey)
{
   if (inObj==mFocusObject)
      return;

   if (mHandler)
   {
      Event focus(etFocus);
      focus.id = inObj ? inObj->id : 0;
      focus.value = inSource;
      focus.code = inKey;
   
      mHandler(focus,mHandlerData);

      if (inSource!=fsProgram && focus.result==erCancel)
         return;
   }


   if (!inObj || inObj->getStage()!=this)
   {
      if (mFocusObject)
      {
         mFocusObject->Unfocus();
         mFocusObject->DecRef();
      }
      mFocusObject = 0;
   }
   else
   {
      inObj->IncRef();
      if (mFocusObject)
      {
         mFocusObject->Unfocus();
         mFocusObject->DecRef();
      }
      mFocusObject = inObj;
      inObj->Focus();
   }

}

void Stage::SetNominalSize(int inWidth, int inHeight)
{
   mNominalWidth = inWidth;
   mNominalHeight = inHeight;
   CalcStageScaling( getStageWidth(), getStageHeight() );
}


void Stage::SetEventHandler(EventHandler inHander,void *inUserData)
{
   mHandler = inHander;
   mHandlerData = inUserData;
}


void Stage::SetMouseEventHandler(EventHandler inHander,void *inUserData)
{
   mMouseHandler = inHander;
   mMouseHandlerData = inUserData;
}

void Stage::HandleEvent(Event &inEvent)
{
   gCurrentStage = this;
   DisplayObject *hit_obj = 0;

   if ( mMouseHandler && ( inEvent.type==etMouseMove || inEvent.type==etMouseDown ||
         inEvent.type==etMouseUp || inEvent.type==etMouseClick ||
         inEvent.type==etTouchBegin || inEvent.type==etTouchEnd || 
         inEvent.type==etTouchMove || inEvent.type==etTouchTap )
       )
   {
      int was = inEvent.x;
      mMouseHandler(inEvent, mMouseHandlerData);
   }


   bool primary = inEvent.flags & efPrimaryTouch;

   if ( (inEvent.type==etMouseMove || inEvent.type==etMouseDown ||
         inEvent.type==etTouchBegin || inEvent.type==etTouchMove  )
            && primary )
      mLastMousePos = UserPoint(inEvent.x, inEvent.y);


   if (mMouseDownObject && primary)
   {
      switch(inEvent.type)
      {
         case etTouchMove:
         case etMouseMove:
            if (inEvent.flags & efLeftDown)
            {
               mMouseDownObject->Drag(inEvent);
               break;
            }
            // fallthrough
         case etMouseClick:
         case etMouseDown:
         case etMouseUp:
         case etTouchBegin:
         case etTouchTap:
         case etTouchEnd:
            mMouseDownObject->EndDrag(inEvent);
            mMouseDownObject->DecRef();
            mMouseDownObject = 0;
            break;
         default: break;
      }
   }

   if (inEvent.type==etKeyDown || inEvent.type==etKeyUp || inEvent.type==etChar)
   {
      inEvent.id = mFocusObject ? mFocusObject->id : id;
      if (mHandler)
         mHandler(inEvent,mHandlerData);
      if (inEvent.result==0 && mFocusObject)
         mFocusObject->OnKey(inEvent);
      #ifdef ANDROID
      // Non-cancelled back key ...
      if (inEvent.result==0 && inEvent.value==27 && inEvent.type == etKeyUp)
      {
          StopAnimation();
      }
      #endif
      return;
   }

   if (inEvent.type==etResize)
   {
      CalcStageScaling( inEvent.x, inEvent.y);
   }

   if (inEvent.type==etActivate)
   {
      #ifdef NME_AUDIO
      Sound::Resume();
      #endif
   }
   else if (inEvent.type==etDeactivate)
   {
      #ifdef NME_AUDIO
      Sound::Suspend();
      #endif
   }

   if (inEvent.type==etMouseMove || inEvent.type==etMouseDown ||
         inEvent.type==etMouseUp || inEvent.type==etMouseClick ||
         inEvent.type==etTouchBegin || inEvent.type==etTouchEnd ||
         inEvent.type==etTouchMove || inEvent.type==etTouchTap ||
         inEvent.type==etDropEnd
       )
   {
      UserPoint pixels(inEvent.x,inEvent.y);
      hit_obj = HitTest(pixels);
      //if (inEvent.type!=etTouchMove)
        //ELOG("  type=%d %d,%d obj=%p (%S)", inEvent.type, inEvent.x, inEvent.y, hit_obj, hit_obj?hit_obj->name.c_str():L"(none)");

      SimpleButton *but = hit_obj ? dynamic_cast<SimpleButton *>(hit_obj) : 0;
      inEvent.id = hit_obj ? hit_obj->id : id;
      Cursor cur = hit_obj ? hit_obj->GetCursor() : curPointer;

      if (mSimpleButton && (inEvent.flags & efLeftDown) )
      {
         // Don't change simple button if dragging ...
      }
      else if (but!=mSimpleButton)
      {
         if (but)
            but->IncRef();
         if (mSimpleButton)
         {
            SimpleButton *s = mSimpleButton;
            mSimpleButton = 0;
            s->setMouseState(SimpleButton::stateUp);
            s->DecRef();
         }
         mSimpleButton = but;
      }

      if (mSimpleButton)
      {
         bool over = but==mSimpleButton;
         bool down =  (inEvent.flags & efLeftDown);
         mSimpleButton->setMouseState( over ? ( down ?
             SimpleButton::stateDown : SimpleButton::stateOver) : SimpleButton::stateUp );
         if (!down && !over)
         {
            SimpleButton *s = mSimpleButton;
            mSimpleButton = 0;
            s->DecRef();
         }
         else if (mSimpleButton->getUseHandCursor())
            cur = curHand;
      }

      SetCursor( (gMouseShowCursor || cur>=curTextSelect0) ? cur : curNone );

      UserPoint stage = mStageScale.ApplyInverse(pixels);
      inEvent.x = stage.x;
      inEvent.y = stage.y;
   }


   if (hit_obj)
      hit_obj->IncRef();

   if (mHandler)
      mHandler(inEvent,mHandlerData);

   if (hit_obj)
   {
      if ( (inEvent.type==etMouseDown ||
            (inEvent.type==etTouchBegin && (inEvent.flags & efPrimaryTouch) ))
           && inEvent.result!=erCancel )
      {
         if (hit_obj->WantsFocus())
            SetFocusObject(hit_obj,fsMouse);
         #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
         else
         {
            PopupKeyboard(pkmOff);
            SetFocusObject(0,fsMouse);
         }
         #endif
      }
   
      if (inEvent.type==etMouseDown || (inEvent.type==etTouchBegin && primary) )
      {
         if (hit_obj->CaptureDown(inEvent))
         {
            hit_obj->IncRef();
            mMouseDownObject = hit_obj;
         }
      }
      if (inEvent.type==etMouseUp && (inEvent.value==3 || inEvent.value==4) )
      {
         TextField *text =  dynamic_cast<TextField *>(hit_obj);
         if (text && text->getMouseWheelEnabled() )
            text->OnScrollWheel(-inEvent.deltaY);
      }
   }
   #if defined(IPHONE) || defined(ANDROID) || defined(WEBOS) || defined(TIZEN)
   else if (inEvent.type==etMouseClick ||  inEvent.type==etMouseDown ||
         (inEvent.type==etTouchBegin && (inEvent.flags & efPrimaryTouch) ))
   {
      PopupKeyboard(pkmOff);
      SetFocusObject(0);
   }
   #endif
 
   
   if (hit_obj)
      hit_obj->DecRef();
}

void Stage::onTextFieldText(const std::string &inText, int inPos0, int inPos1)
{
   if (mFocusObject)
   {
      TextField *field = dynamic_cast<TextField *>(mFocusObject);
      if (field)
         field->onTextUpdate(inText, inPos0, inPos1);
   }
}

void Stage::onTextFieldSelect(int inPos0, int inPos1)
{
   if (mFocusObject)
   {
      TextField *field = dynamic_cast<TextField *>(mFocusObject);
      if (field)
         field->onTextSelect(inPos0, inPos1);
   }
}


void Stage::setOpaqueBackground(uint32 inBG)
{
   opaqueBackground = inBG | 0xff000000;
   DirtyCache();
}


void Stage::RemovingFromStage(DisplayObject *inObject)
{
   DisplayObject *b = mSimpleButton;
   while(b)
   {
      if (b==inObject)
      {
         mSimpleButton->DecRef();
         mSimpleButton = 0;
         break;
      }
      b = b->getParent();
   }


   DisplayObject *f = mFocusObject;
   while(f)
   {
      if (f==inObject)
      {
         mFocusObject->DecRef();
         mFocusObject = 0;
         break;
      }
      f = f->getParent();
   }

   DisplayObject *m = mMouseDownObject;
   while(m)
   {
      if (m==inObject)
      {
         mMouseDownObject->DecRef();
         mMouseDownObject = 0;
         break;
      }
      m = m->getParent();
   }

}


void Stage::CalcStageScaling(double inNewWidth,double inNewHeight)
{
   double StageScaleX=1;
   double StageScaleY=1;
   double StageOX=0;
   double StageOY=0;
   if (inNewWidth<=0 || inNewHeight<=0)
      return;

   if (scaleMode!=ssmNoScale)
   {
      StageScaleX = inNewWidth/(double)mNominalWidth;
      StageScaleY = inNewHeight/(double)mNominalHeight;

      if (scaleMode==ssmNoBorder)
      {
         if (StageScaleX>StageScaleY)
            StageScaleY = StageScaleX;
         else
            StageScaleX = StageScaleY;
      }
      else if (scaleMode==ssmShowAll)
      {
         if (StageScaleX<StageScaleY)
            StageScaleY = StageScaleX;
         else
            StageScaleX = StageScaleY;
      }

   }

   double extra_x = inNewWidth-StageScaleX*mNominalWidth;
   double extra_y = inNewHeight-StageScaleY*mNominalHeight;

   switch(align)
   {
      case saTopLeft: break;
      case saLeft: break;
      case saBottomLeft: break;
      case saTopRight:
      case saRight:
      case saBottomRight:
         StageOX = int(extra_x);
         break;
      case saTop:
      case saBottom:
      case saCentre:
      case saGame:
      case saGamePixels:
      case saGameStretch:
         StageOX = int(extra_x/2);
         break;
   }

   switch(align)
   {
      case saTopLeft: break;
      case saTopRight: break;
      case saTop: break;
      case saBottomRight:
      case saBottomLeft:
      case saBottom:
         StageOY = int(extra_y);
         break;
      case saLeft:
      case saRight:
      case saCentre:
      case saGame:
      case saGamePixels:
      case saGameStretch:
         StageOY = int(extra_y/2);
         break;
   }
   DirtyCache();

   mStageScale.m00 = StageScaleX;
   mStageScale.m11 = StageScaleY;
   mStageScale.mtx = StageOX;
   mStageScale.mty = StageOY;
}


bool Stage::FinishEditOnEnter()
{
   if (mFocusObject && mFocusObject!=this)
      return mFocusObject->FinishEditOnEnter();
   return false;
}

int Stage::GetAA()
{
   switch(quality)
   {
      case sqLow: return 1;
      case sqMedium: return 2;
      case sqHigh:
      case sqBest:
         return 4;
   }
   return 1;
}


void Stage::BeginRenderStage(bool inClear)
{
   Surface *surface = GetPrimarySurface();
   currentTarget = surface->BeginRender( Rect(surface->Width(),surface->Height()),false );
   if (inClear)
      surface->Clear( (opaqueBackground | 0xff000000) & getBackgroundMask() );
}

void Stage::RenderStage()
{
   ColorTransform::TidyCache();

   if (currentTarget.IsHardware())
      currentTarget.mHardware->SetQuality(quality);

   RenderState state(0, GetAA() );

   state.mTransform.mMatrix = &mStageScale;

   int w = currentTarget.Width();
   int h = currentTarget.Height();
   if (align==saGame)
   {
      int ox = mStageScale.mtx;
      int oy = mStageScale.mty;
      // Rounding?
      int sw = w-ox*2;
      int sh = h-oy*2;
      state.mClipRect = Rect(ox, oy, sw, sh);
   }
   else
   {
      state.mClipRect = Rect(w,h);
   }

   state.mPhase = rpBitmap;
   state.mRoundSizeToPOW2 = currentTarget.IsHardware();
   Render(currentTarget,state);

   state.mPhase = rpRender;
   Render(currentTarget,state);
}

void Stage::EndRenderStage()
{
   currentTarget = RenderTarget();
   GetPrimarySurface()->EndRender();
   ClearCacheDirty();
   Flip();
}


bool Stage::BuildCache()
{
   Surface *surface = GetPrimarySurface();
   RenderState state(surface, GetAA() );
   state.mTransform.mMatrix = &mStageScale;
   bool wasDirty = false;
   state.mWasDirtyPtr = &wasDirty;

   state.mPhase = rpBitmap;

   RenderTarget target(state.mClipRect, surface->GetHardwareRenderer());
   state.mRoundSizeToPOW2 = surface->GetHardwareRenderer();
   Render(target,state);

   return wasDirty;
}

double Stage::getStageWidth()
{
   Surface *s = GetPrimarySurface();
   if (!s) return 0;
   return s->Width();
}

double Stage::getStageHeight()
{
   Surface *s = GetPrimarySurface();
   if (!s) return 0;
   return s->Height();
}


void Stage::setScaleMode(int inMode)
{
   scaleMode = (StageScaleMode)inMode;
   CalcStageScaling( getStageWidth(), getStageHeight() );
}

void Stage::setAlign(int inAlign)
{
   align = (StageAlign)inAlign;
   CalcStageScaling( getStageWidth(), getStageHeight() );
}

void Stage::setQuality(int inQuality)
{
   quality = (StageQuality)inQuality;
   DirtyCache();
}

void Stage::setDisplayState(int inDisplayState)
{
   displayState = (StageDisplayState)inDisplayState;
   SetFullscreen(inDisplayState>0);
}


Matrix Stage::GetFullMatrix(bool inStageScaling)
{
   if (!inStageScaling)
      return DisplayObject::GetFullMatrix(false);

   return mStageScale.Mult(GetLocalMatrix());
}
  


DisplayObject *Stage::HitTest(UserPoint inStage,DisplayObject *inRoot,bool inRecurse)
{
   Surface *surface = GetPrimarySurface();

   RenderTarget target = surface->BeginRender( Rect(surface->Width(),surface->Height()),true );

   RenderState state(0, GetAA() );
   state.mClipRect = Rect( inStage.x, inStage.y, 1, 1 );
   Matrix m = mStageScale;
   if (inRoot)
      m = inRoot->GetFullMatrix(true);
   state.mTransform.mMatrix = &m;


   state.mRoundSizeToPOW2 = target.IsHardware();
   state.mPhase = rpHitTest;
   state.mRecurse = inRecurse;

   (inRoot ? inRoot : this) -> Render(target,state);

   surface->EndRender();

   // ELOG("Stage hit %f,%f -> %p\n", inStage.x, inStage.y, state.mHitResult );

   return state.mHitResult;
}



} // end namespace nme


