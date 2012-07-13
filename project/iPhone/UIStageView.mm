//
//  UIStageView.mm
//  Blank
//
//  Created by Hugh on 12/01/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>
#include <Utils.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


using namespace nme;

void EnableKeyboard(bool inEnable);
extern "C" void nme_app_set_active(bool inActive);

namespace nme { int gFixedOrientation = -1; }


@interface NMEAppDelegate : NSObject <UIApplicationDelegate>
{
   UIWindow *window;
   UIViewController *controller;
   BOOL isRunning;
   BOOL isPaused;
}
- (void) setActive:(BOOL)isActive;
- (void) startAnimation;
- (void) pauseAnimation;
- (void) resumeAnimation;
- (void) stopAnimation;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *controller;

@end


@interface UIStageViewController : UIViewController
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)loadView;
@end


// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface UIStageView : UIView<UITextFieldDelegate,UIAccelerometerDelegate>
{    
@private
   BOOL animating;
   BOOL displayLinkSupported;
   id displayLink;
   NSInteger animationFrameInterval;
   NSTimer *animationTimer;
   int    mPrimaryEvent;
@public
   class IOSStage *mStage;

   UITextField *mTextField;
   UIAccelerometer *mAccelerometer;
   double mAccX;
   double mAccY;
   double mAccZ;
   BOOL mKeyboardEnabled;
   bool   mMultiTouch;
   int    mPrimaryTouchHash;
}


@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (void) myInit;
- (void) drawView:(id)sender;
- (void) onPoll:(id)sender;
- (void) enableKeyboard:(bool)withEnable;
- (void) enableMultitouch:(bool)withEnable;
- (BOOL)canBecomeFirstResponder;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

@end

// Global instance ...
UIStageView *sgMainView = nil;
static FrameCreationCallback sOnFrame = nil;
static bool sgHardwareRendering = true;



const void* imageDataProviderGetBytePointer(void* imageData)
{
    return imageData;
}

void deleteImageData(void*, const void* imageData)
{
}

CGDataProviderDirectCallbacks providerCallbacks =
    { 0, imageDataProviderGetBytePointer, deleteImageData, 0, 0 };


// --- Stage Implementaton ------------------------------------------------------


class IOSSurf : public Surface
{
public:
   int mWidth;
   int mHeight;
   unsigned char *mBuffer;

   IOSSurf() { }
   ~IOSSurf() { }

   int Width() const  { return mWidth; }
   int Height() const  { return mHeight; }
   PixelFormat Format()  const { return pfXRGB; }
   const uint8 *GetBase() const { return (const uint8 *)mBuffer; }
   int GetStride() const { return mWidth*4; }
   void Clear(uint32 inColour,const nme::Rect *inRect)
   {
      nme::Rect r = inRect ? *inRect : nme::Rect(Width(),Height());
      int y1 = r.y1();
      //printf("Clear %d,%d %dx%d   %08x\n", r.x, r.y, r.w, r.h, inColour);
      for(int y=r.y;y<y1;y++)
      {
         uint32 *row = (uint32 *)(mBuffer + (y*mWidth+r.x)*4 );
         if ( (inColour&0xffffff)==0 )
            memset(row,0,r.w*4);
         else if ( (inColour&0xffffff)==0xffffff )
            memset(row,255,r.w*4);
         else
           for(int x=0;x<r.w;x++)
               *row++ = inColour;
      }
   }

   RenderTarget BeginRender(const nme::Rect &inRect)
   {
      return RenderTarget(nme::Rect(Width(),Height()), Format(), (uint8 *)mBuffer, mWidth*4);
   }
   void EndRender() { }

   void BlitTo(const RenderTarget &outTarget,
               const nme::Rect &inSrcRect,int inPosX, int inPosY,
               BlendMode inBlend, const BitmapCache *inMask,
               uint32 inTint=0xffffff ) const
   {
   }
	void BlitChannel(const RenderTarget &outTarget, const nme::Rect &inSrcRect,
									 int inPosX, int inPosY,
									 int inSrcChannel, int inDestChannel ) const
	{
	}

   void StretchTo(const RenderTarget &outTarget,
          const nme::Rect &inSrcRect, const DRect &inDestRect) const
   {
   }
};



class IOSStage : public nme::Stage
{
public:

   unsigned char *mImageData[2];
   int mRenderBuffer;
   IOSSurf *mSoftwareSurface;
   CGColorSpaceRef colorSpace;

   IOSStage(CALayer *inLayer,bool inInitRef) : nme::Stage(inInitRef)
   {
      defaultFramebuffer = 0;
      colorRenderbuffer = 0;
      mHardwareContext = 0;
      mHardwareSurface = 0;
      mLayer = inLayer;
      mDPIScale = 1.0;
      mOGLContext = 0;
      mImageData[0] = 0;
      mImageData[1] = 0;
      mRenderBuffer = 0;
      mSoftwareSurface = 0;
      colorSpace = CGColorSpaceCreateDeviceRGB();

      if (sgHardwareRendering)
      {
         mOGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
         if (!mOGLContext || ![EAGLContext setCurrentContext:mOGLContext])
         {
            throw "Could not initilize OpenL";
         }
 
         CreateOGLFramebuffer();
      
         #ifndef OBJC_ARC
         mHardwareContext = HardwareContext::CreateOpenGL(inLayer, mOGLContext);
         #else
         mHardwareContext = HardwareContext::CreateOpenGL((__bridge void *)inLayer, (__bridge void *)mOGLContext);
         #endif
         mHardwareContext->IncRef();
         mHardwareContext->SetWindowSize(backingWidth, backingHeight);
         mHardwareSurface = new HardwareSurface(mHardwareContext);
         mHardwareSurface->IncRef();
      }
      else
      {
         mSoftwareSurface = new IOSSurf();
         CreateImageBuffers();
      }
   }

   double getDPIScale() { return mDPIScale; }


   ~IOSStage()
   {
      if (mOGLContext)
      {
         if (mHardwareSurface)
            mHardwareSurface->DecRef();
         if (mHardwareContext)
            mHardwareContext->DecRef();
         // Tear down GL
         if (defaultFramebuffer)
         {
            glDeleteFramebuffersOES(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
         }

         if (colorRenderbuffer)
         {
            glDeleteRenderbuffersOES(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
         }
   
         // Tear down context
         if ([EAGLContext currentContext] == mOGLContext)
            [EAGLContext setCurrentContext:nil];

         #ifndef OBJC_ARC
         [mOGLContext release];
         #endif
      }
      else
      {
          DestroyImageBuffers();
          delete mSoftwareSurface;
      }
   }

   bool getMultitouchSupported() { return true; }

   void setMultitouchActive(bool inActive)
   {
      [ sgMainView enableMultitouch:inActive ];

   }
   bool getMultitouchActive()
   {
      return sgMainView->mMultiTouch;
   }

   bool isOpenGL() const { return mOGLContext; }

   void RenderState()
   {
      if ( [sgMainView isAnimating] )
         nme::Stage::RenderStage();
   }



   void CreateOGLFramebuffer()
   {
      // Create default framebuffer object.
      // The backing will be allocated for the current layer in -resizeFromLayer
      glGenFramebuffersOES(1, &defaultFramebuffer);
      glGenRenderbuffersOES(1, &colorRenderbuffer);
      glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
      glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
      [mOGLContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)mLayer];
      glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES,
                                  GL_RENDERBUFFER_OES, colorRenderbuffer);
   
      glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
      glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

      //printf("Create OGL window %dx%d\n", backingWidth, backingHeight);
       
       int framebufferStatus = glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES);

      if (framebufferStatus != GL_FRAMEBUFFER_COMPLETE_OES)
      {
         NSLog(@"Failed to make complete framebuffer object %x",
              glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
         throw "OpenGL resize failed";
      }
   }
   
   
  void DestroyOGLFramebuffer()
   {
      if (defaultFramebuffer)
         glDeleteFramebuffersOES(1, &defaultFramebuffer);
      defaultFramebuffer = 0;
      if (colorRenderbuffer)
         glDeleteRenderbuffersOES(1, &colorRenderbuffer);
      defaultFramebuffer = 0;
   }

   void CreateImageBuffers()
   {
      backingWidth = [mLayer bounds].size.width;
      backingHeight = [mLayer bounds].size.height;

      mSoftwareSurface->mWidth = backingWidth;
      mSoftwareSurface->mHeight = backingHeight;

      int size = backingWidth*backingHeight*4;

      for(int b=0;b<2;b++)
      {
         mImageData[b] = new unsigned char[size];
      }
   }
   
   void OnSoftwareResize(CALayer *inLayer)
   {
      DestroyImageBuffers();
      CreateImageBuffers();

      Event evt(etResize);
      evt.x = backingWidth;
      evt.y = backingHeight;
      HandleEvent(evt);
   }

   void OnOGLResize(CAEAGLLayer *inLayer)
   {   
      // Recreate frame buffers ..
      [EAGLContext setCurrentContext:mOGLContext];
      DestroyOGLFramebuffer();
      CreateOGLFramebuffer();

      mHardwareContext->SetWindowSize(backingWidth,backingHeight);

      //printf("OnOGLResize %dx%d\n", backingWidth, backingHeight);
      Event evt(etResize);
      evt.x = backingWidth;
      evt.y = backingHeight;
      HandleEvent(evt);

   }
   
   void DestroyImageBuffers()
   {
      for(int i=0;i<2;i++)
      {
         delete [] mImageData[i];
         mImageData[i] = 0;
      }
   }

   void OnRedraw()
   {
      Event evt(etRedraw);
      HandleEvent(evt);
   }

   void OnPoll()
   {
      Event evt(etPoll);
      HandleEvent(evt);
   }

   void OnEvent(Event &inEvt)
   {
      HandleEvent(inEvt);
   }

   void OnMouseEvent(Event &inEvt)
   {
      inEvt.x *= mDPIScale;
      inEvt.y *= mDPIScale;
      HandleEvent(inEvt);
   }

   void Flip()
   {
       // printf("flip %d\n", mRenderBuffer);
       if (sgHardwareRendering)
       {
         glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
         [mOGLContext presentRenderbuffer:GL_RENDERBUFFER_OES];
       }
       else
       {
          int size = backingWidth*backingHeight*4;
          CGDataProviderRef dataProvider = CGDataProviderCreateDirect(mImageData[mRenderBuffer], size, &providerCallbacks);

          CGImageRef imageRef = CGImageCreate( backingWidth, backingHeight,
                8, 32, backingWidth*4, colorSpace,
                kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                dataProvider, 0, false, kCGRenderingIntentDefault);

          #ifdef HXCPP_CLANG // this cast currently does not build.
          //mLayer.contents = objc_unretainedObject(imageRef);
          #else
            mLayer.contents = (objc_object*)imageRef;
          #endif


          CGDataProviderRelease(dataProvider);

          CGImageRelease(imageRef);

          mRenderBuffer = 1-mRenderBuffer;
       }
   }

   void GetMouse()
   {
      // TODO
   }

   
   Surface *GetPrimarySurface()
   {
      if (mHardwareSurface)
         return mHardwareSurface;
      mSoftwareSurface->mBuffer = mImageData[ mRenderBuffer ];
      return mSoftwareSurface;
   }

   void SetCursor(nme::Cursor)
   {
      // No cursors on iPhone !
   }

   void EnablePopupKeyboard(bool inEnable)
   {
      ::EnableKeyboard(inEnable);
   }



  // --- IRenderTarget Interface ------------------------------------------
   int Width() { return backingWidth; }
   int Height() { return backingHeight; }

   //double getStageWidth() { return backingWidth; }
   //double getStageHeight() { return backingHeight; }



   EventHandler mHandler;
   void *mHandlerData;


   EAGLContext *mOGLContext;
   CALayer *mLayer;
   HardwareSurface *mHardwareSurface;
   HardwareContext *mHardwareContext;


   // The pixel dimensions of the CAEAGLLayer
   GLint backingWidth;
   GLint backingHeight;
   double mDPIScale;
   
   // The OpenGL names for the framebuffer and renderbuffer used to render to this view
   GLuint defaultFramebuffer, colorRenderbuffer;

};


// --- UIStageViewController ----------------------------------------------------------



@implementation UIStageViewController

#define UIInterfaceOrientationPortraitMask (1 << UIInterfaceOrientationPortrait)
#define UIInterfaceOrientationLandscapeLeftMask  (1 << UIInterfaceOrientationLandscapeLeft)
#define UIInterfaceOrientationLandscapeRightMask  (1 << UIInterfaceOrientationLandscapeRight)
#define UIInterfaceOrientationPortraitUpsideDownMask  (1 << UIInterfaceOrientationPortraitUpsideDown)
   
#define UIInterfaceOrientationLandscapeMask   (UIInterfaceOrientationLandscapeLeftMask | UIInterfaceOrientationLandscapeRightMask)
#define UIInterfaceOrientationAllMask  (UIInterfaceOrientationPortraitMask | UIInterfaceOrientationLandscapeLeftMask | UIInterfaceOrientationLandscapeRightMask | UIInterfaceOrientationPortraitUpsideDownMask)
#define UIInterfaceOrientationAllButUpsideDownMask  (UIInterfaceOrientationPortraitMask | UIInterfaceOrientationLandscapeLeftMask | UIInterfaceOrientationLandscapeRightMask)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
   if (gFixedOrientation >= 0)
      return interfaceOrientation == gFixedOrientation;
   Event evt(etShouldRotate);
   evt.value = interfaceOrientation;
   sgMainView->mStage->OnEvent(evt);
   return evt.result == 2;
}

- (NSUInteger)supportedInterfaceOrientations
{
   int mask = 1;
   bool isOverridden = false;

   if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft]) {
      isOverridden = true;
      mask = UIInterfaceOrientationLandscapeLeftMask;
   }

   if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeRight]) {
      if (isOverridden) {
         mask |= UIInterfaceOrientationLandscapeRightMask;
      } else {
         isOverridden = true;
         mask = UIInterfaceOrientationLandscapeRightMask;
      }
   }

   if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown]) {
      if (isOverridden) {
         mask |= UIInterfaceOrientationPortraitUpsideDownMask;
      } else {
         isOverridden = true;
         mask = UIInterfaceOrientationPortraitUpsideDownMask;
      }
   }

   if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortrait]) {
      if (isOverridden) {
         mask |= UIInterfaceOrientationPortraitMask;
      } else {
         isOverridden = true;
         mask = UIInterfaceOrientationPortraitMask;
      }
   }

   if (!isOverridden) {
      mask = UIInterfaceOrientationAllMask;
   }
   return mask;
}

- (void)loadView
{
   UIStageView *view = [[UIStageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   self.view = view;
}

@end




// --- UIStageView -------------------------------------------------------------------

@implementation UIStageView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class) layerClass
{
   if (sgHardwareRendering)
      return [CAEAGLLayer class];
   else
      return [super layerClass];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:

- (id) initWithCoder:(NSCoder*)coder
{    
   if ((self = [super initWithCoder:coder]))
   {
      sgMainView = self;
      [self myInit];
      return self;
   }
   return nil;
}

// For when we init programatically...
- (id) initWithFrame:(CGRect)frame
{    
   if ((self = [super initWithFrame:frame]))
   {
      sgMainView = self;
      self.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight;
      [self myInit];
      return self;
   }
   return nil;
}


- (void) myInit
{
      // Get the layer
      if (sgHardwareRendering)
      {
         CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

         eaglLayer.opaque = TRUE;
         eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                         kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                         nil];
      }

      mStage = new IOSStage(self.layer,true);

      // Set scaling to ensure 1:1 pixels ...
      if([[UIScreen mainScreen] respondsToSelector: NSSelectorFromString(@"scale")])
      {
	      if([self respondsToSelector: NSSelectorFromString(@"contentScaleFactor")])
	      {
		      mStage->mDPIScale = [[UIScreen mainScreen] scale];
		      self.contentScaleFactor = mStage->mDPIScale;
	      }
      }

  
      mAccelerometer = [UIAccelerometer sharedAccelerometer];
      mAccelerometer.updateInterval = 0.033;
      mAccelerometer.delegate = self;
     
      mAccX = 0.0;
      mAccY = -1.0;
      mAccZ = 0.0;
      animating = FALSE;
      displayLinkSupported = FALSE;
      animationFrameInterval = 1;
      displayLink = nil;
      animationTimer = nil;
      mTextField = nil;
      mKeyboardEnabled = NO;
      
      mMultiTouch = false;
      mPrimaryTouchHash = 0;


      // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
      // class is used as fallback when it isn't available.
      /*
      NSString *reqSysVer = @"3.1";
      NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
      if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
         displayLinkSupported = TRUE;
      */

      displayLinkSupported = FALSE;

/*
      Event evt(etResize);
      evt.x = mStage->Width();
      evt.y = mStage->Height();
      mStage->HandleEvent(evt);
*/
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
   mAccX = acceleration.x;
   mAccY = acceleration.y;
   mAccZ = acceleration.z;
}


- (BOOL)canBecomeFirstResponder { return YES; }


/* UITextFieldDelegate method.  Invoked when user types something. */

- (BOOL)textField:(UITextField *)_textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

   if ([string length] == 0)
   {
      /* SDL hack to detect delete */
      Event key_down(etKeyDown);
      key_down.code = keyBACKSPACE;
      key_down.value = keyBACKSPACE;
      mStage->OnEvent(key_down);

      Event key_up(etKeyUp);
      key_up.code = keyBACKSPACE;
      key_up.value = keyBACKSPACE;
      mStage->OnEvent(key_up);
   }
   else
   {
      /* go through all the characters in the string we've been sent
         and convert them to key presses */
      for(int i=0; i<[string length]; i++)
      {
         unichar c = [string characterAtIndex: i];

         Event key_down(etKeyDown);
         key_down.code = c;
         key_down.value = c;
         mStage->OnEvent(key_down);
         
         Event key_up(etKeyUp);
         key_up.code = c;
         key_up.value = c;
         mStage->OnEvent(key_up);
      }
   }

   return NO; /* don't allow the edit! (keep placeholder text there) */
}

/* Terminates the editing session */
- (BOOL)textFieldShouldReturn:(UITextField*)_textField {
   if (mStage->FinishEditOnEnter())
   {
      mStage->SetFocusObject(0);
      [self enableKeyboard:NO];
      return YES;
   }

   // Fake a return character...

   Event key_down(etKeyDown);
   key_down.value = keyENTER;
   key_down.code = keyENTER;
   mStage->OnEvent(key_down);

   Event key_up(etKeyUp);
   key_up.value = keyENTER;
   key_up.code = keyENTER;
   mStage->OnEvent(key_up);
 
   return NO;
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   NSArray *touchArr = [touches allObjects];
   NSInteger touchCnt = [touchArr count];

   for(int i=0;i<touchCnt;i++)
   {
      UITouch *aTouch = [touchArr objectAtIndex:i];

      CGPoint thumbPoint;
      thumbPoint = [aTouch locationInView:aTouch.view];
      //printf("touchesBegan %d x %d!\n", (int)thumbPoint.x, (int)thumbPoint.y);

      if (mPrimaryTouchHash==0)
         mPrimaryTouchHash = [aTouch hash];

      if (mMultiTouch)
      {
         Event mouse(etTouchBegin, thumbPoint.x, thumbPoint.y);
         mouse.value = [aTouch hash];
         if (mouse.value==mPrimaryTouchHash)
            mouse.flags |= efPrimaryTouch;
         mStage->OnMouseEvent(mouse);
      }
      else
      {
         Event mouse(etMouseDown, thumbPoint.x, thumbPoint.y);
         mouse.flags |= efLeftDown;
         mouse.flags |= efPrimaryTouch;
         mStage->OnMouseEvent(mouse);
      }

   }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
   NSArray *touchArr = [touches allObjects];
   NSInteger touchCnt = [touchArr count];

   for(int i=0;i<touchCnt;i++)
   {
      UITouch *aTouch = [touchArr objectAtIndex:i];

      CGPoint thumbPoint;
      thumbPoint = [aTouch locationInView:aTouch.view];

      if (mMultiTouch)
      {
         Event mouse(etTouchMove, thumbPoint.x, thumbPoint.y);
         mouse.value = [aTouch hash];
         if (mouse.value==mPrimaryTouchHash)
            mouse.flags |= efPrimaryTouch;
         mStage->OnMouseEvent(mouse);
      }
      else
      {
         Event mouse(etMouseMove, thumbPoint.x, thumbPoint.y);
         mouse.flags |= efLeftDown;
         mouse.flags |= efPrimaryTouch;
         mStage->OnMouseEvent(mouse);
      }
   }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
   NSArray *touchArr = [touches allObjects];
   NSInteger touchCnt = [touchArr count];

   for(int i=0;i<touchCnt;i++)
   {
      UITouch *aTouch = [touchArr objectAtIndex:i];

      CGPoint thumbPoint;
      thumbPoint = [aTouch locationInView:aTouch.view];
//printf("touchesEnd %d x %d!\n", (int)thumbPoint.x, (int)thumbPoint.y);

      if (mMultiTouch)
      {
         Event mouse(etTouchEnd, thumbPoint.x, thumbPoint.y);
         mouse.value = [aTouch hash];
         if (mouse.value==mPrimaryTouchHash)
         {
            mouse.flags |= efPrimaryTouch;
            mPrimaryTouchHash = 0;
         }
         mStage->OnMouseEvent(mouse);
      }
      else
      {
         Event mouse(etMouseUp, thumbPoint.x, thumbPoint.y);
         mouse.flags |= efPrimaryTouch;
         mStage->OnMouseEvent(mouse);
      }
   }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
   [self touchesEnded:touches withEvent:event];
}

- (void) enableMultitouch:(bool)withEnable
{
   mMultiTouch = withEnable;
   if (mMultiTouch)
      [self setMultipleTouchEnabled:YES];
   else
      [self setMultipleTouchEnabled:NO];
}


- (void) enableKeyboard:(bool)withEnable
{
   if (mKeyboardEnabled!=withEnable)
   {
       mKeyboardEnabled = withEnable;
       if (mKeyboardEnabled)
       {
          // Setup a dummy textfield to make iPhone think we have a text field - but
          //  delegate all the events to ourselves..
          if (mTextField==nil)
          {
             #ifndef OBJC_ARC
             mTextField = [[[UITextField alloc] initWithFrame: CGRectMake(0,0,0,0)] autorelease];
             #else
             mTextField = [[UITextField alloc] initWithFrame: CGRectMake(0,0,0,0)];
             #endif

             mTextField.delegate = self;
             /* placeholder so there is something to delete! (from SDL code) */
             mTextField.text = @" ";   
   
             /* set UITextInputTrait properties, mostly to defaults */
             mTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
             mTextField.autocorrectionType = UITextAutocorrectionTypeNo;
             mTextField.enablesReturnKeyAutomatically = NO;
             mTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
             mTextField.keyboardType = UIKeyboardTypeDefault;
             mTextField.returnKeyType = UIReturnKeyDefault;
             mTextField.secureTextEntry = NO;   
             mTextField.hidden = YES;

	     [self addSubview: mTextField];

          }
          [mTextField becomeFirstResponder];
       }
       else
       {
          [mTextField resignFirstResponder];
       }
   }
}


- (void) drawView:(id)sender
{
   mStage->OnRedraw();
}

- (void) onPoll:(id)sender
{
   mStage->OnPoll();
}


- (void) layoutSubviews
{
   if (sgHardwareRendering)
      mStage->OnOGLResize((CAEAGLLayer*)self.layer);
   else
      mStage->OnSoftwareResize(self.layer);
}

#ifndef OBJC_ARC
- (void) dealloc
{
    if (mStage) mStage->DecRef();
    if (mTextField)
       [mTextField release];
   
    [super dealloc];
}
#endif

@end


double sgWakeUp = 0.0;

// --- NMEAppDelegate ----------------------------------------------------------

class UIViewFrame : public nme::Frame
{
public:
   virtual void SetTitle()  { }
   virtual void SetIcon() { }
   virtual Stage *GetStage()  { return sgMainView->mStage; }

};

@implementation NMEAppDelegate

@synthesize window;
@synthesize controller;

namespace nme {}

- (void) applicationDidFinishLaunching:(UIApplication *)application
{
   UIWindow *win = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   window = win;
   [window makeKeyAndVisible];
   UIStageViewController  *c = [[UIStageViewController alloc] init];
   controller = c;
   [win addSubview:c.view];
   self.window.rootViewController = c;
   nme_app_set_active(true);
   application.idleTimerDisabled = YES;
   sOnFrame( new UIViewFrame() );
}

- (void) mainLoop {
   isRunning = YES;
   while (isRunning) {
      while(CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, TRUE) == kCFRunLoopRunHandledSource);

      /*if (paused) {
         usleep(250000); // Sleep for a quarter of a second (250,000 microseconds) so that the framerate is 4 fps.
      }*/
      
      sgMainView->mStage->OnPoll();
      
      while(CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, TRUE) == kCFRunLoopRunHandledSource);
   }
   /*while(!sgTerminated)
   {
       double delta = sgMainView->mStage->GetNextWake() - GetTimeStamp();
       if (delta<0) delta = 0;
       if (CFRunLoopRunInMode(kCFRunLoopDefaultMode,delta,TRUE) != kCFRunLoopRunHandledSource)
       {
          sgMainView->mStage->OnPoll();
       }
   }*/
}

- (void) startAnimation
{
   if (!isPaused)
      [self performSelectorOnMainThread:@selector(mainLoop) withObject:nil waitUntilDone:NO];
}

- (void) pauseAnimation
{
   isPaused = YES;
   [self stopAnimation];
}

- (void) resumeAnimation
{
   isPaused = NO;
   [self startAnimation];
}

- (void) stopAnimation
{
   isRunning = NO;
}

- (void) setActive:(BOOL)isActive
{
   if (isActive) {
      [self startAnimation];
   } else {
      [self stopAnimation];
   }
   nme_app_set_active(isActive);
}

- (void) applicationWillResignActive:(UIApplication *)application {[self setActive:false];} 
- (void) applicationDidBecomeActive:(UIApplication *)application {[self setActive:true];} 
- (void) applicationWillTerminate:(UIApplication *)application {[self setActive:false];} 

#ifndef OBJC_ARC
- (void) dealloc
{
   [window release];
   [controller release];
   [super dealloc];
}
#endif

@end



// --- Extenal Interface -------------------------------------------------------

void EnableKeyboard(bool inEnable)
{
   [ sgMainView enableKeyboard:inEnable];
}


/*
 These aren't part of the offical SDK
extern "C"
{
   extern int *_NSGetArgc(void);
   extern char ***_NSGetArgv(void);
};
*/


namespace nme
{
Stage *IPhoneGetStage() { return sgMainView->mStage; }

void StartAnimation() {
   NMEAppDelegate *appDelegate = (NMEAppDelegate *)[[UIApplication sharedApplication] delegate];
   [appDelegate startAnimation];
}
void PauseAnimation() {
   NMEAppDelegate *appDelegate = (NMEAppDelegate *)[[UIApplication sharedApplication] delegate];
   [appDelegate pauseAnimation];
}
void ResumeAnimation() {
   NMEAppDelegate *appDelegate = (NMEAppDelegate *)[[UIApplication sharedApplication] delegate];
   [appDelegate resumeAnimation];
}
void StopAnimation() {
   NMEAppDelegate *appDelegate = (NMEAppDelegate *)[[UIApplication sharedApplication] delegate];
   [appDelegate stopAnimation];
}
void SetNextWakeUp(double inWakeUp) { sgWakeUp = inWakeUp; }

int GetDeviceOrientation() {

	return ( [UIDevice currentDevice].orientation );
}

double CapabilitiesGetPixelAspectRatio() {
	
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	return screenBounds.size.width / screenBounds.size.height;
	
}
	
double CapabilitiesGetScreenDPI() {
	CGFloat screenScale = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        screenScale = [[UIScreen mainScreen] scale];
    }
    float dpi;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        dpi = 132 * screenScale;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        dpi = 163 * screenScale;
    } else {
        dpi = 160 * screenScale;
    }
    
	return dpi;
}

double CapabilitiesGetScreenResolutionX() {

	CGRect screenBounds = [[UIScreen mainScreen] bounds];
   if([[UIScreen mainScreen] respondsToSelector: NSSelectorFromString(@"scale")])
   {
   	CGFloat screenScale = [[UIScreen mainScreen] scale];
   	CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
   	return screenSize.width;
   }
   return screenBounds.size.width;
}
	
double CapabilitiesGetScreenResolutionY() {

	CGRect screenBounds = [[UIScreen mainScreen] bounds];
   if([[UIScreen mainScreen] respondsToSelector: NSSelectorFromString(@"scale")])
   {
   	CGFloat screenScale = [[UIScreen mainScreen] scale];
   	CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
   	return screenSize.height;
   }
   return screenBounds.size.height;	
}	
	
	
void CreateMainFrame(FrameCreationCallback inCallback,
   int inWidth,int inHeight,unsigned int inFlags, const char *inTitle, Surface *inIcon )
{
   sOnFrame = inCallback;
   int argc = 0;// *_NSGetArgc();
   char **argv = 0;// *_NSGetArgv();

   sgHardwareRendering = (inFlags & wfHardware );
   //printf("Flags %08x %d\n", inFlags, sgHardwareRendering);
   if (!sgHardwareRendering)
      gC0IsRed = false;


   #ifndef OBJC_ARC
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
   #endif
   UIApplicationMain(argc, argv, nil, @"NMEAppDelegate");
   #ifndef OBJC_ARC
   [pool release];
   #endif
}

bool GetAcceleration(double &outX, double &outY, double &outZ)
{
#ifdef IPHONESIM
   return false;
#else
   if (!sgMainView)
      return false;
   outX = sgMainView->mAccX;
   outY = sgMainView->mAccY;
   outZ = sgMainView->mAccZ;
   return true;
#endif
}


// Since you can't write data in your bundle, I think you need to save user data
// under a different file name to avoid confilcts.
// getPathForResource does not work in sub-directories on iPod 3.1.3
// "resourcePath" is soooo much nicer.
FILE *OpenRead(const char *inName)
{
   FILE *result = 0;

   if (inName[0]=='/')
   {
      result = fopen(inName,"rb");
   }
   else
   {
      std::string asset = GetResourcePath() + gAssetBase + inName;
      //printf("Try asset %s.\n", asset.c_str());
      result = fopen(asset.c_str(),"rb");

      if (!result)
      {
         std::string doc;
		 GetSpecialDir(DIR_USER, doc);
		 doc += gAssetBase + inName;
         //printf("Try doc %s.\n", doc.c_str());
         result = fopen(doc.c_str(),"rb");
      }
   }
   //printf("%s -> %p\n", inName, result);
   return result;
}



//[ddc]
FILE *OpenOverwrite(const char *inName)
{
    std::string asset = gAssetBase + inName;
    NSString *str = [[NSString alloc] initWithUTF8String:asset.c_str()];

    NSString *strWithoutInitialDash;    
    if([str hasPrefix:@"/"]){
     strWithoutInitialDash = [str substringFromIndex:1];
     }
     else {
     strWithoutInitialDash = str;
     }

    //NSLog(@"file name I'm wrinting to = %@", strWithoutInitialDash);
    
    //NSString *path = [[NSBundle mainBundle] pathForResource:str ofType:nil];
    NSString  *path = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingString: @"/"] stringByAppendingString: strWithoutInitialDash];
    //NSLog(@"path name I'm wrinting to = %@", path);
    

	if ( ! [[NSFileManager defaultManager] fileExistsAtPath: [path stringByDeletingLastPathComponent]] ) {
        //NSLog(@"directory doesn't exist, creating it");
		[[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES  attributes:nil error:NULL];
	}

    FILE * result = fopen([path cStringUsingEncoding:1],"w");
    #ifndef OBJC_ARC
    [str release];
    #endif
    return result;
}

}

extern "C"
{

void nme_app_set_active(bool inActive)
{
   if (IPhoneGetStage())
   {
      Event evt(inActive ? etActivate : etDeactivate);
      IPhoneGetStage()->HandleEvent(evt);
   }

   if (inActive)
      nme::StartAnimation();
   else
      nme::StopAnimation();
}


}
