//
//  UIStageView.mm
//  Blank
//
//  Created by Hugh on 12/01/10.
//


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CADisplayLink.h>
#import <CoreMotion/CMMotionManager.h>
#import <MediaPlayer/MediaPlayer.h>

#include <Display.h>
#include <Surface.h>
#include <KeyCodes.h>
#include <Utils.h>

  //https://gist.github.com/Jaybles/1323251#comment-791121
#include "UIDeviceHardware.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include <StageVideo.h>

using namespace nme;

extern "C" void nme_app_set_active(bool inActive);

namespace nme { int gFixedOrientation = -1; }

// viewWillDisappear

#ifdef HXCPP_DEBUG
   #define APP_LOG NSLog
#else
   #define APP_LOG(x) { }
#endif


#ifndef IPHONESIM
CMMotionManager *sgCmManager = 0;
#endif
bool sgHasAccelerometer = false;

class NMEStage;

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface NMEView : UIView<UITextFieldDelegate>
{    
@private


   int      mRenderBuffer;
   bool     multisampling;
   bool     multisamplingEnabled;

   CAEAGLLayer      *mLayer;
   //[ddc] antialiasing code taken from:
   // http://www.gandogames.com/2010/07/tutorial-using-anti-aliasing-msaa-in-the-iphone/
   // http://is.gd/oHLipb
   // https://devforums.apple.com/thread/45850
   // Buffer definitions for the MSAA
   GLuint          msaaFramebuffer;
   GLuint          msaaRenderBuffer;
   GLuint          msaaDepthBuffer;


@public
   class NMEStage *mStage;
   UITextField    *mTextField;
   BOOL           mKeyboardEnabled;
   bool           mMultiTouch;
   int            mPrimaryTouchHash;
   double         dpiScale;


  // The OpenGL names for the framebuffer and renderbuffer used to render to this view
   GLuint          defaultFramebuffer;
   GLuint          colorRenderbuffer;
   GLuint          depthStencilBuffer;



   // The pixel dimensions of the CAEAGLLayer
   EAGLContext     *mOGLContext;
   GLint           backingWidth;
   GLint           backingHeight;
   HardwareSurface *mHardwareSurface;
   HardwareRenderer *mHardwareRenderer;
}



- (void) setupStageLayer:(NMEStage *)inStage;
- (void) drawView:(id)sender;
- (void) enableKeyboard:(bool)withEnable;
- (void) enableMultitouch:(bool)withEnable;
- (BOOL) canBecomeFirstResponder;
+ (unichar) translateASCIICodeToKeyCode:(unichar)asciiCode;
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) makeCurrent:(bool)withMultisampling;

- (void) createOGLFramebuffer;
- (void) destroyOGLFramebuffer;
- (void) recreateOGLFramebuffer;
@end


// --- NMEAnimationController ----------------------

@interface NMEAnimationController : NSObject
{
   NMEStage   *stage;
   BOOL       animating;
   CADisplayLink   *displayLink;
   NSInteger  animationFrameInterval;
}
- (id)   initWithStage:(NMEStage *)inStage;
- (void) startAnimation;
- (void) stopAnimation;
- (void) mainLoop:(id) sender;
@end


NMEAnimationController *sgAnimationController=0;


// --- Stage Implementaton ------------------------------------------------------
//
// The stage acts as the controller between the NME view and the NME application.
//  It passes events as sets properties as required

class NMEStage : public nme::Stage
{
public:

   EventHandler mHandler;
   void *mHandlerData;


   UIView         *container;
   UIView         *playerView;
   NMEView        *nmeView;
   class IOSVideo *video;

   bool           popupEnabled;
   bool           multiTouchEnabled;
   bool           haveOpaqueBg;
   bool           wantOpaqueBg;
   bool           needRecreateOGLFramebuffer;

   NMEStage(CGRect inRect);
   ~NMEStage();

   UIView *getRootView() { return container; }
   bool getMultitouchSupported() { return true; }
   bool isOpenGL() const { return nmeView->mOGLContext; }
   Surface *GetPrimarySurface() { return nmeView->mHardwareSurface; }
   void SetCursor(nme::Cursor) { /* No cursors on iPhone ! */ }
   void PopupKeyboard(PopupKeyboardMode inEnable,WString *);
   double getDPIScale() { return nmeView->dpiScale; }

   int getWindowFrameBufferId() { return nmeView->defaultFramebuffer; };



   StageVideo *createStageVideo(void *);
   void       onVideoPlay();
   CGRect     getViewBounds();
   void       setOpaqueBackground(uint32 inBG);
   uint32     getBackgroundMask();
   void       recreateNmeView();
   void       updateSize(int inWidth, int inHeight);



   void setMultitouchActive(bool inActive);
   bool getMultitouchActive();


   void OnOGLResize(int width, int height);
   void OnRedraw();
   void OnEvent(Event &inEvt);
   void Flip();
   void GetMouse() { }

   // --- IRenderTarget Interface ------------------------------------------
   int Width() { return nmeView->backingWidth; }
   int Height() { return nmeView->backingHeight; }

};

NMEStage *sgNmeStage = 0;



// Wrapper for nme 'frame' class
class IOSViewFrame : public nme::Frame
{
public:
   Stage *stage;

   IOSViewFrame(Stage *inStage) : stage(inStage) { }

   virtual Stage *GetStage()  { return stage; }

};


// --- NMEAnimationController -------------------------------------------------------------------

static NSString *sgDisplayLinkMode = NSRunLoopCommonModes;

@implementation NMEAnimationController

- (id) initWithStage:(NMEStage *)inStage
{
   APP_LOG(@"initWithStage");
   animationFrameInterval = 1;
   stage = inStage;

   displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(mainLoop:)];
   [displayLink setFrameInterval:animationFrameInterval];

   animating = true;
   [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:sgDisplayLinkMode];
   return self;
}

- (void) startAnimation
{
   APP_LOG(@"startAnimation");
   if (!animating)
   {
      displayLink.paused = NO;
      animating = true;
   }
}

- (void) stopAnimation
{
   if (animating)
   {
      displayLink.paused = NO;
      animating = false;
   }
}

- (void) mainLoop:(id) sender
{
   if (animating)
   {
      if (stage->nmeView->mOGLContext && [EAGLContext currentContext] != stage->nmeView->mOGLContext)
         [EAGLContext setCurrentContext:stage->nmeView->mOGLContext];
     
      if (stage->needRecreateOGLFramebuffer)
         [stage->nmeView recreateOGLFramebuffer];

      Event evt(etPoll);
      stage->OnEvent(evt);
   }
}


@end



// Global instance ...

static FrameCreationCallback sOnFrame = nil;
static bool sgAllowShaders = false;
static bool sgHasDepthBuffer = true;
static bool sgHasStencilBuffer = true;
static bool sgEnableMSAA2 = true;
static bool sgEnableMSAA4 = true;
static std::string nmeTitle;

// --- NMEView -------------------------------------------------------------------

@implementation NMEView


// You must implement this method
+ (Class) layerClass
{
  return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:

- (id) initWithCoder:(NSCoder*)coder
{    
   NSLog(@"NME View init with coder - not supported");
   if ((self = [super initWithCoder:coder]))
   {
      //return self;
   }
   return nil;
    
}

// For when we init programatically...
- (id) initWithFrame:(CGRect)frame
{    
   APP_LOG(@"initWithFrame");
   if ((self = [super initWithFrame:frame]))
   {
      dpiScale = 1.0;
      //printf("Init with frame %fx%f", frame.size.width, frame.size.height );
      self.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight;
      //[self myInit];
      return self;
   }
   return nil;
}


- (void) setupStageLayer:(NMEStage *)inStage
{
   APP_LOG(@"setupStageLayer");
   //printf("--- NMEView layer ----\n");
   mStage = inStage;

   defaultFramebuffer = 0;
   colorRenderbuffer = 0;
   depthStencilBuffer = 0;
   mHardwareRenderer = 0;
   mHardwareSurface = 0;
   mLayer = 0;
   mOGLContext = 0;
   mRenderBuffer = 0;

   //todo ; rather expose this hardware value as a function
   //and they can disable AA selectively on devices themselves 
   //rather than hardcoding it here.
   multisampling = sgEnableMSAA2 || sgEnableMSAA4;



   // Get the layer
   mLayer = (CAEAGLLayer *)self.layer;

   mLayer.opaque = mStage->wantOpaqueBg;

   mLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                   kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                   nil];

   // Set scaling to ensure 1:1 pixels ...
   if([[UIScreen mainScreen] respondsToSelector: NSSelectorFromString(@"scale")])
   {
      if([self respondsToSelector: NSSelectorFromString(@"contentScaleFactor")])
      {
         dpiScale = [[UIScreen mainScreen] scale];
         self.contentScaleFactor = dpiScale;
      }
   }

  
   mTextField = nil;
   mKeyboardEnabled = NO;
   
   mMultiTouch = false;
   mPrimaryTouchHash = 0;


   if (sgAllowShaders)
   {
      mOGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
   }
   else
   {
      mOGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
   }
   
   if (!mOGLContext || ![EAGLContext setCurrentContext:mOGLContext])
   {
      throw "Could not initilize OpenGL";
   }
 
   //printf("createOGLFramebuffer...\n");
   [self createOGLFramebuffer];

   #ifndef OBJC_ARC
   mHardwareRenderer = HardwareRenderer::CreateOpenGL(mLayer, mOGLContext, sgAllowShaders);
   #else
   mHardwareRenderer = HardwareRenderer::CreateOpenGL((__bridge void *)mLayer, (__bridge void *)mOGLContext, sgAllowShaders);
   #endif
   mHardwareRenderer->IncRef();
   mHardwareRenderer->SetWindowSize(backingWidth, backingHeight);

   mHardwareSurface = new HardwareSurface(mHardwareRenderer);
   mHardwareSurface->IncRef();
}


- (void)didMoveToWindow
{
   //printf("didMoveToWindow %p\n", self.window);
   nme_app_set_active(self.window!=nil);
}

- (BOOL)canBecomeFirstResponder { return YES; }


+ (unichar)translateASCIICodeToKeyCode:(unichar)asciiCode
{
   // Map lowercase letters to uppercase equivalent
   // ASCII codes for uppercase letters match their keycodes
   if (asciiCode >= 97 && asciiCode <= 122)
   {
      asciiCode -= 32;
   }
   
   switch (asciiCode)
   {
      /* 0-31 are control codes */
      case 10: return keyENTER;
      case 13: return keyENTER;
      /* 32 is a space, maps to self */
      case 33: return keyNUMBER_1;
      case 34: return keyQUOTE;
      case 35: return keyNUMBER_3;
      case 36: return keyNUMBER_4;
      case 37: return keyNUMBER_5;
      case 38: return keyNUMBER_7;
      case 39: return keyQUOTE;
      case 40: return keyNUMBER_9;
      case 41: return keyNUMBER_0;
      case 42: return keyNUMBER_2;
      case 43: return keyEQUAL;
      case 44: return keyCOMMA;
      case 45: return keyMINUS;
      case 46: return keyPERIOD;
      case 47: return keySLASH;
      /* 48-57 are digits, map to self */
      case 58: return keySEMICOLON;
      case 59: return keySEMICOLON;
      case 60: return keyCOMMA;
      case 61: return keyEQUAL;
      case 62: return keyPERIOD;
      case 63: return keySLASH;
      case 64: return keyNUMBER_2;
      /* 65-90 are uppercase letters, map to self */
      case 91: return keyLEFTBRACKET;
      case 92: return keyBACKSLASH;
      case 93: return keyRIGHTBRACKET;
      case 94: return keyNUMBER_6;
      case 95: return keyMINUS;
      case 96: return keyBACKQUOTE;
      /* 97-122 are lowercase letters, handled above */
      case 123: return keyLEFTBRACKET;
      case 124: return keyBACKSLASH;
      case 125: return keyRIGHTBRACKET;
      case 126: return keyBACKQUOTE;
      default: return asciiCode;
   }
}


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
         unichar v = [NMEView translateASCIICodeToKeyCode: c];

         Event key_down(etKeyDown);
         key_down.code = c;
         key_down.value = v;
         mStage->OnEvent(key_down);
         
         Event text_input(etChar);
         text_input.code = c;
         mStage->OnEvent(text_input);
         
         Event key_up(etKeyUp);
         key_up.code = c;
         key_up.value = v;
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
         Event mouse(etTouchBegin, thumbPoint.x*dpiScale, thumbPoint.y*dpiScale);
         mouse.value = [aTouch hash];
         if (mouse.value==mPrimaryTouchHash)
            mouse.flags |= efPrimaryTouch;
         mStage->OnEvent(mouse);
      }
      else
      {
         Event mouse(etMouseDown, thumbPoint.x*dpiScale, thumbPoint.y*dpiScale);
         mouse.flags |= efLeftDown;
         mouse.flags |= efPrimaryTouch;
         mStage->OnEvent(mouse);
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
         Event mouse(etTouchMove, thumbPoint.x*dpiScale, thumbPoint.y*dpiScale);
         mouse.value = [aTouch hash];
         if (mouse.value==mPrimaryTouchHash)
            mouse.flags |= efPrimaryTouch;
         mStage->OnEvent(mouse);
      }
      else
      {
         Event mouse(etMouseMove, thumbPoint.x*dpiScale, thumbPoint.y*dpiScale);
         mouse.flags |= efLeftDown;
         mouse.flags |= efPrimaryTouch;
         mStage->OnEvent(mouse);
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
         Event mouse(etTouchEnd, thumbPoint.x*dpiScale, thumbPoint.y*dpiScale);
         mouse.value = [aTouch hash];
         if (mouse.value==mPrimaryTouchHash)
         {
            mouse.flags |= efPrimaryTouch;
            mPrimaryTouchHash = 0;
         }
         mStage->OnEvent(mouse);
      }
      else
      {
         Event mouse(etMouseUp, thumbPoint.x*dpiScale, thumbPoint.y*dpiScale);
         mouse.flags |= efPrimaryTouch;
         mStage->OnEvent(mouse);
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


- (void) createOGLFramebuffer
{
   APP_LOG(@"createOGLFramebuffer");
   // Create default framebuffer object.
   // The backing will be allocated for the current layer in -resizeFromLayer
   if (sgAllowShaders)
   {
      glGenFramebuffers(1, &defaultFramebuffer);
      glGenRenderbuffers(1, &colorRenderbuffer);
      glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
      glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
      
      [mOGLContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)mLayer];
      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
      
      //fetch the values of size first
      glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
      glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
      
      //Create the depth / stencil buffers
      if (sgHasDepthBuffer && !sgHasStencilBuffer)
      {
         //printf("NMEView :: Creating Depth buffer. \n");
         //Create just the depth buffer
         glGenRenderbuffers(1, &depthStencilBuffer);
         glBindRenderbuffer(GL_RENDERBUFFER, depthStencilBuffer);
         glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
         glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthStencilBuffer);
      }
      else if (sgHasDepthBuffer && sgHasStencilBuffer)
      {
         //printf("NMEView :: Creating Depth buffers. \n");
         //printf("NMEView :: Creating Stencil buffers. \n");
         
         //Create the depth/stencil buffer combo
         glGenRenderbuffers(1, &depthStencilBuffer);
         glBindRenderbuffer(GL_RENDERBUFFER, depthStencilBuffer);
         glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, backingWidth, backingHeight);
         glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthStencilBuffer);
         glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, depthStencilBuffer);    
      }
      else
      {
         //printf("NMEView :: No depth/stencil buffer requested. \n");
      }
      
      //printf("Create OGL window %dx%d\n", backingWidth, backingHeight);
      
      // [ddc]
      // code taken from:
      // http://www.gandogames.com/2010/07/tutorial-using-anti-aliasing-msaa-in-the-iphone/
      // http://is.gd/oHLipb
      // https://devforums.apple.com/thread/45850
      // Generate and bind our MSAA Frame and Render buffers
      if (multisampling)
      {
         glGenFramebuffers(1, &msaaFramebuffer);
         glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
         glGenRenderbuffers(1, &msaaRenderBuffer);
         glBindRenderbuffer(GL_RENDERBUFFER, msaaRenderBuffer);
         
         glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, (sgEnableMSAA4 ? 4 : 2) , GL_RGB5_A1, backingWidth, backingHeight);
         glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, msaaRenderBuffer);
         glGenRenderbuffers(1, &msaaDepthBuffer);
         
         multisamplingEnabled = true;
         
      }
      else
      {
         multisamplingEnabled = false;
      }
      
      int framebufferStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
      
      if (framebufferStatus != GL_FRAMEBUFFER_COMPLETE)
      {
         NSLog(@"Failed to make complete framebuffer object %x",
         glCheckFramebufferStatus(GL_FRAMEBUFFER));
         throw "OpenGL resize failed";
      }
   }
   else
   {
      glGenFramebuffersOES(1, &defaultFramebuffer);
      glGenRenderbuffersOES(1, &colorRenderbuffer);
      glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
      glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
      
      [mOGLContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)mLayer];
      
      glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
      
      glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
      glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
      
      if (sgHasDepthBuffer && !sgHasStencilBuffer)
      {
         //Create just the depth buffer
         glGenRenderbuffersOES(1, &depthStencilBuffer);
         glBindRenderbufferOES(GL_RENDERBUFFER, depthStencilBuffer);
         glRenderbufferStorageOES(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
         glFramebufferRenderbufferOES(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthStencilBuffer);
         
      }
      else if (sgHasDepthBuffer)
      {
         //Create the depth/stencil buffer combo
         glGenRenderbuffersOES(1, &depthStencilBuffer);
         glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthStencilBuffer);
         glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH24_STENCIL8_OES, backingWidth, backingHeight);
         glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER, depthStencilBuffer);
         glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_STENCIL_ATTACHMENT_OES, GL_RENDERBUFFER, depthStencilBuffer);          
      }
      
      //printf("Create OGL window %dx%d\n", backingWidth, backingHeight);
      
      // [ddc]
      // code taken from:
      // http://www.gandogames.com/2010/07/tutorial-using-anti-aliasing-msaa-in-the-iphone/
      // http://is.gd/oHLipb
      // https://devforums.apple.com/thread/45850
      // Generate and bind our MSAA Frame and Render buffers
      if (multisampling)
      {
         glGenFramebuffersOES(1, &msaaFramebuffer);
         glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer);
         glGenRenderbuffersOES(1, &msaaRenderBuffer);
         glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaRenderBuffer);
         
         glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, (sgEnableMSAA4 ? 4 : 2) , GL_RGB5_A1_OES, backingWidth, backingHeight);
         glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, msaaRenderBuffer);
         glGenRenderbuffersOES(1, &msaaDepthBuffer);
         
         multisamplingEnabled = true;
      }
      else
      {
         multisamplingEnabled = false;
      }
      
      int framebufferStatus = glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES);
      
      if (framebufferStatus != GL_FRAMEBUFFER_COMPLETE_OES)
      {
         NSLog(@"Failed to make complete framebuffer object %x",
         glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
         throw "OpenGL resize failed";
      }
   }
}

- (void) destroyOGLFramebuffer
{
   if (defaultFramebuffer)
   {
      if (sgAllowShaders)
      {
         glDeleteFramebuffers(1, &defaultFramebuffer);
      }
      else
      {
         glDeleteFramebuffersOES(1, &defaultFramebuffer);
      }
   }
   defaultFramebuffer = 0;
   if (colorRenderbuffer)
   {
      if (sgAllowShaders)
      {
         glDeleteRenderbuffers(1, &colorRenderbuffer);
      }
      else
      {
         glDeleteRenderbuffersOES(1, &colorRenderbuffer);
      }
   }
   defaultFramebuffer = 0;

   if (depthStencilBuffer)
   {
      if (sgAllowShaders)
      {
         glDeleteRenderbuffers(1, &depthStencilBuffer);
      }
      else
      {
         glDeleteRenderbuffersOES(1, &depthStencilBuffer);
      }
      depthStencilBuffer = 0;
   }
}

- (void) makeCurrent :(bool)withMultisampling
{
   [EAGLContext setCurrentContext:mOGLContext];

   bool multisamplingEnabledNow = withMultisampling;
   
   if (multisampling && multisamplingEnabled != multisamplingEnabledNow)
   {
      multisamplingEnabled = multisamplingEnabledNow;
      if (multisamplingEnabled)
      {
         if (sgAllowShaders)
         {
            glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, msaaRenderBuffer);
         }
         else
         {
            glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer);
            glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaRenderBuffer);
         }
      }
      else
      {
         if (sgAllowShaders)
         {
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
            glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
         }
         else
         {
            glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
            glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
         }
      }
   }
   
   if (multisampling && multisamplingEnabled)
   {
      if (sgAllowShaders)
      {
         glBindFramebuffer(GL_FRAMEBUFFER, msaaFramebuffer);  
      }
      else
      {
         glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer);
      }
   }
}



- (void) tearDown
{
   // TODO: Mouse events.

   if (mStage)
   {
      // only holds a dumb reference since lifetime will be shorter
      //mStage->DecRef();
      mStage = 0;
   }

   if (mTextField)
   {
      [mTextField release];
      mTextField = nil;
   }
 

   [self enableKeyboard:false];

   if (mHardwareSurface)
   {
      mHardwareSurface->DecRef();
      mHardwareSurface = 0;
   }
   if (mHardwareRenderer)
   {
      mHardwareRenderer->DecRef();
      mHardwareRenderer = 0;
   }

   [self destroyOGLFramebuffer];

   if (mOGLContext)
   {
      // Tear down context
      if ([EAGLContext currentContext] == mOGLContext)
         [EAGLContext setCurrentContext:nil];

      [mOGLContext release];
      mOGLContext = nil;
   }

   [self removeFromSuperview];
}


- (void) flip
{
   if (multisampling && multisamplingEnabled)
   {
      // [ddc] code taken from
      // http://www.gandogames.com/2010/07/tutorial-using-anti-aliasing-msaa-in-the-iphone/
      // http://is.gd/oHLipb
      // https://devforums.apple.com/thread/45850
      //GLenum attachments[] = {GL_DEPTH_ATTACHMENT_OES};
      //glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);
      
      if (sgAllowShaders)
      {
         const GLenum discards[] = {GL_DEPTH_ATTACHMENT,GL_COLOR_ATTACHMENT0};
         glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 2, discards);
      }
      else
      {
         const GLenum discards[] = {GL_DEPTH_ATTACHMENT_OES,GL_COLOR_ATTACHMENT0_OES};
         glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 2, discards);
      }
      
      //Bind both MSAA and View FrameBuffers.
      if (sgAllowShaders)
      {
         glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
         glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, defaultFramebuffer);
      }
      else
      {
         glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
         glBindFramebufferOES(GL_DRAW_FRAMEBUFFER_APPLE, defaultFramebuffer);
      }
      
      // Call a resolve to combine both buffers
      glResolveMultisampleFramebufferAPPLE();
      // Present final image to screen
   }
   
   if (sgAllowShaders)
   {
      glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
      [mOGLContext presentRenderbuffer:GL_RENDERBUFFER];
   }
   else
   {
      glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
      [mOGLContext presentRenderbuffer:GL_RENDERBUFFER_OES];
   }
}

- (void) recreateOGLFramebuffer
{
   [EAGLContext setCurrentContext:mOGLContext];
   [self destroyOGLFramebuffer];
   [self createOGLFramebuffer];
   //printf("Resize, set ogl %p : %dx%d\n", mOGLContext, backingWidth, backingHeight);

   mHardwareRenderer->SetWindowSize(backingWidth,backingHeight);

   mStage->OnOGLResize(backingWidth,backingHeight);

   mStage->needRecreateOGLFramebuffer = false;
}

- (void) layoutSubviews
{
   mStage->needRecreateOGLFramebuffer = true; 
}

#ifndef OBJC_ARC
- (void) dealloc
{
  
    [super dealloc];
}
#endif

@end // End NMEView


class IOSVideo;
@interface PlayerHandler : NSObject
{
   class IOSVideo *video;
   MPMoviePlayerController *player;
}
- (id) initWithVideo:(IOSVideo *)inVideo player:(MPMoviePlayerController*) inPlayer;

-(void)moviePlayBackDidFinish:(NSNotification*)notification;
-(void)loadStateDidChange:(NSNotification *)notification;
-(void)moviePlayBackStateDidChange:(NSNotification*)notification;
-(void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification;
-(void)movieDurationAvailable:(NSNotification*)notification;
-(void)installMovieNotificationObservers;
-(void)removeMovieNotificationHandlers;

@end


class IOSVideo : public StageVideo
{
   NMEStage                *stage;
   MPMoviePlayerController *player; 
   std::string             lastUrl;
   bool                    vpIsSet;
   CGRect                  viewport;
   double                  pointScale;
   PlayerHandler           *handler;
   double                  duration;
   int                     videoWidth;
   int                     videoHeight;

   bool                    active;
   bool                    playing;
   bool                    stopped;
   bool                    seenPrepared;
   bool                    sentMeta;

   double                  seekPending;
   double                  timeAtLastSeek;

   bool                    pendingStateDelayed;
   int                     pendingState;

public:
   IOSVideo(NMEStage *inStage,double inPointScale)
   {
      IncRef();
      pointScale = inPointScale;
      stage = inStage;
      player = 0;
      vpIsSet = false;
      handler = 0;
      videoWidth = 0;
      videoHeight = 0;
      sentMeta = false;
      duration = 0;
      active = true;
      playing = false;
      stopped = true;
      seekPending = -999;
      timeAtLastSeek = 0;
      seenPrepared = false;
      pendingStateDelayed = false;
      pendingState = 0;
      //printf("New video\n");
   }

   UIView *getPlayerView()
   {
      if (!player)
        return 0;
      return [player view];
   }

   void play(const char *inUrl, double inStart, double inLength)
   {
      printf("VIDEO: play %s %f %f\n", inUrl, inStart, inLength);

      if (inUrl==lastUrl)
      {
         //printf("Replay\n");
         return;
      }

      //printf("VIDEO: load %s\n", inUrl);
 
      /*
      Create a MPMoviePlayerController movie object for the specified URL and add movie notification
      observers. Configure the movie object for the source type, scaling mode, control style, background
      color, background image, repeat mode and AirPlay mode. Add the view containing the movie content and 
      controls to the existing view hierarchy.
      */
  
      if (!stopped && player)
      {
         //printf("VIDEO: Stop player before play\n");
         [player stop];
         stopped = true;
      }

      lastUrl = inUrl;
      bool isLocal = true;
      std::string local = gAssetBase + lastUrl;
   
      NSString *str = [[NSString alloc] initWithUTF8String:local.c_str()];

      // Try asset first ...
      NSURL *localUrl = [[NSBundle mainBundle] URLForResource:str withExtension:nil];

      // Treat as absolute url...
      if (localUrl==nil)
      {
         isLocal = false;
         localUrl = [[NSURL alloc] initWithString:[[NSString alloc] initWithUTF8String:inUrl ] ];
      }

      // TODO - isLocal for loca file, not asset (http?)

      //printf("Loading : %s(%s)\n", [[localUrl absoluteString] UTF8String], isLocal?"local":"streaming");

      if (player==0)
      {
         player = [[MPMoviePlayerController alloc] init];
         player.controlStyle = MPMovieControlStyleNone;
         handler = [[PlayerHandler alloc] initWithVideo:this player:player ];
      }

      player.movieSourceType = isLocal ? MPMovieSourceTypeFile : MPMovieSourceTypeStreaming;
      player.contentURL = localUrl;

      stage->onVideoPlay();

      if (!vpIsSet)
         viewport = stage->getViewBounds();

      //printf("Player viewport %fx%f\n", viewport.size.width, viewport.size.height );

      [[player view] setFrame:viewport];


      stopped = false;
      videoWidth = 0;
      videoHeight = 0;
      sentMeta = false;
      duration = 0;
      seenPrepared = false;
      seekPending = -999;

      if (inLength== PAUSE_LEN)
      {
         //printf("Init paused...");
         [player prepareToPlay];
         playing = false;
      }
      else
      {
         //printf("Init playing\n");
         playing = true;
         setState();
      }
    }

   ~IOSVideo()
   {
      //printf("~IOSVideo\n");
      destroy();
   }
   
   void sendSeekStatus(int inCode, double inRequest)
   {
      int top = 0;
      gc_set_top_of_stack(&top,false);

      int seekFromId =  val_id("seekFrom");
      alloc_field( mOwner.get(), seekFromId, alloc_float(inRequest) );
      int codeId =  val_id("seekCode");
      alloc_field( mOwner.get(), codeId, alloc_int(inCode) );
 
      int f =  val_id("_native_on_seek");
      val_ocall0(mOwner.get(), f);
   }

   void sendMeta()
   {
      sentMeta = true;
      int top = 0;
      gc_set_top_of_stack(&top,false);

      int widthId =  val_id("videoWidth");
      alloc_field( mOwner.get(), widthId, alloc_int(videoWidth) );
      int heightId =  val_id("videoHeight");
      alloc_field( mOwner.get(), heightId, alloc_int(videoHeight) );
      int durationId =  val_id("duration");
      alloc_field( mOwner.get(), durationId, alloc_float(duration) );

      int f =  val_id("_native_meta_data");
      val_ocall0(mOwner.get(), f);
   }

   void sendStateDelayed(int inState)
   {
      pendingState = inState;
      pendingStateDelayed = true;
   }

   void sendState(int inState)
   {
      int top = 0;
      gc_set_top_of_stack(&top,false);

      int f =  val_id("_native_play_status");
      val_ocall1(mOwner.get(), f, alloc_int(inState) );
   }

   void setActive(bool inActive)
   {
      active = inActive;
      //printf("Video set active %d\n", inActive);
      setState();
   }

   void seek(double inTime)
   {
      //printf("VIDEO: seek %f\n", inTime);
      if (seekPending<0)
      {
         timeAtLastSeek = player.currentPlaybackTime;
         seekPending = inTime;
      }
      player.currentPlaybackTime = inTime;
   }

   void setPan(double x, double y)
   {
      //printf("video: setPan %f %f\n",x,y);
   }

   void setZoom(double x, double y)
   {
      //printf("video: setZoom %f %f\n",x,y);
   }

   void setSoundTransform(double inVolume, double inPosition)
   {
      //printf("video: setSoundTransform music %f %f\n", inVolume, inPosition);
      // does this work?
      MPMusicPlayerController* musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
      musicPlayer.volume = inVolume;
   }

   void setViewport(double x, double y, double width, double height)
   {
      //printf("VIDEO: setviewport %f %f %f %f\n",x,y, width,height);
      vpIsSet = true;
      viewport = CGRectMake(x*pointScale,y*pointScale,width*pointScale,height*pointScale);
      if (player)
         [[player view] setFrame:viewport];
   }

   double getTime()
   {
      NSTimeInterval t = player.currentPlaybackTime;
      //printf("video: getTime %f\n", t);
      return t;
   }

   void setState()
   {
      if (!stopped && player!=nil)
      {
         if (playing && active)
         {
            //printf("> PLAY\n");
            [player play];
         }
         else
         {
            //printf("> PAUSE\n");
            [player pause];
         }
      }
   }

   void pause()
   {
      //printf("VIDEO: pause\n");
      playing = false;
      setState();
   }

   void resume()
   {
      //printf("VIDEO: resume\n");
      playing = true;
      setState();
   }

   void togglePause()
   {
      //printf("VIDEO: togglePause\n");
      playing = !playing;
      setState();
   }

   double getBufferedPercent()
   {
      if (!player || duration<=0)
         return 0;
      // Add position?
      return 100.0 * player.playableDuration/player.duration;
   }


   void destroy()
   {
      //printf("video: destroy\n");
      lastUrl = "";
      videoWidth = 0;
      videoHeight = 0;
      duration = 0;
      if (player && !stopped)
      {
         //printf("STOP\n");
         stopped = true;
         [player stop];
      }
      /*
      // TODO - dealloc ?
      player = 0;
      */
   }

   void onPoll()
   {
      if (player && seekPending>=0 && player.currentPlaybackTime != timeAtLastSeek )
      {
         double val = seekPending;
         seekPending = -9999;
         sendSeekStatus(SEEK_FINISHED_OK,val);
      }

      if (pendingStateDelayed)
      {
         pendingStateDelayed = false;
         sendState(pendingState);
      }
   }

   void checkSize(bool inIgnoreDuration=false)
   {
      CGSize size = player.naturalSize;
      int w = (int)size.width;
      int h = (int)size.height;
      if (duration==0 && player)
      {
         duration = player.duration;
      }

      if (w!=videoWidth || h!=videoHeight || (!sentMeta && w && h))
      {
         videoWidth = w;
         videoHeight = h;
         if (duration>0 || inIgnoreDuration)
            sendMeta();
      }
   }

   void onBufferingStateChange()
   { 
      checkSize();
      //printf("onBufferingStateChange %d\n", player.loadState);
      switch(player.loadState)
      {
         case MPMovieLoadStateUnknown: break;
         case MPMovieLoadStatePlayable: break;
         case MPMovieLoadStatePlaythroughOK: break;
         case MPMovieLoadStateStalled: break;
      }
   }
    
   void onPlaybackStateChange()
   { 
      checkSize();
      //printf("State changed %d\n", player.playbackState);
      switch(player.playbackState)
      {
         case MPMoviePlaybackStateStopped:
            //printf("MPMoviePlaybackStateStopped\n");
            sendStateDelayed( PLAY_STATUS_STOPPED );
            break;
         case MPMoviePlaybackStatePlaying:

            //printf("MPMoviePlaybackStatePlaying\n");
            checkSize(true);
            sendStateDelayed( PLAY_STATUS_STARTED );
            break;
         case MPMoviePlaybackStatePaused: break;
         case MPMoviePlaybackStateInterrupted:
            //printf("Interrupted");
            break;
         case MPMoviePlaybackStateSeekingForward: break;
         case MPMoviePlaybackStateSeekingBackward:break;
      }
   }
 
   void onSizeAvailable()
   { 
      CGSize size = player.naturalSize;
      videoWidth = size.width;
      videoHeight = size.height;
      if (duration==0 && player)
      {
         duration = player.duration;
      }
      if (duration>0)
        sendMeta();
   }
 

   void onMovieDurationAvailable()
   {
      duration = player.duration;
      printf("onMovieDurationAvailable %f (%dx%d)\n", duration, videoWidth, videoHeight);
 
      if (videoWidth>0)
         sendMeta();
      else
         checkSize();
   }

   
   void onPreparedStateChanged()
   { 
      checkSize();
      if (player.isPreparedToPlay)
        seenPrepared = true;
   }
    
   void onFinished(int reason)
   { 
      printf("on Finished %d\n",reason);
      // force stop to avoid loop
      if(!stopped)
      {
         printf("force stop\n");
         [player stop];
         stopped = true;
         lastUrl = "";
         videoWidth = 0;
         videoHeight = 0;
         duration = 0;
      }

      if (reason == MPMovieFinishReasonPlaybackEnded)
      {
         printf("playback ended\n");
         // movie finished playin
         if (seekPending>=0)
         {
            seekPending = -999;
            sendSeekStatus(SEEK_FINISHED_EARLY,duration);
         }
         sendStateDelayed( PLAY_STATUS_COMPLETE );
      }
      else if (reason == MPMovieFinishReasonUserExited)
      {
         printf("playback cancelled\n");
         //user hit the done button - is this complete?
         sendStateDelayed( PLAY_STATUS_COMPLETE );
      }
      else if (reason == MPMovieFinishReasonPlaybackError)
      {
         printf("playback error\n");

         //error
         if (seekPending>=0)
         {
            double val = seekPending;
            seekPending = -999;
            sendSeekStatus(SEEK_FINISHED_ERROR,val);
         }
         if (seenPrepared)
         {
            sendStateDelayed( PLAY_STATUS_NOT_STARTED );
         }
         else
          {
            sendStateDelayed( PLAY_STATUS_ERROR );
          }
      }
   }

};


@implementation PlayerHandler

- (id) initWithVideo:(IOSVideo *)inVideo player:(MPMoviePlayerController*) inPlayer
{
   video = inVideo;
   player = inPlayer;
   [self installMovieNotificationObservers];
   return self;
}

-(void)moviePlayBackDidFinish:(NSNotification*)notification
{
   //printf("moviePlayBackDidFinish\n");
   int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
   video->onFinished(reason);
}

-(void)loadStateDidChange:(NSNotification *)notification
{
   //printf("loadStateDidChange\n");
   video->onBufferingStateChange();
}

-(void)moviePlayBackStateDidChange:(NSNotification*)notification
{
   //printf("moviePlayBackStateDidChange\n");
   video->onPlaybackStateChange();
}

-(void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
   //printf("mediaIsPreparedToPlayDidChange\n");
   video->onPreparedStateChanged();
}


-(void)movieDurationAvailable:(NSNotification*)notification
{
   //printf("movieDurationAvailable\n");
   video->onMovieDurationAvailable();
}


-(void)sizeAvailable:(NSNotification*)notification
{
   //printf("sizeAvailable\n");
   video->onSizeAvailable();
}



-(void)installMovieNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(loadStateDidChange:) 
                                                 name:MPMoviePlayerLoadStateDidChangeNotification 
                                               object:player];
 
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(moviePlayBackDidFinish:) 
                                                 name:MPMoviePlayerPlaybackDidFinishNotification 
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(mediaIsPreparedToPlayDidChange:) 
                                                 name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification 
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(moviePlayBackStateDidChange:) 
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification 
                                               object:player];        
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(movieDurationAvailable:) 
                                                 name:MPMovieDurationAvailableNotification 
                                               object:player];        
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(sizeAvailable:) 
                                                 name:MPMovieNaturalSizeAvailableNotification 
                                               object:player];        
}

-(void)removeMovieNotificationHandlers
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMovieDurationAvailableNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMovieNaturalSizeAvailableNotification object:player];
}

@end


double sgWakeUp = 0.0;






// --- Stage Implementaton ------------------------------------------------------
//
// The stage acts as the controller between the NME view and the NME application.
//  It passes events as sets properties as required


NMEStage::NMEStage(CGRect inRect) : nme::Stage(true)
{
   APP_LOG(@"new NMEStage");
   video = 0;
   //printf("New NMEStage\n");

   sgNmeStage = this;

   haveOpaqueBg = true;
   wantOpaqueBg = true;
   needRecreateOGLFramebuffer = false;

   NSString* platform = [UIDeviceHardware platformString];
   //printf("Detected hardware: %s\n", [platform UTF8String]);
   
  
   playerView = 0;
   popupEnabled = false;
   multiTouchEnabled = false;
   container = [[UIView alloc] initWithFrame:inRect];
   container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
   container.opaque = TRUE;

   CGRect childRect = CGRectMake(0,0, inRect.size.width, inRect.size.height);

   nmeView = [[NMEView alloc] initWithFrame:childRect ];

   [nmeView setupStageLayer:this];

   [container addSubview:nmeView];

   sgAnimationController = [[NMEAnimationController alloc] initWithStage:this ];

   [sgAnimationController startAnimation];


   #ifndef IPHONESIM
   if (!sgCmManager)
   {
      sgCmManager = [[CMMotionManager alloc]init];
      if ([sgCmManager isAccelerometerAvailable])
      {
        sgCmManager.accelerometerUpdateInterval = 0.033;
        [sgCmManager startAccelerometerUpdates];
        sgHasAccelerometer = true;
      }
   }
   #endif
}

void NMEStage::setOpaqueBackground(uint32 inBG)
{
   Stage::setOpaqueBackground(inBG);
   #ifdef HX_LIME
   wantOpaqueBg = true;
   #else
   wantOpaqueBg = (inBG & 0xff000000) != 0;
   #endif

   if (wantOpaqueBg!=haveOpaqueBg)
      recreateNmeView();
   else if (playerView)
   {
      double r = ((opaqueBackground>>16) & 0xff) / 255.0;
      double g = ((opaqueBackground>>8 ) & 0xff) / 255.0;
      double b = ((opaqueBackground    ) & 0xff) / 255.0;
      container.backgroundColor = [[UIColor alloc] initWithRed:r green:g blue:b alpha:1.0];
   }
}

void NMEStage::recreateNmeView()
{
   printf("===== recreateNmeView ===== %d\n",wantOpaqueBg);
   [nmeView tearDown];
   #ifndef OBJC_ARC
   // Should do it here
   [nmeView release];
   #endif
   nmeView = 0;


   CGRect rect = [container bounds];

   nmeView = [[NMEView alloc] initWithFrame:rect ];

   [nmeView setupStageLayer:this];

   [container addSubview:nmeView];

   haveOpaqueBg = wantOpaqueBg;

   if (!playerView)
   {
      // No underlay required...
      container.backgroundColor = nil;
   }
   else
   {
      // add underlay to go under video
      double r = ((opaqueBackground>>16) & 0xff) / 255.0;
      double g = ((opaqueBackground>>8 ) & 0xff) / 255.0;
      double b = ((opaqueBackground    ) & 0xff) / 255.0;
      container.backgroundColor = [[UIColor alloc] initWithRed:r green:g blue:b alpha:1.0];
   }
   ResetHardwareContext();
   Event evt(etRenderContextLost);
   OnEvent(evt);
}

void NMEStage::updateSize(int inWidth, int inHeight)
{
/*
   if (backingWidth!=inWidth || backingHeight!=inHeight)
   {
      recreateNmeView();
   }
*/
}

 
uint32 NMEStage::getBackgroundMask()
{
   return wantOpaqueBg ? 0xffffffff : 0x00ffffff;
}

CGRect NMEStage::getViewBounds()
{
   return nmeView.bounds;
}

void NMEStage::onVideoPlay()
{
   if (!playerView)
   {
      playerView = video->getPlayerView();
      [container insertSubview:playerView belowSubview:nmeView];
      //[container addSubview:playerView];

      wantOpaqueBg = false;
      if (wantOpaqueBg!=haveOpaqueBg)
         recreateNmeView();
   }
}

StageVideo *NMEStage::createStageVideo(void *inOwner)
{
   if (!video)
   {
      video = new IOSVideo(this,1.0/getDPIScale());
      video->setOwner( (value) inOwner );
   }

   return video;
}


NMEStage::~NMEStage()
{
  [nmeView tearDown];
}

void NMEStage::PopupKeyboard(PopupKeyboardMode inMode, WString *)
{
  popupEnabled = inMode!=pkmOff;
  if(popupEnabled){
      DisplayObject *fobj = GetFocusObject();
      int softKeyboard = 0;
      if(fobj)
          softKeyboard = fobj->getSoftKeyboard();
      else
          softKeyboard = getSoftKeyboard();

      if(softKeyboard == 1)
          nmeView->mTextField.keyboardType = UIKeyboardTypeNamePhonePad;
      else if(softKeyboard == 4)
          nmeView->mTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
      else if(softKeyboard == 5)
          nmeView->mTextField.keyboardType = UIKeyboardTypeURL;
      else if(softKeyboard == 3)
          nmeView->mTextField.keyboardType = UIKeyboardTypeNumberPad;
      else if(softKeyboard == 2)
          nmeView->mTextField.keyboardType = UIKeyboardTypeEmailAddress;
      else if(softKeyboard == 102)
          nmeView->mTextField.keyboardType = UIKeyboardTypeASCIICapable;
      else //default
          nmeView->mTextField.keyboardType = UIKeyboardTypeDefault;
  }
  [ nmeView enableKeyboard:popupEnabled];
}
 

void NMEStage::setMultitouchActive(bool inActive)
{
   multiTouchEnabled = inActive;
   [ nmeView enableMultitouch:inActive ];
}

bool NMEStage::getMultitouchActive()
{
   return multiTouchEnabled;
}

void NMEStage::OnOGLResize(int width, int height)
{   
   //printf("OnOGLResize %dx%d\n", width, height);
   Event evt(etResize);
   evt.x = width;
   evt.y = height;
   OnEvent(evt);

}

void NMEStage::OnRedraw()
{
   //[nmeView makeCurrent: GetAA()>1 ];
   Event evt(etRedraw);
   OnEvent(evt);
}


void NMEStage::OnEvent(Event &inEvt)
{
   int top = 0;
   gc_set_top_of_stack(&top,false);

   if (inEvt.type==etPoll && video)
      video->onPoll();

   if ((inEvt.type==etActivate || inEvt.type==etDeactivate) && video)
      video->setActive(inEvt.type==etActivate);
   HandleEvent(inEvt);
}

void NMEStage::Flip()
{
   [nmeView flip];
}



// --- UIStageViewController ----------------------------------------------------------

bool nmeIsMain = true;


@interface NMEStageViewController : UIViewController
@end

@implementation NMEStageViewController
{
  @public
  NMEStage *nmeStage;
  bool     isFirstAppearance;
}

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
   {
      enum {
         OrientationPortrait = 1,
         OrientationPortraitUpsideDown = 2,
         OrientationLandscapeRight = 3,
         OrientationLandscapeLeft = 4,
         OrientationFaceUp = 5,
         OrientationFaceDown = 6,
         OrientationPortraitAny = 7,
         OrientationLandscapeAny = 8,
         OrientationAny = 9,
      };

      if (interfaceOrientation == gFixedOrientation)
         return true;
      if (gFixedOrientation==OrientationAny)
         return true;
      if (gFixedOrientation==OrientationPortraitAny)
         return interfaceOrientation==OrientationPortrait || interfaceOrientation==OrientationPortraitUpsideDown;
      if (gFixedOrientation==OrientationLandscapeAny)
         return interfaceOrientation==OrientationLandscapeLeft || interfaceOrientation==OrientationLandscapeRight;
      return false;
   }
   Event evt(etShouldRotate);
   evt.value = interfaceOrientation;
   nmeStage->OnEvent(evt);
   return evt.result == 2;
}

- (void) setNMEMain:(bool)isMain
{
   nmeIsMain = isMain;
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

- (void) setInstance
{
   // May be overriden
}

- (void)loadView
{
   APP_LOG(@"loadView");
   [self setInstance];
   //printf("loadView...\n");
   nmeStage = new NMEStage([[UIScreen mainScreen] bounds]);
   self.view = nmeStage->getRootView();
   //printf("loadView done\n");
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
   //printf("didMoveToParentViewController!\n");
   [super didMoveToParentViewController:parent];
}



- (void)viewDidAppear:(BOOL)animated
{
   APP_LOG(@"viewDidAppear");
   CGRect bounds = self.view.bounds;
 

   if (!isFirstAppearance)
   {
      isFirstAppearance = true;
      if (!nmeIsMain)
      {
         int top = 0;
         gc_set_top_of_stack(&top,false);
         sOnFrame( new IOSViewFrame(nmeStage) );
      }
   }
}


- (void)didReceiveMemoryWarning
{
   APP_LOG(@"didReceiveMemoryWarning");
}


@end




// --- NMEAppDelegate ----------------------------------------------------------


@interface NMEAppDelegate : NSObject <UIApplicationDelegate>
{
   UIWindow *window;
   UIViewController *controller;
}
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *controller;

@end


@implementation NMEAppDelegate

@synthesize window;
@synthesize controller;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   APP_LOG(@"application start");
   UIWindow *win = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
   window = win;
   [window makeKeyAndVisible];
   NMEStageViewController  *c = [[NMEStageViewController alloc] init];
   controller = c;
   nme_app_set_active(true);
   application.idleTimerDisabled = YES;
   // Accessing the .view property causes the 'loadView' callback
   [win addSubview:c.view];
   self.window.rootViewController = c;
   sOnFrame( new IOSViewFrame(c->nmeStage) );
   return YES;
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   APP_LOG(@"willFinishLaunchingWithOptions");
   return YES;
}

- (void) applicationWillResignActive:(UIApplication *)application
{
   nme_app_set_active(false);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
   nme_app_set_active(false);
   APP_LOG(@"applicationDidEnterBackground");
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
   APP_LOG(@"applicationDidBecomeActive");
   nme_app_set_active(true);
}

- (void) applicationWillTerminate:(UIApplication *)application
{
   APP_LOG(@"applicationWillTerminate");
   nme_app_set_active(false);
}

#ifndef OBJC_ARC
- (void) dealloc
{
   APP_LOG(@"NMEAppDelegate dealloc");
   nme_app_set_active(false);
   [window release];
   [controller release];
   [super dealloc];
}
#endif

@end








// --- Extenal Interface -------------------------------------------------------

void EnableKeyboard(bool inEnable)
{
   sgNmeStage->PopupKeyboard(inEnable ? pkmDumb : pkmOff,0);
}


namespace nme
{

Stage *IPhoneGetStage()
{
   return sgNmeStage;
}

void StartAnimation()
{
   if (sgAnimationController)
   {
      [sgAnimationController startAnimation];
   }
}
void PauseAnimation()
{
   if (sgAnimationController)
   {
      [sgAnimationController stopAnimation];
   }
}
void ResumeAnimation()
{
   if (sgAnimationController)
   {
      [sgAnimationController startAnimation];
   }
}
void StopAnimation()
{
   if (sgAnimationController)
   {
      [sgAnimationController stopAnimation];
   }
}

void SetNextWakeUp(double inWakeUp)
{
   sgWakeUp = inWakeUp;
}
   
   
void CreateMainFrame(FrameCreationCallback inCallback,
   int inWidth,int inHeight,unsigned int inFlags, const char *inTitle, Surface *inIcon )
{
   APP_LOG(@"CreateMainFrame");
   nmeTitle= inTitle;
   sOnFrame = inCallback;
   int argc = 0;// *_NSGetArgc();
   char **argv = 0;// *_NSGetArgv();

   //sgAllowShaders = ( inFlags & wfAllowShaders );
   sgAllowShaders = true;
   sgHasDepthBuffer = ( inFlags & wfDepthBuffer );
   sgHasStencilBuffer = ( inFlags & wfStencilBuffer );
   sgEnableMSAA2 = ( inFlags & wfHW_AA );
   sgEnableMSAA4 = ( inFlags & wfHW_AA_HIRES );

   //can't have a stencil buffer on it's own, 
   if(sgHasStencilBuffer && !sgHasDepthBuffer)
      sgHasDepthBuffer = true;

   if (nmeIsMain)
   {
      // The NMEAppDelegate will create a NMEStageViewController

      #ifndef OBJC_ARC
      NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
      #endif
      UIApplicationMain(argc, argv, nil, @"NMEAppDelegate");
      #ifndef OBJC_ARC
      [pool release];
      #endif
   }
}

bool GetAcceleration(double &outX, double &outY, double &outZ)
{
#ifdef IPHONESIM
   return false;
#else
   if (!sgCmManager || !sgHasAccelerometer)
      return false;

   CMAcceleration a = sgCmManager.accelerometerData.acceleration;

   outX = a.x;
   outY = a.y;
   outZ = a.z;
   return true;
#endif
}


/*
void nmeReparentNMEView(void *inParent)
{
   UIView *parent = (UIView *)inParent;

   if (sgNmeStage!=nil)
   {
      UIView *view = sgNmeStage->getRootView();

      [parent  addSubview:view];

      nme::StartAnimation();
   }
}
*/

} // namespace nme



extern "C"
{

void nme_app_set_active(bool inActive)
{
   if (sgNmeStage)
   {
      Event evt(inActive ? etActivate : etDeactivate);
      sgNmeStage->OnEvent(evt);
   }

   if (inActive)
      nme::StartAnimation();
   else
      nme::StopAnimation();
}


}


