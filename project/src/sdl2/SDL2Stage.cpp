#include <Display.h>
#include <Utils.h>
#include <SDL.h>
#include <Surface.h>
#include <nme/NmeCffi.h>
#include <KeyCodes.h>
#include <map>

#include <Sound.h>


#ifdef NME_MIXER
#include <SDL_mixer.h>
#endif

#ifdef HX_WINDOWS
#include <SDL_syswm.h>
#include <Windows.h>
#include <Utils.h>
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX) 
#include "GameControllerDB.h"
#endif

#if defined(HX_WINDOWS) && !defined(HX_WINRT)
#define NME_WINDOWS_SINGLE_INSTANCE
#endif

namespace nme
{
static int sgDesktopWidth = 0;
static int sgDesktopHeight = 0;
static Rect sgWindowRect = Rect(0, 0, 0, 0);
static bool sgInitCalled = false;
//static bool sgJoystickEnabled = false;
static bool sgGameControllerEnabled = false;
static bool sgIsOGL2 = false;
const int sgJoystickDeadZone = 1000;
#ifdef NME_WINDOWS_SINGLE_INSTANCE 
static HANDLE sgMutexRunning = NULL;
#endif

enum { NO_TOUCH = -1 };


int InitSDL()
{   
   if (sgInitCalled)
      return 0;
      
   sgInitCalled = true;
   
   #ifdef NME_MIXER
   int audioFlag = SDL_INIT_AUDIO;
   #else
   int audioFlag = 0;
   #endif
   int err = SDL_Init(SDL_INIT_VIDEO | audioFlag | SDL_INIT_TIMER);
   
   if (err == 0 && SDL_InitSubSystem (SDL_INIT_GAMECONTROLLER) == 0)
   {
      sgGameControllerEnabled = true;
      #if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX) 
      SDL_GameControllerAddMappingsFromRW (SDL_RWFromConstMem (g_gameControllerDB, sizeof (g_gameControllerDB)), 0);
      #endif
   }
   
   return err;
}

static void openAudio()
{
   #ifdef NME_MIXER
   gSDLAudioState = sdaOpen;

   #ifdef HX_WINDOWS
   int chunksize = 2048;
  #else
   int chunksize = 4096;
   #endif
   
   int frequency = 44100;
   //int frequency = MIX_DEFAULT_FREQUENCY //22050
   //The default frequency would have less latency, but is incompatible with the average MP3 file
   
   if (Mix_OpenAudio(frequency, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, chunksize) != 0)
   {
      fprintf(stderr,"Could not open sound: %s\n", Mix_GetError());
      gSDLAudioState = sdaError;
   }
   #endif
}

void InitSDLAudio()
{
   SDL_Init(SDL_INIT_AUDIO);
   openAudio();
}



class SDLSurf : public Surface
{
public:
   SDLSurf(SDL_Surface *inSurf,bool inDelete) : mSurf(inSurf)
   {
      mDelete = inDelete;
      mLockedForHitTest = false;
   }
   ~SDLSurf()
   {
      if (mDelete)
         SDL_FreeSurface(mSurf);
   }
   
   int Width() const { return mSurf->w; }
   int Height() const { return mSurf->h; }
   PixelFormat Format() const
   {
      return pfBGRA;
   }
   const uint8 *GetBase() const { return (const uint8 *)mSurf->pixels; }
   int GetStride() const { return mSurf->pitch; }

   void Clear(uint32 inColour,const Rect *inRect)
   {
      SDL_Rect r;
      SDL_Rect *rect_ptr = 0;
      if (inRect)
      {
         rect_ptr = &r;
         r.x = inRect->x;
         r.y = inRect->y;
         r.w = inRect->w;
         r.h = inRect->h;
      }
      
      SDL_FillRect(mSurf,rect_ptr,SDL_MapRGBA(mSurf->format,
            inColour>>16, inColour>>8, inColour, inColour>>24 )  );
   }

   uint8 *Edit(const Rect *inRect)
   {
      if (SDL_MUSTLOCK(mSurf))
         SDL_LockSurface(mSurf);

      return (uint8 *)mSurf->pixels;
   }
   void Commit()
   {
      if (SDL_MUSTLOCK(mSurf))
         SDL_UnlockSurface(mSurf);
   }

   RenderTarget BeginRender(const Rect &inRect,bool inForHitTest)
   {
      mLockedForHitTest = inForHitTest;
      if (SDL_MUSTLOCK(mSurf) && !mLockedForHitTest)
         SDL_LockSurface(mSurf);
      return RenderTarget(Rect(Width(),Height()), Format(),
         (uint8 *)mSurf->pixels, mSurf->pitch);
   }
   void EndRender()
   {
      if (SDL_MUSTLOCK(mSurf) && !mLockedForHitTest)
         SDL_UnlockSurface(mSurf);
   }

   void BlitTo(const RenderTarget &outTarget,
               const Rect &inSrcRect,int inPosX, int inPosY,
               BlendMode inBlend, const BitmapCache *inMask,
               uint32 inTint=0xffffff ) const
   {
   }
   void BlitChannel(const RenderTarget &outTarget, const Rect &inSrcRect,
                            int inPosX, int inPosY,
                            int inSrcChannel, int inDestChannel ) const
   {
   }

   void StretchTo(const RenderTarget &outTarget,
          const Rect &inSrcRect, const DRect &inDestRect,unsigned int) const
   {
   }

   SDL_Surface *mSurf;
   bool  mDelete;
   bool  mLockedForHitTest;
};


/*
SDL_Surface *SurfaceToSDL(Surface *inSurface)
{
   int swap =  (gC0IsRed!=(bool)(inSurface->Format()&pfSwapRB)) ? 0xff00ff : 0;
   return SDL_CreateRGBSurfaceFrom((void *)inSurface->Row(0),
             inSurface->Width(), inSurface->Height(),
             32, inSurface->Width()*4,
             0x00ff0000^swap, 0x0000ff00,
             0x000000ff^swap, 0xff000000 );
}
*/

SDL_Cursor *CreateCursor(const char *image[],int inHotX,int inHotY)
{
   int i, row, col;
   Uint8 data[4*32];
   Uint8 mask[4*32];

   i = -1;
   for ( row=0; row<32; ++row ) {
      for ( col=0; col<32; ++col ) {
         if ( col % 8 ) {
            data[i] <<= 1;
            mask[i] <<= 1;
         } else {
            ++i;
            data[i] = mask[i] = 0;
         }
         switch (image[row][col]) {
            case 'X':
               data[i] |= 0x01;
               mask[i] |= 0x01;
               break;
            case '.':
               mask[i] |= 0x01;
               break;
            case ' ':
               break;
         }
      }
   }
   return SDL_CreateCursor(data, mask, 32, 32, inHotX, inHotY);
}

SDL_Cursor *sDefaultCursor = 0;
SDL_Cursor *sTextCursor = 0;
SDL_Cursor *sHandCursor = 0;

unsigned int FullscreenMode = SDL_WINDOW_FULLSCREEN_DESKTOP;
//unsigned int FullscreenMode = SDL_WINDOW_FULLSCREEN;

class SDLStage : public Stage
{
public:
   SDLStage(SDL_Window *inWindow, SDL_Renderer *inRenderer, uint32 inWindowFlags, bool inIsOpenGL, int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      
      mIsOpenGL = inIsOpenGL;
      mSDLWindow = inWindow;
      mSDLRenderer = inRenderer;
      mWindowFlags = inWindowFlags;
      
      mShowCursor = true;
      mCurrentCursor = curPointer;
      
      mIsFullscreen = (mWindowFlags & (SDL_WINDOW_FULLSCREEN | SDL_WINDOW_FULLSCREEN_DESKTOP) );
      if (mIsFullscreen)
         displayState = sdsFullscreenInteractive;

      if (mIsOpenGL)
      {
         mOpenGLContext = HardwareRenderer::CreateOpenGL(0, 0, sgIsOGL2);
         mOpenGLContext->IncRef();
         //mOpenGLContext->SetWindowSize(inSurface->w, inSurface->h);
         mOpenGLContext->SetWindowSize(mWidth, mHeight);
         mPrimarySurface = new HardwareSurface(mOpenGLContext);
      }
      else
      {
         mOpenGLContext = 0;
         mSoftwareSurface = SDL_CreateRGBSurface(0, mWidth, mHeight, 32, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
         if (!mSoftwareSurface)
         {
            fprintf(stderr, "Could not create SDL surface : %s\n", SDL_GetError());
         }
         mSoftwareTexture = SDL_CreateTexture(mSDLRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, mWidth, mHeight);
         mPrimarySurface = new SDLSurf(mSoftwareSurface, inIsOpenGL);
      }
      mPrimarySurface->IncRef();
     
      #if defined(WEBOS) || defined(BLACKBERRY)
      mMultiTouch = true;
      #else
      mMultiTouch = false;
      #endif
      mSingleTouchID = NO_TOUCH;
      mDX = 0;
      mDY = 0;
      
      mDownX = 0;
      mDownY = 0;
   }
   
   
   ~SDLStage()
   {
      SDL_SetWindowFullscreen(mSDLWindow, 0);
      if (!mIsOpenGL)
      {
         SDL_FreeSurface(mSoftwareSurface);
         SDL_DestroyTexture(mSoftwareTexture);
      }
      else
      {
         mOpenGLContext->DecRef();
      }
      mPrimarySurface->DecRef();
      SDL_DestroyRenderer(mSDLRenderer);
      SDL_DestroyWindow(mSDLWindow); 

      #ifdef NME_WINDOWS_SINGLE_INSTANCE
      if ( sgMutexRunning )
      {
         ReleaseMutex( sgMutexRunning );
         sgMutexRunning = NULL;
      }
      #endif
   }
   
   
   void Resize(int inWidth, int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      
      if (mIsOpenGL)
      {
         mOpenGLContext->SetWindowSize(inWidth, inHeight);
      }
      else
      {
         SDL_FreeSurface(mSoftwareSurface);
         SDL_DestroyTexture(mSoftwareTexture);
         
         mSoftwareSurface = SDL_CreateRGBSurface(0, mWidth, mHeight, 32, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
         if (!mSoftwareSurface)
         {
            fprintf(stderr, "Could not create SDL surface : %s\n", SDL_GetError());
         }
         mSoftwareTexture = SDL_CreateTexture(mSDLRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, mWidth, mHeight);
         ((SDLSurf*)mPrimarySurface)->mSurf = mSoftwareSurface;
      }
   }
   
   
   void ResizeWindow(int inWidth, int inHeight)
   {
      #if !defined(RASPBERRYPI)
      if (mIsFullscreen)
      {
        /*
          Ignore
         SDL_DisplayMode mode;
         SDL_GetCurrentDisplayMode(0, &mode);
         
         mode.w = inWidth;
         mode.h = inHeight;
         
         SDL_SetWindowDisplayMode(mSDLWindow, &mode);
        */
      }
      else
      {
         SDL_SetWindowSize(mSDLWindow, inWidth, inHeight);
      }
      #endif
   }
   
   
   void SetFullscreen(bool inFullscreen)
   {
      if (inFullscreen != mIsFullscreen)
      {
         if (!mIsFullscreen)
         {
            SDL_GetWindowPosition(mSDLWindow, &sgWindowRect.x, &sgWindowRect.y);
            SDL_GetWindowSize(mSDLWindow, &sgWindowRect.w, &sgWindowRect.h);
         }

         mIsFullscreen = inFullscreen;
         
         if (mIsFullscreen)
         {
            //SDL_SetWindowSize(mSDLWindow, sgDesktopWidth, sgDesktopHeight);
            SDL_DisplayMode mode;
            SDL_GetCurrentDisplayMode(0, &mode);
            mode.w = sgDesktopWidth;
            mode.h = sgDesktopHeight;
            SDL_SetWindowDisplayMode(mSDLWindow, &mode);
            
            SDL_SetWindowFullscreen(mSDLWindow, FullscreenMode /*SDL_WINDOW_FULLSCREEN_DESKTOP*/);
         }
         else
         {
            SDL_SetWindowFullscreen(mSDLWindow, 0);
            /*
              Trust sdl to restore the window position
            #if !defined(HX_LINUX) && !defined(HX_MACOS)
            if (sgWindowRect.w && sgWindowRect.h)
            {
               SDL_SetWindowSize(mSDLWindow, sgWindowRect.w, sgWindowRect.h);
               SDL_SetWindowPosition(mSDLWindow, sgWindowRect.x, sgWindowRect.y);
            }
            #endif
            */
         }
         
         SDL_ShowCursor(mShowCursor);
      }
   }


   void SetResolution(int inWidth, int inHeight)
   {
      fprintf(stderr, "SetResolution %i %i\n", inWidth, inHeight);
      SDL_DisplayMode mode;
      SDL_GetCurrentDisplayMode(0, &mode);
      fprintf(stderr, "Current %i %i\n", mode.w, mode.h);
      mode.w = inWidth;
      mode.h = inHeight;
      SDL_SetWindowFullscreen(mSDLWindow, 0);
      SDL_SetWindowDisplayMode(mSDLWindow, &mode);
      SDL_SetWindowFullscreen(mSDLWindow, FullscreenMode);
   }
   

   void SetScreenMode(ScreenMode m)
   {
      if (m.width <= 1 || m.height <= 1)
      {
         //fprintf(stderr, "Stop calling me\n");
         return;
      }
      SDL_DisplayMode mode;
      mode.w = m.width;
      mode.h = m.height;
      mode.refresh_rate = m.refreshRate;
      switch (m.format) {
      case PIXELFORMAT_UNKNOWN:
         mode.format = SDL_PIXELFORMAT_UNKNOWN;
         break;
      case PIXELFORMAT_INDEX1LSB:
         mode.format = SDL_PIXELFORMAT_INDEX1LSB;
         break;
      case PIXELFORMAT_INDEX1MSB:
         mode.format = SDL_PIXELFORMAT_INDEX1MSB;
         break;
      case PIXELFORMAT_INDEX4LSB:
         mode.format = SDL_PIXELFORMAT_INDEX4LSB;
         break;
      case PIXELFORMAT_INDEX4MSB:
         mode.format = SDL_PIXELFORMAT_INDEX4MSB;
         break;
      case PIXELFORMAT_INDEX8:
         mode.format = SDL_PIXELFORMAT_INDEX8;
         break;
      case PIXELFORMAT_RGB332:
         mode.format = SDL_PIXELFORMAT_RGB332;
         break;
      case PIXELFORMAT_RGB444:
         mode.format = SDL_PIXELFORMAT_RGB444;
         break;
      case PIXELFORMAT_RGB555:
         mode.format = SDL_PIXELFORMAT_RGB555;
         break;
      case PIXELFORMAT_BGR555:
         mode.format = SDL_PIXELFORMAT_BGR555;
         break;
      case PIXELFORMAT_ARGB4444:
         mode.format = SDL_PIXELFORMAT_ARGB4444;
         break;
      case PIXELFORMAT_RGBA4444:
         mode.format = SDL_PIXELFORMAT_RGBA4444;
         break;
      case PIXELFORMAT_ABGR4444:
         mode.format = SDL_PIXELFORMAT_ABGR4444;
         break;
      case PIXELFORMAT_BGRA4444:
         mode.format = SDL_PIXELFORMAT_BGRA4444;
         break;
      case PIXELFORMAT_ARGB1555:
         mode.format = SDL_PIXELFORMAT_ARGB1555;
         break;
      case PIXELFORMAT_RGBA5551:
         mode.format = SDL_PIXELFORMAT_RGBA5551;
         break;
      case PIXELFORMAT_ABGR1555:
         mode.format = SDL_PIXELFORMAT_ABGR1555;
         break;
      case PIXELFORMAT_BGRA5551:
         mode.format = SDL_PIXELFORMAT_BGRA5551;
         break;
      case PIXELFORMAT_RGB565:
         mode.format = SDL_PIXELFORMAT_RGB565;
         break;
      case PIXELFORMAT_BGR565:
         mode.format = SDL_PIXELFORMAT_BGR565;
         break;
      case PIXELFORMAT_RGB24:
         mode.format = SDL_PIXELFORMAT_RGB24;
         break;
      case PIXELFORMAT_BGR24:
         mode.format = SDL_PIXELFORMAT_BGR24;
         break;
      case PIXELFORMAT_RGB888:
         mode.format = SDL_PIXELFORMAT_RGB888;
         break;
      case PIXELFORMAT_RGBX8888:
         mode.format = SDL_PIXELFORMAT_RGBX8888;
         break;
      case PIXELFORMAT_BGR888:
         mode.format = SDL_PIXELFORMAT_BGR888;
         break;
      case PIXELFORMAT_BGRX8888:
         mode.format = SDL_PIXELFORMAT_BGRX8888;
         break;
      case PIXELFORMAT_ARGB8888:
         mode.format = SDL_PIXELFORMAT_ARGB8888;
         break;
      case PIXELFORMAT_RGBA8888:
         mode.format = SDL_PIXELFORMAT_RGBA8888;
         break;
      case PIXELFORMAT_ABGR8888:
         mode.format = SDL_PIXELFORMAT_ABGR8888;
         break;
      case PIXELFORMAT_BGRA8888:
         mode.format = SDL_PIXELFORMAT_BGRA8888;
         break;
      case PIXELFORMAT_ARGB2101010:
         mode.format = SDL_PIXELFORMAT_ARGB2101010;
         break;
      case PIXELFORMAT_YV12:
         mode.format = SDL_PIXELFORMAT_YV12;
         break;
      case PIXELFORMAT_IYUV:
         mode.format = SDL_PIXELFORMAT_IYUV;
         break;
      case PIXELFORMAT_YUY2:
         mode.format = SDL_PIXELFORMAT_YUY2;
         break;
      case PIXELFORMAT_UYVY:
         mode.format = SDL_PIXELFORMAT_UYVY;
         break;
      case PIXELFORMAT_YVYU:
         mode.format = SDL_PIXELFORMAT_YVYU;
         break;
      }
      SDL_SetWindowFullscreen(mSDLWindow, 0);
      SDL_SetWindowDisplayMode(mSDLWindow, &mode);
      SDL_SetWindowFullscreen(mSDLWindow, FullscreenMode);
   }
    
   
   bool isOpenGL() const { return mOpenGLContext; }
   
   
   void ProcessEvent(Event &inEvent)
   {
      #if defined(HX_WINDOWS) || defined(HX_LINUX)
      if (inEvent.type == etKeyUp && (inEvent.flags & efAltDown) && inEvent.value == keyF4)
      {
         inEvent.type = etQuit;
      }
      #endif
      
      #if defined(WEBOS) || defined(BLACKBERRY)
      if (inEvent.type == etMouseMove || inEvent.type == etMouseDown || inEvent.type == etMouseUp)
      {
         if (mSingleTouchID == NO_TOUCH || inEvent.value == mSingleTouchID || !mMultiTouch)
         inEvent.flags |= efPrimaryTouch;
         
         if (mMultiTouch)
         {
            switch(inEvent.type)
            {
               case etMouseDown: inEvent.type = etTouchBegin; break;
               case etMouseUp: inEvent.type = etTouchEnd; break;
               case etMouseMove: inEvent.type = etTouchMove; break;
            }
            
            if (inEvent.type == etTouchBegin)
            {   
               mDownX = inEvent.x;
               mDownY = inEvent.y;   
            }
            
            if (inEvent.type == etTouchEnd)
            {   
               if (mSingleTouchID == inEvent.value)
                  mSingleTouchID = NO_TOUCH;
            }
         }
      }
      #endif
      
      HandleEvent(inEvent);
   }
   
   
   void Flip()
   {
      if (mIsOpenGL)
      {
         SDL_RenderPresent(mSDLRenderer);
      }
      else
      {
         SDL_UpdateTexture(mSoftwareTexture, NULL, mSoftwareSurface->pixels, mSoftwareSurface->pitch);
         //SDL_RenderClear(mSDLRenderer);
         SDL_RenderCopy(mSDLRenderer, mSoftwareTexture, NULL, NULL);
         SDL_RenderPresent(mSDLRenderer);
      }
   }
   
   
   void GetMouse()
   {
      
   }
   
   
   void SetCursor(Cursor inCursor)
   {
      if (sDefaultCursor==0)
         sDefaultCursor = SDL_GetCursor();
      
      mCurrentCursor = inCursor;
      
      if (inCursor==curNone || !mShowCursor)
         SDL_ShowCursor(false);
      else
      {
         SDL_ShowCursor(true);
         
         if (inCursor==curPointer)
            SDL_SetCursor(sDefaultCursor);
         else if (inCursor==curHand)
         {
            if (!sHandCursor)
               sHandCursor = CreateCursor(sHandCursorData,13,1);
            SDL_SetCursor(sHandCursor);
         }
         else
         {
         // TODO: Rotated
         if (sTextCursor==0)
            sTextCursor = CreateCursor(sTextCursorData,3,13);
         SDL_SetCursor(sTextCursor);
         }
      }
   }
   
   
   void ShowCursor(bool inShow)
   {
      if (inShow!=mShowCursor)
      {
         mShowCursor = inShow;
         this->SetCursor(mCurrentCursor);
      }
   }

    void ConstrainCursorToWindowFrame(bool inLock) 
    {
        if (inLock != mLockCursor) 
        {
           mLockCursor = inLock;
           SDL_SetRelativeMouseMode( inLock ? SDL_TRUE : SDL_FALSE );
        }
    }
   
      //Note that this fires a mouse event, see the SDL_WarpMouseInWindow docs
    void SetCursorPositionInWindow(int inX, int inY) 
    {
      SDL_WarpMouseInWindow( mSDLWindow, inX, inY );
    }   
   
      //Note that this fires a mouse event, see the SDL_WarpMouseInWindow docs
    void SetStageWindowPosition(int inX, int inY) 
    {
       if (!mIsFullscreen)
       {
          SDL_SetWindowPosition( mSDLWindow, inX, inY );
       }
    }   
 
   int GetWindowX() 
   {
      int x = 0;
      int y = 0;
      SDL_GetWindowPosition(mSDLWindow, &x, &y);
      return x;
   }   
 
  
   int GetWindowY() 
   {
      int x = 0;
      int y = 0;
      SDL_GetWindowPosition(mSDLWindow, &x, &y);
      return y;
   }   

   
   
   bool getMultitouchSupported()
   { 
      #if defined(WEBOS) || defined(BLACKBERRY)
      return true;
      #else
      return false;
      #endif
   }
   
   
   void setMultitouchActive(bool inActive) { mMultiTouch = inActive; }
   
   
   bool getMultitouchActive()
   {
      #if defined(WEBOS) || defined(BLACKBERRY)
      return mMultiTouch;
      #else
      return false;
      #endif
   }

   
   void setTitle(const std::string &inTitle)
   {
      SDL_SetWindowTitle(mSDLWindow, inTitle.c_str());
   }
   
   std::string getTitle() {
       return std::string(SDL_GetWindowTitle(mSDLWindow));
   }


   bool mMultiTouch;
   int  mSingleTouchID;
  
   double mDX;
   double mDY;

   double mDownX;
   double mDownY;
   
   const char *getJoystickName(int id)
   {
      if(SDL_IsGameController(id))
           return SDL_GameControllerNameForIndex(id);

      return SDL_JoystickNameForIndex(id);
   }
 
   void setIsFullscreen(bool inIsFullscreen)
   {
      mIsFullscreen = inIsFullscreen;

      displayState = mIsFullscreen ? sdsFullscreenInteractive : sdsNormal;
   }
  
   
   Surface *GetPrimarySurface()
   {
      return mPrimarySurface;
   }
   
   
   HardwareRenderer *mOpenGLContext;
   SDL_Window *mSDLWindow;
   SDL_Renderer *mSDLRenderer;
   Surface     *mPrimarySurface;
   SDL_Surface *mSoftwareSurface;
   SDL_Texture *mSoftwareTexture;
   bool         mIsOpenGL;
   Cursor       mCurrentCursor;
   bool         mShowCursor;
   bool            mLockCursor;   
   bool         mIsFullscreen;
   unsigned int mWindowFlags;
   int          mWidth;
   int          mHeight;
};


class SDLFrame : public Frame
{
public:
   SDLFrame(SDL_Window *inWindow, SDL_Renderer *inRenderer, uint32 inWindowFlags, bool inIsOpenGL, int inWidth, int inHeight)
   {
      mWindowFlags = inWindowFlags;
      mIsOpenGL = inIsOpenGL;
      mStage = new SDLStage(inWindow, inRenderer, mWindowFlags, inIsOpenGL, inWidth, inHeight);
      mStage->IncRef();
   }
   
   
   ~SDLFrame()
   {
      mStage->DecRef();
   }
   
   
   void ProcessEvent(Event &inEvent)
   {
      mStage->ProcessEvent(inEvent);
   }
   
   
   void Resize(int inWidth, int inHeight)
   {
      mStage->Resize(inWidth, inHeight);
   }
   
   
   // --- Frame Interface ----------------------------------------------------
   
   Stage *GetStage()
   {
      return mStage;
   }
   
   
   SDLStage *mStage;
   bool mIsOpenGL;
   uint32 mWindowFlags;
   
   double mAccX;
   double mAccY;
   double mAccZ;
};


// --- When using the simple window class -----------------------------------------------


extern "C" void MacBoot( /*void (*)()*/ );


SDLFrame *sgSDLFrame = 0;
#ifndef EMSCRIPTEN

#define MAX_JOYSTICKS 16
#define etControllerAxisMove etJoyAxisMove
#define etControllerButtonDown etJoyButtonDown
#define etControllerButtonUp etJoyButtonUp
QuickVec<int>*  userIds = NULL;

struct controllerState;
std::map<int, struct controllerState*> sgJoysticksState;
typedef struct controllerState 
{
   int joystickId;
   int userId;
   int controllerAxis[SDL_CONTROLLER_AXIS_MAX];
   int joyAxis[8];
   int hatx;
   int haty;
   bool isGameController;
   SDL_GameController * gameController;
   SDL_Joystick *sdlJoystick;
   controllerState(int joystickIndex):
      hatx(0),
      haty(0),
      joystickId(-1),
      sdlJoystick(NULL),
      userId(-1)
   {
     isGameController = SDL_IsGameController(joystickIndex);
     if(isGameController)
     {
        gameController = SDL_GameControllerOpen(joystickIndex);
        sdlJoystick = SDL_GameControllerGetJoystick(gameController);
     }
     else
     {
        gameController = NULL;
        sdlJoystick = SDL_JoystickOpen(joystickIndex);
     }
     if(sdlJoystick)
     {
        joystickId = SDL_JoystickInstanceID(sdlJoystick);
        memset((void*) controllerAxis, 0, sizeof(controllerAxis));
        memset((void*) joyAxis, 0, sizeof(joyAxis));
     }
   }

   bool add()
   {
     if(sdlJoystick)
     {
         if(joystickId>=0 && sgJoysticksState[joystickId]==NULL)
         {
            sgJoysticksState[joystickId] = this;
            userId = popUserId();
            if(userId>=0)
            {
               Event joystick(etJoyDeviceAdded);
               joystick.id = joystickId;
               joystick.value = userId;
               joystick.flags = 2;
               if(isGameController)
                 joystick.y = 1;
               sgSDLFrame->ProcessEvent(joystick);
               return true;
            }
         }
     }
     return false;
   }

   void remove()
   {
      if(gameController!=NULL)
      {
         SDL_GameControllerClose(gameController);
         Event joystick(etJoyDeviceRemoved);
         joystick.id = joystickId;
         joystick.value = userId;
         joystick.flags = 2;
         joystick.y = 1; //isGameController
         sgSDLFrame->ProcessEvent(joystick);
         gameController = NULL;
         sdlJoystick = NULL;
         sgJoysticksState.erase(joystickId);
      }
      else if(sdlJoystick!=NULL)
      {
         SDL_JoystickClose(sdlJoystick);
         Event joystick(etJoyDeviceRemoved);
         joystick.id = joystickId;
         joystick.value = userId;
         joystick.flags = 2;
         sgSDLFrame->ProcessEvent(joystick);
         sdlJoystick = NULL;
         sgJoysticksState.erase(joystickId);
      }
      if(userId>=0 && userId<MAX_JOYSTICKS)
      {
         pushUserId(userId);
      }
   }

   void controllerAxisMove(int code, int value)
   {
      int codex;
      int codey;
      int x;
      int y;

      if(code >= SDL_CONTROLLER_AXIS_MAX)
         return;

      if (code % 2 == 0)
      {
         codex = code;
         codey = code+1;
         SDL_GameControllerAxis codeyEnum = static_cast<SDL_GameControllerAxis>(codey);
         x = axisClamp(value);
         y = axisClamp(SDL_GameControllerGetAxis(gameController,codeyEnum));
      }
      else
      {
         codex = code-1;
         codey = code;
         SDL_GameControllerAxis codexEnum = static_cast<SDL_GameControllerAxis>(codex);
         x = axisClamp(SDL_GameControllerGetAxis(gameController,codexEnum));
         y = axisClamp(value);
      }
      if (controllerAxis[codex] != x || controllerAxis[codey] != y)
      {
         Event joystick(etControllerAxisMove);
         joystick.id = joystickId;
         joystick.code = codex;
         joystick.value = userId;
         joystick.scaleX = axisNormalize(x);
         joystick.scaleY = axisNormalize(y);
         joystick.flags = 3;
         joystick.y = 1; //isGameController
         sgSDLFrame->ProcessEvent(joystick);
         controllerAxis[codex] = x;
         controllerAxis[codey] = y;
      }
   }

   void joyAxisMove(int code, int value)
   {
      int codex;
      int codey;
      int x;
      int y;

      if(code >= 8)
         return;

      if (code % 2 == 0)
      {
         codex = code;
         codey = code+1;
         x = axisClamp(value);
         y = axisClamp(SDL_JoystickGetAxis(sdlJoystick,codey));
      }
      else
      {
         codex = code-1;
         codey = code;
         x = axisClamp(SDL_JoystickGetAxis(sdlJoystick,codex));
         y = axisClamp(value);
      }
      if (joyAxis[codex] != x || joyAxis[codey] != y)
      {
         Event joystick(etJoyAxisMove);
         joystick.id = joystickId;
         joystick.code = codex;
         joystick.value = userId;
         joystick.scaleX = axisNormalize(x);
         joystick.scaleY = axisNormalize(y);
         joystick.flags = 1;
         if(isGameController)
           joystick.y = 1;
         sgSDLFrame->ProcessEvent(joystick);
         joyAxis[codex] = x;
         joyAxis[codey] = y;
      }
   }


   void controllerHatEvent()
   {
      int x = SDL_GameControllerGetButton(gameController,SDL_CONTROLLER_BUTTON_DPAD_RIGHT)? 1 :
              SDL_GameControllerGetButton(gameController,SDL_CONTROLLER_BUTTON_DPAD_LEFT)? -1 : 0;
      int y = SDL_GameControllerGetButton(gameController,SDL_CONTROLLER_BUTTON_DPAD_UP)? 1 :
              SDL_GameControllerGetButton(gameController,SDL_CONTROLLER_BUTTON_DPAD_DOWN)? -1 : 0;
      if(x!=hatx || y!=haty)
      {
         Event joystick(etJoyHatMove);
         joystick.id = joystickId;
         joystick.code = 0;
         joystick.value = userId;
         joystick.scaleX = (float)x;
         joystick.scaleY = (float)y;
         joystick.y = 1; //isGameController
         sgSDLFrame->ProcessEvent(joystick);
         hatx = x;
         haty = y;
      }
   }
   
   void controllerButtonEvent(int button, bool pressed)
   {
      Event joystick(pressed? etControllerButtonDown: etControllerButtonUp);
      joystick.id = joystickId;
      joystick.code = button;
      joystick.value = userId;
      joystick.scaleX = pressed? 1.0f : 0.0f;
      joystick.y = 1; //isGameController
      sgSDLFrame->ProcessEvent(joystick);
   }

   void joyButtonEvent(int button, bool pressed)
   {
      Event joystick(pressed? etJoyButtonDown: etJoyButtonUp);
      joystick.id = joystickId;
      joystick.code = button;
      joystick.value = userId;
      joystick.scaleX = pressed? 1.0f : 0.0f;
      if(isGameController)
        joystick.y = 1;
      sgSDLFrame->ProcessEvent(joystick);
   }

   inline int axisClamp(int val)
   {
      return ( (val > -sgJoystickDeadZone && val < sgJoystickDeadZone) ? 0 : val );
   } 
   inline float axisNormalize(int val)
   {
      return (val == 0 ? 0.0f : val >=32767 ? 1.0f : val <= -32767 ? -1.0f : val / 32767.0f);
   }

   int popUserId()
   {
      if(userIds==NULL)
      {
         userIds = new QuickVec<int>(MAX_JOYSTICKS);
         for(int i=0; i<MAX_JOYSTICKS; i++)
            (*userIds)[i]=(MAX_JOYSTICKS-1-i);
      }   

      if(userIds->size()==0)
         return -1;

      //fprintf(stderr, "popUserId j:%d, id:%d\n", userIds->size(), (*userIds)[userIds->size()-1]);
      return userIds->qpop();
   }

   void pushUserId(int id)
   {
      int j = userIds->size();
      if(j<MAX_JOYSTICKS)
      {
         if(j==0 || id<(*userIds)[j-1])
         {
            userIds->qpush(id);
            //fprintf(stderr, "pushUserId j:%d, id:%d\n", j, id);
         }
         else
         {
            while(j>0)
            {
               j--;
               if(id<(*userIds)[j-1])
                  break;
            }
            userIds->InsertAt(j,id);
            //fprintf(stderr, "pushUserId j:%d, id:%d\n", j, id);
         }
      }
   }
} ControllerState;
#endif


void AddModStates(int &ioFlags,int inState = -1)
{
   int state = inState==-1 ? SDL_GetModState() : inState;
   if (state & KMOD_SHIFT) ioFlags |= efShiftDown;
   if (state & KMOD_CTRL) ioFlags |= efCtrlDown;
   if (state & KMOD_ALT) ioFlags |= efAltDown;
   if (state & KMOD_GUI) ioFlags |= efCommandDown;
   
   int m = SDL_GetMouseState(0,0);
   if ( m & SDL_BUTTON(1) ) ioFlags |= efLeftDown;
   if ( m & SDL_BUTTON(2) ) ioFlags |= efMiddleDown;
   if ( m & SDL_BUTTON(3) ) ioFlags |= efRightDown;
   
   ioFlags |= efPrimaryTouch;
   ioFlags |= efNoNativeClick;
}


#define SDL_TRANS(x) case SDLK_##x: return key##x;
#define SDL_TRANS_TO(x, y) case SDLK_##x: return key##y;


int SDLKeyToFlash(int inKey,bool &outRight)
{
   outRight = (inKey==SDLK_RSHIFT || inKey==SDLK_RCTRL ||
               inKey==SDLK_RALT || inKey==SDLK_RGUI);
   if (inKey>=keyA && inKey<=keyZ){
      return inKey;
   }
   if (inKey>=keyA+32 && inKey<=keyZ+32){
      return inKey - 32;
   }
   if (inKey>=SDLK_0 && inKey<=SDLK_9)
      return inKey - SDLK_0 + keyNUMBER_0;
   
   if (inKey>=SDLK_F1 && inKey<=SDLK_F12)
      return inKey - SDLK_F1 + keyF1;
   
   switch(inKey)
   {
      case SDLK_RALT:
      case SDLK_LALT:
         return keyALTERNATE;
      case SDLK_RSHIFT:
      case SDLK_LSHIFT:
         return keySHIFT;
      case SDLK_RCTRL:
      case SDLK_LCTRL:
         return keyCONTROL;
      case SDLK_LGUI:
      case SDLK_RGUI:
         return keyCOMMAND;
      
      case SDLK_CAPSLOCK: return keyCAPS_LOCK;
      case SDLK_PAGEDOWN: return keyPAGE_DOWN;
      case SDLK_PAGEUP: return keyPAGE_UP;
      case SDLK_EQUALS: return keyEQUAL;
      case SDLK_RETURN:
      case SDLK_KP_ENTER:
         return keyENTER;
      
      SDL_TRANS(AMPERSAND)
      SDL_TRANS(APPLICATION)
      SDL_TRANS(ASTERISK)
      SDL_TRANS(AT)
      SDL_TRANS(BACKQUOTE)
      SDL_TRANS(BACKSLASH)
      SDL_TRANS(BACKSPACE)
      SDL_TRANS(CARET)
      SDL_TRANS(COLON)
      SDL_TRANS(COMMA)
      SDL_TRANS(DELETE)
      SDL_TRANS(DOLLAR)
      SDL_TRANS(DOWN)
      SDL_TRANS(END)
      SDL_TRANS(ESCAPE)
      SDL_TRANS(EXCLAIM)
      SDL_TRANS(GREATER)
      SDL_TRANS(HASH)
      SDL_TRANS(HOME)
      SDL_TRANS(INSERT)
      SDL_TRANS(LEFT)
      SDL_TRANS(LEFTBRACKET)
      SDL_TRANS(LEFTPAREN)
      SDL_TRANS(LESS)
      SDL_TRANS(MINUS)
      SDL_TRANS(NUMLOCKCLEAR)
      SDL_TRANS(PAUSE)
      SDL_TRANS(PERCENT)
      SDL_TRANS(PERIOD)
      SDL_TRANS(PRINTSCREEN)
      SDL_TRANS(QUESTION)
      SDL_TRANS(QUOTE)
      SDL_TRANS(RIGHT)
      SDL_TRANS(RIGHTBRACKET)
      SDL_TRANS(RIGHTPAREN)
      SDL_TRANS(SCROLLLOCK)
      SDL_TRANS(SEMICOLON)
      SDL_TRANS(SLASH)
      SDL_TRANS(SPACE)
      SDL_TRANS(TAB)
      SDL_TRANS(UNDERSCORE)
      SDL_TRANS(UP)
      SDL_TRANS(F13)
      SDL_TRANS(F14)
      SDL_TRANS(F15)
      SDL_TRANS_TO(KP_0, NUMPAD_0)
      SDL_TRANS_TO(KP_1, NUMPAD_1)
      SDL_TRANS_TO(KP_2, NUMPAD_2)
      SDL_TRANS_TO(KP_3, NUMPAD_3)
      SDL_TRANS_TO(KP_4, NUMPAD_4)
      SDL_TRANS_TO(KP_5, NUMPAD_5)
      SDL_TRANS_TO(KP_6, NUMPAD_6)
      SDL_TRANS_TO(KP_7, NUMPAD_7)
      SDL_TRANS_TO(KP_8, NUMPAD_8)
      SDL_TRANS_TO(KP_9, NUMPAD_9)
      SDL_TRANS_TO(KP_PLUS, NUMPAD_ADD)
      SDL_TRANS_TO(KP_DECIMAL, NUMPAD_DECIMAL)
      SDL_TRANS_TO(KP_PERIOD, NUMPAD_DECIMAL)
      SDL_TRANS_TO(KP_DIVIDE, NUMPAD_DIVIDE)
      //SDL_TRANS_TO(KP_ENTER, NUMPAD_ENTER)
      SDL_TRANS_TO(KP_MULTIPLY, NUMPAD_MULTIPLY)
      SDL_TRANS_TO(KP_MINUS, NUMPAD_SUBTRACT)
   }

   return inKey;
}


void AddCharCode(Event &key)
{
   bool shift = (key.flags & efShiftDown);
   bool foundCode = true;
   
   if (!shift)
   {
      switch (key.value)
      {
         case 8:
         case 9:
         case 13:
         case 27:
         case 32:
            key.code = key.value;
            break;
         case 186:
            key.code = 59;
            break;
         case 187:
            key.code = 61;
            break;
         case 188:
         case 189:
         case 190:
         case 191:
            key.code = key.value - 144;
            break;
         case 192:
            key.code = 96;
            break;
         case 219:
         case 220:
         case 221:
            key.code = key.value - 128;
            break;
         case 222:
            key.code = 39;
            break;
         default:
            foundCode = false;
            break;
      }
   }
   else
   {
      switch (key.value)
      {
         case 48:
            key.code = 41;
            break;
         case 49:
            key.code = 33;
            break;
         case 50:
            key.code = 64;
            break;
         case 51:
         case 52:
         case 53:
            key.code = key.value - 16;
            break;
         case 54:
            key.code = 94;
            break;
         case 55:
            key.code = 38;
            break;
         case 56:
            key.code = 42;
            break;
         case 57:
            key.code = 40;
            break;
         case 186:
            key.code = 58;
            break;
         case 187:
            key.code = 43;
            break;
         case 188:
            key.code = 60;
            break;
         case 189:
            key.code = 95;
            break;
         case 190:
            key.code = 62;
            break;
         case 191:
            key.code = 63;
            break;
         case 192:
            key.code = 126;
            break;
         case 219:
         case 220:
         case 221:
            key.code = key.value - 96;
            break;
         case 222:
            key.code = 34;
            break;
         default:
            foundCode = false;
            break;
      }
   }
   
   if (!foundCode)
   {
      if (key.value >= 48 && key.value <= 57)
      {
         key.code = key.value;
      }
      else if (key.value >= 65 && key.value <= 90)
      {
         key.code = key.value;
      }
      else if (key.value >= 96 && key.value <= 105)
      {
         key.code = key.value - 48;
      }
      else if (key.value >= 106 && key.value <= 111)
      {
         key.code = key.value - 64;
      }
      else if (key.value == 46)
      {
         key.code = 127;
      }
      else if (key.value == 13)
      {
         key.code = 13;
      }
      else if (key.value == 8)
      {
         key.code = keyBACKSPACE;
      }
      else
      {
         key.code = 0;
      }
   }
}


wchar_t *ConvertToWChar(const char *inStr, int *ioLen)
{
   int len = ioLen ? *ioLen : strlen(inStr);

   //wchar_t *result = (wchar_t *)NewGCPrivate(0,sizeof(wchar_t)*(len+1));
   wchar_t *result = (wchar_t *)alloc_private((len+1)*sizeof(wchar_t));
   int l = 0;

   unsigned char *b = (unsigned char *)inStr;
   for(int i=0;i<len;)
   {
      int c = b[i++];
      if (c==0) break;
      else if( c < 0x80 )
      {
        result[l++] = c;
      }
      else if( c < 0xE0 )
        result[l++] = ( ((c & 0x3F) << 6) | (b[i++] & 0x7F) );
      else if( c < 0xF0 )
      {
        int c2 = b[i++];
        result[l++] = ( ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | ( b[i++] & 0x7F) );
      }
      else
      {
        int c2 = b[i++];
        int c3 = b[i++];
        result[l++] = ( ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 << 6) & 0x7F) | (b[i++] & 0x7F) );
      }
   }
   result[l] = '\0';
   if (ioLen)
      *ioLen = l;
   return result;
}


void ProcessEvent(SDL_Event &inEvent)
{
   if (inEvent.type!=SDL_WINDOWEVENT && gCurrentFileDialog)
      return;

   switch(inEvent.type)
   {
      case SDL_QUIT:
      {
         Event close(etQuit);
         sgSDLFrame->ProcessEvent(close);
         break;
      }
      case SDL_WINDOWEVENT:
      {
         switch (inEvent.window.event)
         {
            case SDL_WINDOWEVENT_SHOWN:
            {
               Event activate(etActivate);
               sgSDLFrame->ProcessEvent(activate);
               break;
            }
            case SDL_WINDOWEVENT_HIDDEN:
            {
               Event deactivate(etDeactivate);
               sgSDLFrame->ProcessEvent(deactivate);
               break;
            }
            case SDL_WINDOWEVENT_EXPOSED:
            {
               Event poll(etPoll);
               sgSDLFrame->ProcessEvent(poll);
               break;
            }
            //case SDL_WINDOWEVENT_MOVED: break;
            //case SDL_WINDOWEVENT_RESIZED: break;
            case SDL_WINDOWEVENT_SIZE_CHANGED:
            {
               Event resize(etResize, inEvent.window.data1, inEvent.window.data2);
               sgSDLFrame->Resize(inEvent.window.data1, inEvent.window.data2);
               sgSDLFrame->ProcessEvent(resize);
               break;
            }
            case SDL_WINDOWEVENT_MINIMIZED:
            {
               sgSDLFrame->mStage->setIsFullscreen(false);
               Event deactivate(etDeactivate);
               sgSDLFrame->ProcessEvent(deactivate);
               break;
            }

            case SDL_WINDOWEVENT_RESTORED:
            case SDL_WINDOWEVENT_MAXIMIZED:
               {
               bool isMax = SDL_GetWindowFlags(sgSDLFrame->mStage->mSDLWindow ) &
                            (SDL_WINDOW_FULLSCREEN|SDL_WINDOW_FULLSCREEN_DESKTOP);
               sgSDLFrame->mStage->setIsFullscreen(isMax);

               Event activate(etActivate);
               sgSDLFrame->ProcessEvent(activate);

               int width = 0;
               int height = 0;
               SDL_GetWindowSize(sgSDLFrame->mStage->mSDLWindow, &width, &height);

               Event resize(etResize, width, height);
               sgSDLFrame->Resize(width,height);
               sgSDLFrame->ProcessEvent(resize);
               }
               break;

            //case SDL_WINDOWEVENT_ENTER: break;
            //case SDL_WINDOWEVENT_LEAVE: break;
            case SDL_WINDOWEVENT_FOCUS_GAINED:
            {
               Event inputFocus(etGotInputFocus);
               sgSDLFrame->ProcessEvent(inputFocus);
               break;
            }
            case SDL_WINDOWEVENT_FOCUS_LOST:
            {
               Event inputFocus(etLostInputFocus);
               sgSDLFrame->ProcessEvent(inputFocus);
               break;
            }
            case SDL_WINDOWEVENT_CLOSE:
            {
               //Event deactivate(etDeactivate);
               //sgSDLFrame->ProcessEvent(deactivate);
               
               //Event kill(etDestroyHandler);
               //sgSDLFrame->ProcessEvent(kill);
               break;
            }

            /*
            case SDL_DROPFILE:
            {
               char *dropped_filedir = inEvent.drop.file;
               printf("DROP %s\n", dropped_filedir);
               SDL_free(dropped_filedir);
               break;
            }
            */

            default: break;
         }
         
         break;
         
      }
      case SDL_MOUSEMOTION:
      {  
            //default to 0
         int deltaX = 0;
         int deltaY = 0;

            //but if we are locking the cursor,
            //pass the delta in as well through as deltaX
         if(SDL_GetRelativeMouseMode()) {
            SDL_GetRelativeMouseState( &deltaX, &deltaY );
         }

            //int inValue=0, int inID=0, int inFlags=0, float inScaleX=1,float inScaleY=1, int inDeltaX=0,int inDeltaY=0
         Event mouse(etMouseMove, inEvent.motion.x, inEvent.motion.y, 0, 0, 0, 1.0f, 1.0f, deltaX, deltaY);
         #if defined(WEBOS) || defined(BLACKBERRY)
         mouse.value = inEvent.motion.which;
         mouse.flags |= efLeftDown;
         #else
         AddModStates(mouse.flags);
         #endif
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }
      case SDL_MOUSEBUTTONDOWN:
      {
         Event mouse(etMouseDown, inEvent.button.x, inEvent.button.y, inEvent.button.button - 1);
         #if defined(WEBOS) || defined(BLACKBERRY)
         mouse.value = inEvent.motion.which;
         mouse.flags |= efLeftDown;
         #else
         AddModStates(mouse.flags);
         #endif
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }
      case SDL_MOUSEBUTTONUP:
      {
         Event mouse(etMouseUp, inEvent.button.x, inEvent.button.y, inEvent.button.button - 1);
         #if defined(WEBOS) || defined(BLACKBERRY)
         mouse.value = inEvent.motion.which;
         #else
         AddModStates(mouse.flags);
         #endif
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }
      case SDL_MOUSEWHEEL: 
      {   
            //previous behavior in nme was fake button 3 for down, 4 for up
         int event_dir = (inEvent.wheel.y > 0) ? 3 : 4;
            //space to get the current mouse position, to make sure the values are sane
         int _x = 0; 
         int _y = 0;
            //fetch the mouse position
         SDL_GetMouseState(&_x,&_y);
            //create the event
         Event mouse(etMouseUp, _x, _y, event_dir);
         mouse.deltaX = inEvent.wheel.x;
         mouse.deltaY = inEvent.wheel.y;
            //add flags for modifier keys
         AddModStates(mouse.flags);
            //and done.
         sgSDLFrame->ProcessEvent(mouse);
         break;
      }
        case SDL_TEXTINPUT:
        {
            const char *text = inEvent.text.text;
            int unicode = ConvertToWChar(text, 0)[0];
            Event key( etChar );
            key.code = unicode;
            sgSDLFrame->ProcessEvent(key);
            break;
        }
      case SDL_KEYDOWN:
      case SDL_KEYUP:
      {
         Event key(inEvent.type == SDL_KEYDOWN ? etKeyDown : etKeyUp );
         bool right;
         key.value = SDLKeyToFlash(inEvent.key.keysym.sym, right);
         /*if (inEvent.type == SDL_KEYDOWN)
         {
            //key.code = key.value==keyBACKSPACE ? keyBACKSPACE : inEvent.key.keysym.unicode;
            key.code = inEvent.key.keysym.scancode;
            sLastUnicode[inEvent.key.keysym.scancode] = key.code;
         }
         else
            // SDL does not provide unicode on key up, so remember it,
            //  keyed by scancode
            key.code = sLastUnicode[inEvent.key.keysym.scancode];*/
         //key.code = 0;
         AddModStates(key.flags, inEvent.key.keysym.mod);
         if (right)
            key.flags |= efLocationRight;
         
         // SDL2 does not expose char codes in key events (due to the more advanced
         // Unicode event API), so we'll add some ASCII assumptions to return something
         AddCharCode(key);
         sgSDLFrame->ProcessEvent(key);
         break;
      }
      case SDL_CONTROLLERAXISMOTION:
      {   
         ControllerState* controller = sgJoysticksState[inEvent.jbutton.which];
         if(controller != NULL)
            controller->controllerAxisMove(inEvent.jaxis.axis, inEvent.jaxis.value);
         break;
      }
      case SDL_CONTROLLERBUTTONDOWN:
      case SDL_CONTROLLERBUTTONUP:
      {     
         ControllerState* controller = sgJoysticksState[inEvent.jbutton.which];
         if(controller!=NULL)
         {
             if(inEvent.jbutton.button>=SDL_CONTROLLER_BUTTON_DPAD_UP) 
                controller->controllerHatEvent();
             else
             controller->controllerButtonEvent(inEvent.jbutton.button, inEvent.jbutton.state==SDL_PRESSED);
         }
         break;
      }
      //case SDL_CONTROLLERDEVICEADDED:
      case SDL_JOYDEVICEADDED:
      {
         int index = inEvent.jdevice.which;
         ControllerState* controller = new controllerState(index);
         if(!controller->add())
         {
            delete controller;
         }
         break;
      }
      //case SDL_CONTROLLERDEVICEREMOVED:
      case SDL_JOYDEVICEREMOVED:
      {
         ControllerState* controller = sgJoysticksState[inEvent.jdevice.which];
         if(controller != NULL)
         {
            controller->remove();
            delete controller;
         }
         break;
      }
      case SDL_JOYAXISMOTION:
      {   
         ControllerState* controller = sgJoysticksState[inEvent.jbutton.which];
         if(controller != NULL && !controller->isGameController)
            controller->joyAxisMove(inEvent.jaxis.axis, inEvent.jaxis.value);
         break;
      }
      case SDL_JOYBUTTONDOWN:
      case SDL_JOYBUTTONUP:
      {     
         ControllerState* controller = sgJoysticksState[inEvent.jbutton.which];
         if(controller!=NULL && !controller->isGameController)
             controller->joyButtonEvent(inEvent.jbutton.button, inEvent.jbutton.state==SDL_PRESSED);
         break;
      }
      case SDL_JOYBALLMOTION:
      {
         ControllerState* controller = sgJoysticksState[inEvent.jbutton.which];
         if(controller!=NULL && !controller->isGameController)
         {
            Event joystick(etJoyBallMove);
            joystick.id = controller->joystickId;
            joystick.code = inEvent.jball.ball;
            joystick.value = controller->userId;
            joystick.scaleX = inEvent.jball.xrel;
            joystick.scaleY = inEvent.jball.yrel;
            sgSDLFrame->ProcessEvent(joystick);
         }
         break;
      }
      case SDL_JOYHATMOTION:
      {
         ControllerState* controller = sgJoysticksState[inEvent.jbutton.which];
         if(controller!=NULL && !controller->isGameController)
         {
            Event joystick(etJoyHatMove);
            joystick.id = controller->joystickId;
            joystick.code = 0;
            joystick.value = controller->userId;
            joystick.scaleX = inEvent.jhat.hat & SDL_HAT_RIGHT ? 1.0f : 
                              inEvent.jhat.hat & SDL_HAT_LEFT  ?-1.0f : 0.0f;
            joystick.scaleY = inEvent.jhat.hat & SDL_HAT_UP    ? 1.0f : 
                              inEvent.jhat.hat & SDL_HAT_DOWN  ?-1.0f : 0.0f;
            sgSDLFrame->ProcessEvent(joystick);
         }
         break;
      }
   }
};

#if (defined(HX_WINDOWS) && !defined(HX_WINRT))

#ifndef GWL_WNDPROC
   #define GWL_WNDPROC GWLP_WNDPROC
#endif

struct WinData
{
   WNDPROC proc;
   SDLFrame *frame;

   WinData(WNDPROC inProc=0, SDLFrame *inFrame=0) : proc(inProc), frame(inFrame) { }
};

std::map<HWND,WinData> oldWinProcs;

LRESULT CALLBACK NmeWinProc(
    HWND hwnd,        // handle to window
    UINT uMsg,        // message identifier
    WPARAM wParam,    // first message parameter
    LPARAM lParam)    // second message parameter
{ 
   WinData next = oldWinProcs[hwnd];

   if (uMsg==WM_DESTROY && next.proc)
   {
      SetWindowLongPtr(hwnd, GWL_WNDPROC, (LONG_PTR)next.proc);
      oldWinProcs.erase( oldWinProcs.find(hwnd) );
   }
   else if (uMsg==0x02E0 /*WM_DPICHANGED*/)
   {
      //printf("WM_DPICHANGED %d,%d ... %d,%d\n", rect->left, rect->top, rect->right, rect->bottom);
      RECT* const rect = (RECT*)lParam;
      SetWindowPos(hwnd,
         NULL,
         rect->left,
         rect->top,
         rect->right - rect->left,
         rect->bottom - rect->top,
         SWP_NOZORDER | SWP_NOACTIVATE);

      Event dpiChanged(etDpiChanged);
      dpiChanged.x = LOWORD(wParam);
      dpiChanged.y = HIWORD(wParam);
      sgSDLFrame->ProcessEvent(dpiChanged);
   }

   if (next.proc)
      return CallWindowProc(next.proc, hwnd, uMsg, wParam, lParam);
   return 0;
}

void insertWinProc(HWND hwnd,SDLFrame *frame)
{
   WNDPROC proc = (WNDPROC)SetWindowLongPtr(hwnd, GWL_WNDPROC, (LONG_PTR)NmeWinProc);
   oldWinProcs[hwnd] = WinData(proc,frame);
}

#endif

void CreateMainFrame(FrameCreationCallback inOnFrame, int inWidth, int inHeight, unsigned int inFlags, const char *inTitle, Surface *inIcon)
{
   #ifdef HX_MACOS
   MacBoot();
   #endif
   
   bool fullscreen = (inFlags & wfFullScreen) != 0;
   bool opengl = (inFlags & wfHardware) != 0;
   bool resizable = (inFlags & wfResizable) != 0;
   bool borderless = (inFlags & wfBorderless) != 0;
   bool vsync = (inFlags & wfVSync) != 0;
   //WindowScaleMode scaleMode = (WindowScaleMode)( (inFlags & wfScaleMask)/wfScaleBase );

   #ifdef HX_LINUX
   if (opengl)
   {
      if (!InitOGLFunctions())
        opengl = false;
   }
   #endif

   #ifdef NME_WINDOWS_SINGLE_INSTANCE
   bool singleInstance = (inFlags & wfSingleInstance) != 0;
   if (singleInstance)
   {
      // Detect previous instances of game
      HANDLE sgMutexRunning = OpenMutex( MUTEX_ALL_ACCESS, 0, inTitle );
      if ( !sgMutexRunning )
      {
         sgMutexRunning = CreateMutex( 0, 0, inTitle );
      }
      else
      {
         MessageBox( NULL, (LPCSTR)"An instance of the game is already running.",
                           (LPCSTR)"Application already running", MB_ICONWARNING | MB_OK );
         return;
      }
   }
   #endif   
   
   //Rect r(100,100,inWidth,inHeight);
   
   int err = InitSDL();
   if (err == -1)
   {
      fprintf(stderr,"Could not initialize SDL : %s\n", SDL_GetError());
      inOnFrame(0);
   }
   
   //SDL_EnableUNICODE(1);
   //SDL_EnableKeyRepeat(500,30);

   #ifdef NME_MIXER
   openAudio();
   #endif
   
   if (SDL_GetNumVideoDisplays() > 0)
   {
      SDL_DisplayMode currentMode;
      SDL_GetDesktopDisplayMode(0, &currentMode);
      sgDesktopWidth = currentMode.w;
      sgDesktopHeight = currentMode.h;
   }
   
   int windowFlags, requestWindowFlags = 0;
   
   if (opengl) requestWindowFlags |= SDL_WINDOW_OPENGL;
   if (resizable) requestWindowFlags |= SDL_WINDOW_RESIZABLE;
   if (borderless) requestWindowFlags |= SDL_WINDOW_BORDERLESS;
   if (fullscreen) requestWindowFlags |= FullscreenMode; //SDL_WINDOW_FULLSCREEN_DESKTOP;
   
   #ifdef NME_ANGLE
   SDL_GL_SetAttribute(SDL_GL_CONTEXT_EGL, 1); 
   SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES); 
   SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3); 
   SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3); 
   #endif

   if (opengl)
   {
      SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
      SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
      SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
      
      if (inFlags & wfDepthBuffer)
         SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 32 - (inFlags & wfStencilBuffer) ? 8 : 0);
      
      if (inFlags & wfStencilBuffer)
         SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
      
      SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
      
      if (inFlags & wfHW_AA_HIRES)
      {
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, true);
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
      }
      else if (inFlags & wfHW_AA)
      {
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, true);
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 2);
      }
   }

   double dpiScale = CapabilitiesGetScreenDPI()/96.0;
   int targetW = dpiScale<1.5 ? inWidth : dpiScale*inWidth;
   if (targetW>sgDesktopWidth)
      targetW = sgDesktopWidth;
   int targetH = dpiScale<1.5 ? inHeight : dpiScale*inHeight;
   if (targetH>sgDesktopHeight)
      targetH = sgDesktopHeight;

   int targetX = SDL_WINDOWPOS_UNDEFINED;
   int targetY = SDL_WINDOWPOS_UNDEFINED;

   #if (defined(HX_WINDOWS) && !defined(HX_WINRT))
   HWND hWin = 0;

   if (!borderless && !fullscreen)
   {
      DWORD style = WS_CLIPSIBLINGS | WS_CLIPCHILDREN | WS_OVERLAPPED |
                    WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
      if (resizable)
         style |= WS_THICKFRAME | WS_MAXIMIZEBOX;

       RECT r;
       r.left =  r.top = 0;
       r.right = r.bottom = 100;
       AdjustWindowRectEx(&r, style, FALSE, 0);
       int borderW = r.right-r.left - 100;
       int borderH = r.bottom-r.top - 100;
       if (targetH + borderH > sgDesktopHeight)
       {
          targetY = -r.top;
          targetH = sgDesktopHeight - borderH;
       }
       if (targetW + borderW > sgDesktopWidth)
       {
          targetX = -r.left;
          targetW = sgDesktopWidth - borderW;
       }
   }
   #endif
   
   #ifdef HX_LINUX
   int setWidth = targetW;
   int setHeight = targetH;
   #else
   int setWidth = fullscreen ? sgDesktopWidth : targetW;
   int setHeight = fullscreen ? sgDesktopHeight : targetH;
   #endif

   SDL_Window *window = NULL;
   SDL_Renderer *renderer = NULL;

   while (!window || !renderer) 
   {
      // if there's an old window around from a failed attempt, destroy it
      if (window) 
      {
         SDL_DestroyWindow(window);
         window = NULL;
      }

      window = SDL_CreateWindow(inTitle, targetX, targetY, setWidth, setHeight, requestWindowFlags);
      
      #if (defined(HX_WINDOWS) && !defined(HX_WINRT))
      HINSTANCE handle = ::GetModuleHandle(0);
      LPSTR resource = MAKEINTRESOURCE(101);
      LPARAM icon = (LPARAM)::LoadImage(handle, resource, IMAGE_ICON, 
         GetSystemMetrics(SM_CXICON), GetSystemMetrics(SM_CYICON), 0);
      LPARAM smicon = (LPARAM)::LoadImage(handle, resource, IMAGE_ICON, 
         GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), 0);
      
      SDL_SysWMinfo wminfo;
      SDL_VERSION (&wminfo.version);
      if (SDL_GetWindowWMInfo(window, &wminfo) == 1)
      {
         hWin = wminfo.info.win.window;
         if (icon)
         {
            ::SendMessage(hWin, WM_SETICON, ICON_BIG, icon);
            if(smicon)
                ::SendMessage(hWin, WM_SETICON, ICON_SMALL, smicon);
            else
                ::SendMessage(hWin, WM_SETICON, ICON_SMALL, icon);
         }
      }
      #endif
     
      // retrieve the actual window flags (as opposed to the requested ones)
      windowFlags = SDL_GetWindowFlags (window);
      if (fullscreen) sgWindowRect = Rect(SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, inWidth, inHeight);

      int renderFlags = 0;
      if (opengl) renderFlags |= SDL_RENDERER_ACCELERATED;
      if (opengl && vsync) renderFlags |= SDL_RENDERER_PRESENTVSYNC;

      renderer = SDL_CreateRenderer (window, -1, renderFlags);
      
      if (opengl)
      {
         sgIsOGL2 = (inFlags & (wfAllowShaders | wfRequireShaders));
      }
      else
      {
         sgIsOGL2 = false;
      }
      
      if (!renderer && (inFlags & wfHW_AA_HIRES || inFlags & wfHW_AA)) {
         // if no window was created and AA was enabled, disable AA and try again
         fprintf(stderr, "Multisampling is not available. Retrying without. (%s)\n", SDL_GetError());
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, false);
         SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0);
         inFlags &= ~wfHW_AA_HIRES;
         inFlags &= ~wfHW_AA;
      }
      else if (!renderer && opengl) 
      {
         // if opengl is enabled and no window was created, disable it and try again
         fprintf(stderr, "OpenGL is not available. Retrying without. (%s)\n", SDL_GetError());
         opengl = false;
         requestWindowFlags &= ~SDL_WINDOW_OPENGL;
      }
      else 
      {
         // no more things to try, break out of the loop
         break;
      }
   }

   if (!window)
   {
      fprintf(stderr, "Failed to create SDL window: %s\n", SDL_GetError());
      return;
   }  
   
   if (!renderer)
   {
      fprintf(stderr, "Failed to create SDL renderer: %s\n", SDL_GetError());
      return;
   }
   
   int width, height;
   if (windowFlags & (SDL_WINDOW_FULLSCREEN | SDL_WINDOW_FULLSCREEN_DESKTOP) )
   {
      //SDL_DisplayMode mode;
      //SDL_GetCurrentDisplayMode(0, &mode);
      //width = mode.w;
      //height = mode.h;
      width = sgDesktopWidth;
      height = sgDesktopHeight;
   }
   else
   {
      SDL_GetWindowSize(window, &width, &height);
   }
   
   sgSDLFrame = new SDLFrame(window, renderer, windowFlags, opengl, width, height);
   #if (defined(HX_WINDOWS) && !defined(HX_WINRT))
   insertWinProc(hWin,sgSDLFrame);
   #endif
   inOnFrame(sgSDLFrame);

   //int numJoysticks = SDL_NumJoysticks();
   //SDL_GameControllerEventState(SDL_TRUE);

   StartAnimation();
}


bool sgDead = false;


void SetIcon(const char *path)
{
   
}

#if (defined(HX_WINDOWS) && !defined(HX_WINRT))
HWND GetApplicationWindow()
{
   if (!sgSDLFrame)
      return 0;

   SDL_SysWMinfo wminfo;
   SDL_VERSION (&wminfo.version);
   if (SDL_GetWindowWMInfo(sgSDLFrame->mStage->mSDLWindow, &wminfo) == 1)
       return wminfo.info.win.window;

   return 0;
}
#endif


QuickVec<int>* CapabilitiesGetScreenResolutions()
{   
   InitSDL();
   QuickVec<int> *out = new QuickVec<int>();
   
   int numModes = SDL_GetNumDisplayModes(0);
   SDL_DisplayMode mode;
   
   for (int i = 0; i < numModes; i++)
   {
      SDL_GetDisplayMode(0, i, &mode);
      out->push_back(mode.w);
      out->push_back(mode.h);
   }
   
   return out;
}


QuickVec<ScreenMode>* CapabilitiesGetScreenModes()
{
   InitSDL();
   QuickVec<ScreenMode> *out = new QuickVec<ScreenMode>();

   int numModes = SDL_GetNumDisplayModes(0);
   SDL_DisplayMode mode;

   for (int i = 0; i < numModes; i++)
   {
      SDL_GetDisplayMode(0, i, &mode);
      ScreenMode screenMode;
      screenMode.width = mode.w;
      screenMode.height = mode.h;
      switch (mode.format) {
      case SDL_PIXELFORMAT_UNKNOWN:
         screenMode.format = PIXELFORMAT_UNKNOWN;
         break;
      case SDL_PIXELFORMAT_INDEX1LSB:
         screenMode.format = PIXELFORMAT_INDEX1LSB;
         break;
      case SDL_PIXELFORMAT_INDEX1MSB:
         screenMode.format = PIXELFORMAT_INDEX1MSB;
         break;
      case SDL_PIXELFORMAT_INDEX4LSB:
         screenMode.format = PIXELFORMAT_INDEX4LSB;
         break;
      case SDL_PIXELFORMAT_INDEX4MSB:
         screenMode.format = PIXELFORMAT_INDEX4MSB;
         break;
      case SDL_PIXELFORMAT_INDEX8:
         screenMode.format = PIXELFORMAT_INDEX8;
         break;
      case SDL_PIXELFORMAT_RGB332:
         screenMode.format = PIXELFORMAT_RGB332;
         break;
      case SDL_PIXELFORMAT_RGB444:
         screenMode.format = PIXELFORMAT_RGB444;
         break;
      case SDL_PIXELFORMAT_RGB555:
         screenMode.format = PIXELFORMAT_RGB555;
         break;
      case SDL_PIXELFORMAT_BGR555:
         screenMode.format = PIXELFORMAT_BGR555;
         break;
      case SDL_PIXELFORMAT_ARGB4444:
         screenMode.format = PIXELFORMAT_ARGB4444;
         break;
      case SDL_PIXELFORMAT_RGBA4444:
         screenMode.format = PIXELFORMAT_RGBA4444;
         break;
      case SDL_PIXELFORMAT_ABGR4444:
         screenMode.format = PIXELFORMAT_ABGR4444;
         break;
      case SDL_PIXELFORMAT_BGRA4444:
         screenMode.format = PIXELFORMAT_BGRA4444;
         break;
      case SDL_PIXELFORMAT_ARGB1555:
         screenMode.format = PIXELFORMAT_ARGB1555;
         break;
      case SDL_PIXELFORMAT_RGBA5551:
         screenMode.format = PIXELFORMAT_RGBA5551;
         break;
      case SDL_PIXELFORMAT_ABGR1555:
         screenMode.format = PIXELFORMAT_ABGR1555;
         break;
      case SDL_PIXELFORMAT_BGRA5551:
         screenMode.format = PIXELFORMAT_BGRA5551;
         break;
      case SDL_PIXELFORMAT_RGB565:
         screenMode.format = PIXELFORMAT_RGB565;
         break;
      case SDL_PIXELFORMAT_BGR565:
         screenMode.format = PIXELFORMAT_BGR565;
         break;
      case SDL_PIXELFORMAT_RGB24:
         screenMode.format = PIXELFORMAT_RGB24;
         break;
      case SDL_PIXELFORMAT_BGR24:
         screenMode.format = PIXELFORMAT_BGR24;
         break;
      case SDL_PIXELFORMAT_RGB888:
         screenMode.format = PIXELFORMAT_RGB888;
         break;
      case SDL_PIXELFORMAT_RGBX8888:
         screenMode.format = PIXELFORMAT_RGBX8888;
         break;
      case SDL_PIXELFORMAT_BGR888:
         screenMode.format = PIXELFORMAT_BGR888;
         break;
      case SDL_PIXELFORMAT_BGRX8888:
         screenMode.format = PIXELFORMAT_BGRX8888;
         break;
      case SDL_PIXELFORMAT_ARGB8888:
         screenMode.format = PIXELFORMAT_ARGB8888;
         break;
      case SDL_PIXELFORMAT_RGBA8888:
         screenMode.format = PIXELFORMAT_RGBA8888;
         break;
      case SDL_PIXELFORMAT_ABGR8888:
         screenMode.format = PIXELFORMAT_ABGR8888;
         break;
      case SDL_PIXELFORMAT_BGRA8888:
         screenMode.format = PIXELFORMAT_BGRA8888;
         break;
      case SDL_PIXELFORMAT_ARGB2101010:
         screenMode.format = PIXELFORMAT_ARGB2101010;
         break;
      case SDL_PIXELFORMAT_YV12:
         screenMode.format = PIXELFORMAT_YV12;
         break;
      case SDL_PIXELFORMAT_IYUV:
         screenMode.format = PIXELFORMAT_IYUV;
         break;
      case SDL_PIXELFORMAT_YUY2:
         screenMode.format = PIXELFORMAT_YUY2;
         break;
      case SDL_PIXELFORMAT_UYVY:
         screenMode.format = PIXELFORMAT_UYVY;
         break;
      case SDL_PIXELFORMAT_YVYU:
         screenMode.format = PIXELFORMAT_YVYU;
         break;
      }
      screenMode.refreshRate = mode.refresh_rate;
      out->push_back(screenMode);
   }

   return out;
 }


double CapabilitiesGetScreenResolutionX()
{
   InitSDL();   
   return sgDesktopWidth;
}


double CapabilitiesGetScreenResolutionY()
{   
   InitSDL();   
   return sgDesktopHeight;
}


void PauseAnimation() {}
void ResumeAnimation() {}


void StopAnimation()
{
   #ifdef NME_MIXER
   if (gSDLAudioState==sdaOpen)
   {
      gSDLAudioState = sdaClosed;
      Mix_CloseAudio();
   }
   #else
   Sound::Shutdown();
   #endif
   sgDead = true;
}


static SDL_TimerID sgTimerID = 0;



#ifndef SDL_NOEVENT
#define SDL_NOEVENT -1;
#endif


void StartAnimation()
{
   SDL_Event event;
   event.type = SDL_NOEVENT;

   //SDL_EventState(SDL_DROPFILE, SDL_ENABLE);

   double nextWake = GetTimeStamp();
   while(!sgDead)
   {
      // Process real events ...
      while(SDL_PollEvent(&event))
      {
         ProcessEvent(event);
         if (sgDead)
            break;
      }
 
      // Poll
      Event poll(etPoll);
      sgSDLFrame->ProcessEvent(poll);
      nextWake = sgSDLFrame->GetStage()->GetNextWake();
      if (sgDead)
         break;

      if (gCurrentFileDialog && gCurrentFileDialog->isFinished)
         gCurrentFileDialog->complete();

      double dWaitMs = (nextWake - GetTimeStamp())*1000.0 + 0.5;
      if (dWaitMs>1000000)
         dWaitMs = 1000000;
      int waitMs = (int)dWaitMs;
      if (gCurrentFileDialog && waitMs<100)
         waitMs = 100;

      // Kill some time
      if (waitMs>0)
      {
         AutoGCBlocking block;
         if (sgSDLFrame->mStage->BuildCache())
         {
            block.Close();
            Event redraw(etRedraw);
            sgSDLFrame->ProcessEvent(redraw);
         }
         else
         {
            // Windows will oversleep 10ms for any positive number here...
            #ifdef HX_WINDOWS
            if (waitMs>10)
               SDL_Delay(1);
            else
               SDL_Delay(0);
            #else
            // TODO - check this is ok for other targets...
            if (waitMs>10)
               SDL_Delay(10);
            else if (waitMs>1)
               SDL_Delay(waitMs-1);
            #endif
         }
      }
   }

   Event deactivate(etDeactivate);
   sgSDLFrame->ProcessEvent(deactivate);
      
#ifdef NME_WINDOWS_SINGLE_INSTANCE
   if ( sgMutexRunning )
   {
      ReleaseMutex( sgMutexRunning );
	  sgMutexRunning = NULL;
   }
#endif
   
   Event kill(etDestroyHandler);
   sgSDLFrame->ProcessEvent(kill);
   SDL_Quit();
}

bool SetClipboardText(const char* text)
{
   return SDL_SetClipboardText(text);
}

bool HasClipboardText()
{
    return SDL_HasClipboardText();
}

const char *GetClipboardText()
{
   const char *clipboardText = SDL_GetClipboardText();
   #ifdef HX_WINDOWS
   if (clipboardText)
   {
      int origLen = strlen(clipboardText);
      const unsigned char *ptr = (const unsigned char *)clipboardText;
      const unsigned char *end = ptr + origLen;
      int bufferSize = 0;
      while(ptr<end)
      {
         const unsigned char *charStart = ptr;
         int code = DecodeAdvanceUTF8(ptr);
         if (code!='\r')
            bufferSize += ptr-charStart;
      }

      if (bufferSize<origLen)
      {
         static std::vector<unsigned char> utf8Buffer;

         utf8Buffer.resize(bufferSize + 1);
         ptr = (const unsigned char *)clipboardText;
         int bufferPos = 0;
         while(ptr<end)
         {
            const unsigned char *charStart = ptr;
            int code = DecodeAdvanceUTF8(ptr);
            if (code!='\r')
               while(charStart<ptr)
                  utf8Buffer[bufferPos++] = *charStart++;
         }
         utf8Buffer[bufferPos] = '\0';
         clipboardText = (const char *)&utf8Buffer[0];
      }
   }
   #endif

   return clipboardText;
}

}
