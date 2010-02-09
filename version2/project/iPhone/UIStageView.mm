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

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


using namespace nme;

class EAGLStage : public nme::Stage
{
public:
   EAGLStage(CAEAGLLayer *inLayer,bool inInitRef) : nme::Stage(inInitRef)
   {

      defaultFramebuffer = 0;
      colorRenderbuffer = 0;
      mHardwareContext = 0;
      mHardwareSurface = 0;
      mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
      if (!mContext || ![EAGLContext setCurrentContext:mContext])
      {
         throw "Could not initilize OpenL";
      }
      
      // Create default framebuffer object.
      // The backing will be allocated for the current layer in -resizeFromLayer
      glGenFramebuffersOES(1, &defaultFramebuffer);
      glGenRenderbuffersOES(1, &colorRenderbuffer);
      glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
      glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
      glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES,
                                     GL_RENDERBUFFER_OES, colorRenderbuffer);

      mHardwareContext = HardwareContext::CreateOpenGL(inLayer,mContext);
      mHardwareContext->IncRef();
      mHardwareSurface = new HardwareSurface(mHardwareContext);
      mHardwareSurface->IncRef();
   }

   ~EAGLStage()
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
      if ([EAGLContext currentContext] == mContext)
         [EAGLContext setCurrentContext:nil];
   
      [mContext release];
   }

   void OnResizeLayer(CAEAGLLayer *inLayer)
   {   
      // Allocate color buffer backing based on the current layer size
      glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
      [mContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:inLayer];
      glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
      glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
   
      if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
      {
          NSLog(@"Failed to make complete framebuffer object %x",
            glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
          throw "OpenGL resize failed";
      }
      mHardwareContext->SetWindowSize(backingWidth,backingHeight);

      Event evt(etResize);
      HandleEvent(evt);

   }

    void SetPollMethod(PollMethod inMethod)
    {
       // Do nothing for now - use the 60Hz timer....
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



   void Flip()
   {
       glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
       [mContext presentRenderbuffer:GL_RENDERBUFFER_OES];
   }
   void GetMouse()
   {
      // TODO
   }

   
   Surface *GetPrimarySurface()
   {
      return mHardwareSurface;
   }

  // --- IRenderTarget Interface ------------------------------------------
   int Width() { return backingWidth; }
   int Height() { return backingHeight; }


   EventHandler mHandler;
   void *mHandlerData;


   EAGLContext *mContext;
   HardwareSurface *mHardwareSurface;
   HardwareContext *mHardwareContext;


   // The pixel dimensions of the CAEAGLLayer
   GLint backingWidth;
   GLint backingHeight;
   
   // The OpenGL names for the framebuffer and renderbuffer used to render to this view
   GLuint defaultFramebuffer, colorRenderbuffer;

};


// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface UIStageView : UIView
{    
@private
   BOOL animating;
   BOOL displayLinkSupported;
   NSInteger animationFrameInterval;
   // Use of the CADisplayLink class is the preferred method for controlling your animation timing.
   // CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
   // The NSTimer class is used only as fallback when running on a pre 3.1 device where CADisplayLink
   // isn't available.
   id displayLink;
    NSTimer *animationTimer;
@public
   EAGLStage *mStage;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (void) startAnimation;
- (void) stopAnimation;
- (void) drawView:(id)sender;
- (void) onPoll:(id)sender;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

@end


UIStageView *sgMainView = nil;


@implementation UIStageView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id) initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder]))
   {
      sgMainView = self;
      // Get the layer
      CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

      eaglLayer.opaque = TRUE;
      eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                      kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                      nil];

      mStage = new EAGLStage(eaglLayer,true);
        
      animating = FALSE;
      displayLinkSupported = FALSE;
      animationFrameInterval = 1;
      displayLink = nil;
      animationTimer = nil;
      
      // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
      // class is used as fallback when it isn't available.
      /*
      NSString *reqSysVer = @"3.1";
      NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
      if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
         displayLinkSupported = TRUE;
      */

      displayLinkSupported = FALSE;
    }
   
    return self;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
   CGPoint thumbPoint;
   UITouch *thumb = [[event allTouches] anyObject];
   thumbPoint = [thumb locationInView:thumb.view];

   if(thumb.tapCount==0)
   {
      Event mouse(etMouseDown, thumbPoint.x, thumbPoint.y);
      mStage->OnEvent(mouse);
   }
   else if(thumb.tapCount==1)
   {
      Event mouse(etMouseClick, thumbPoint.x, thumbPoint.y);
      mStage->OnEvent(mouse);
   }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
   if([touches count] == 1)
   {
      CGPoint thumbPoint;
      UITouch *thumb = [[event allTouches] anyObject];
      thumbPoint = [thumb locationInView:thumb.view];

      Event mouse(etMouseMove, thumbPoint.x, thumbPoint.y);
      mStage->OnEvent(mouse);
   }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
   if([touches count] == [[event touchesForView:self] count])
   {
      CGPoint thumbPoint;
      UITouch *thumb = [[event allTouches] anyObject];
      thumbPoint = [thumb locationInView:thumb.view];

      Event mouse(etMouseUp, thumbPoint.x, thumbPoint.y);
      mStage->OnEvent(mouse);
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
   mStage->OnResizeLayer((CAEAGLLayer*)self.layer);
}

- (NSInteger) animationFrameInterval
{
   return animationFrameInterval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
   // Frame interval defines how many display frames must pass between each time the
   // display link fires. The display link will only fire 30 times a second when the
   // frame internal is two on a display that refreshes 60 times a second. The default
   // frame interval setting of one will fire 60 times a second when the display refreshes
   // at 60 times a second. A frame interval setting of less than one results in undefined
   // behavior.
   if (frameInterval >= 1)
   {
      animationFrameInterval = frameInterval;
      
      if (animating)
      {
         [self stopAnimation];
         [self startAnimation];
      }
   }
}

- (void) startAnimation
{
   if (!animating)
   {
      /*
      if (displayLinkSupported)
      {
         // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
         // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
         // not be called in system versions earlier than 3.1.

         displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
         [displayLink setFrameInterval:animationFrameInterval];
         [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
      }
      else
      */

         animationTimer = [NSTimer
             //scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval)
             scheduledTimerWithTimeInterval:(NSTimeInterval)(0.0001)
             target:self selector:@selector(onPoll:)
             userInfo:nil
             repeats:TRUE];
      
      animating = TRUE;
   }
}

- (void)stopAnimation
{
   if (animating)
   {
      if (displayLinkSupported)
      {
         [displayLink invalidate];
         displayLink = nil;
      }
      else
      {
         [animationTimer invalidate];
         animationTimer = nil;
      }
      
      animating = FALSE;
   }
}

- (void) dealloc
{
    if (mStage) mStage->DecRef();
   
    [super dealloc];
}

@end


class UIViewFrame : public nme::Frame
{
public:
   virtual void SetTitle()  { }
   virtual void SetIcon() { }
   virtual Stage *GetStage()  { return sgMainView->mStage; }

};

namespace nme
{
Stage *IPhoneGetStage() { return sgMainView->mStage; }
void MainLoop() { }
void TerminateMainLoop() { }

Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, const char *inTitle, const char *inIcon )
{
    return new UIViewFrame();
}




}

extern "C"
{

void nme_app_set_active(bool inActive)
{
   printf("nme_app_set_active %d\n",inActive);
   if (inActive)
      [ sgMainView startAnimation ];
   else
      [ sgMainView stopAnimation ];
}


}
