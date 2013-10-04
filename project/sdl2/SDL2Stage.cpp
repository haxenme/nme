#include <Display.h>
#include <Utils.h>
#include <SDL.h>
#include <Surface.h>
#include <ExternalInterface.h>
#include <KeyCodes.h>
#include <map>

#ifdef NME_MIXER
#include <SDL_mixer.h>
#endif


namespace nme
{
	

static int sgDesktopWidth = 0;
static int sgDesktopHeight = 0;
static Rect sgWindowRect = Rect(0, 0, 0, 0);
static bool sgInitCalled = false;
static bool sgJoystickEnabled = false;
static int  sgShaderFlags = 0;
static bool sgIsOGL2 = false;

enum { NO_TOUCH = -1 };


int InitSDL()
{	
	if (sgInitCalled)
		return 0;
		
	sgInitCalled = true;
	
	int err = SDL_Init(SDL_INIT_VIDEO /*| SDL_INIT_AUDIO*/ | SDL_INIT_TIMER);
	
	if (err == 0 && SDL_InitSubSystem (SDL_INIT_JOYSTICK) == 0)
	{
		sgJoystickEnabled = true;
	}
	
	return err;
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
		#ifdef EMSCRIPTEN
		uint8 swap = 0;
		#else
		uint8 swap = mSurf->format->Bshift; // is 0 on argb
		#endif
		if (mSurf->format->Amask)
			return swap ? pfARGBSwap : pfARGB;
		return swap ? pfXRGBSwap : pfXRGB;
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
			 const Rect &inSrcRect, const DRect &inDestRect) const
	{
	}

	SDL_Surface *mSurf;
	bool  mDelete;
	bool  mLockedForHitTest;
};


SDL_Surface *SurfaceToSDL(Surface *inSurface)
{
	int swap =  (gC0IsRed!=(bool)(inSurface->Format()&pfSwapRB)) ? 0xff00ff : 0;
	return SDL_CreateRGBSurfaceFrom((void *)inSurface->Row(0),
				 inSurface->Width(), inSurface->Height(),
				 32, inSurface->Width()*4,
				 0x00ff0000^swap, 0x0000ff00,
				 0x000000ff^swap, 0xff000000 );
}

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
		
		mIsFullscreen = (mWindowFlags & SDL_WINDOW_FULLSCREEN || mWindowFlags & SDL_WINDOW_FULLSCREEN_DESKTOP);
		if (mIsFullscreen)
			displayState = sdsFullscreenInteractive;
		
		if (mIsOpenGL)
		{
			mOpenGLContext = HardwareContext::CreateOpenGL(0, 0, sgIsOGL2);
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
		if (mIsFullscreen)
		{
			SDL_DisplayMode mode;
			SDL_GetCurrentDisplayMode(0, &mode);
			
			mode.w = inWidth;
			mode.h = inHeight;
			
			SDL_SetWindowDisplayMode(mSDLWindow, &mode);
		}
		else
		{
			SDL_SetWindowSize(mSDLWindow, inWidth, inHeight);
		}
	}
	
	
	void SetFullscreen(bool inFullscreen)
	{
		if (inFullscreen != mIsFullscreen)
		{
			mIsFullscreen = inFullscreen;
			
			if (mIsFullscreen)
			{
				SDL_GetWindowPosition(mSDLWindow, &sgWindowRect.x, &sgWindowRect.y);
				SDL_GetWindowSize(mSDLWindow, &sgWindowRect.w, &sgWindowRect.h);
				
				//SDL_SetWindowSize(mSDLWindow, sgDesktopWidth, sgDesktopHeight);
				
				SDL_DisplayMode mode;
				SDL_GetCurrentDisplayMode(0, &mode);
				mode.w = sgDesktopWidth;
				mode.h = sgDesktopHeight;
				SDL_SetWindowDisplayMode(mSDLWindow, &mode);
				
				SDL_SetWindowFullscreen(mSDLWindow, SDL_WINDOW_FULLSCREEN /*SDL_WINDOW_FULLSCREEN_DESKTOP*/);
			}
			else
			{
				SDL_SetWindowFullscreen(mSDLWindow, 0);
				if (sgWindowRect.w && sgWindowRect.h)
				{
					SDL_SetWindowSize(mSDLWindow, sgWindowRect.w, sgWindowRect.h);
				}
				#ifndef HX_LINUX
				SDL_SetWindowPosition(mSDLWindow, sgWindowRect.x, sgWindowRect.y);
				#endif
			}
		}
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
			#ifdef RASPBERRYPI
			nmeEGLSwapBuffers();
			#else
			SDL_RenderPresent(mSDLRenderer);
			#endif
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
				sTextCursor = CreateCursor(sTextCursorData,2,13);
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
           SDL_SetRelativeMouseMode( inLock ? SDL_FALSE : SDL_TRUE );
        }
    }
   
      //Note that this fires a mouse event, see the SDL_WarpMouseInWindow docs
    void SetCursorPositionInWindow(int inX, int inY) 
    {
		SDL_WarpMouseInWindow( mSDLWindow, inX, inY );
    }	
	
	
	void EnablePopupKeyboard(bool enabled)
	{
		
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
	
	
	bool mMultiTouch;
	int  mSingleTouchID;
  
	double mDX;
	double mDY;

	double mDownX;
	double mDownY;
	
	
	Surface *GetPrimarySurface()
	{
		return mPrimarySurface;
	}
	
	
	HardwareContext *mOpenGLContext;
	SDL_Window *mSDLWindow;
	SDL_Renderer *mSDLRenderer;
	Surface	  *mPrimarySurface;
	SDL_Surface *mSoftwareSurface;
	SDL_Texture *mSoftwareTexture;
	double		 mFrameRate;
	bool			mIsOpenGL;
	Cursor		 mCurrentCursor;
	bool			mShowCursor;
	bool         	mLockCursor;	
	bool			mIsFullscreen;
	unsigned int mWindowFlags;
	int			 mWidth;
	int			 mHeight;
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
	
	
	void SetTitle()
	{
		
	}
	
	
	void SetIcon()
	{
		
	}
	
	
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
SDL_Joystick *sgJoystick = 0;
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
	if (inKey>=keyA && inKey<=keyZ)
		return inKey;
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
		
		SDL_TRANS(BACKQUOTE)
		SDL_TRANS(BACKSLASH)
		SDL_TRANS(BACKSPACE)
		SDL_TRANS(COMMA)
		SDL_TRANS(DELETE)
		SDL_TRANS(DOWN)
		SDL_TRANS(END)
		SDL_TRANS(ESCAPE)
		SDL_TRANS(HOME)
		SDL_TRANS(INSERT)
		SDL_TRANS(LEFT)
		SDL_TRANS(LEFTBRACKET)
		SDL_TRANS(MINUS)
		SDL_TRANS(PERIOD)
		SDL_TRANS(QUOTE)
		SDL_TRANS(RIGHT)
		SDL_TRANS(RIGHTBRACKET)
		SDL_TRANS(SEMICOLON)
		SDL_TRANS(SLASH)
		SDL_TRANS(SPACE)
		SDL_TRANS(TAB)
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


std::map<int,wchar_t> sLastUnicode;


void ProcessEvent(SDL_Event &inEvent)
{
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
				//case SDL_WINDOWEVENT_MINIMIZED: break;
				//case SDL_WINDOWEVENT_MAXIMIZED: break;
				//case SDL_WINDOWEVENT_RESTORED: break;
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
				default: break;
			}
		}
		case SDL_MOUSEMOTION:
		{
			Event mouse(etMouseMove, inEvent.motion.x, inEvent.motion.y);
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
				//previous behavior in nme was 3 for down, 4 for up
			int event_dir = (inEvent.wheel.y > 0) ? 3 : 4;
				//space to get the current mouse position, to make sure the values are sane
			int _x = 0; 
			int _y = 0;
				//fetch the mouse position
			SDL_GetMouseState(&_x,&_y);
				//create the event
			Event mouse(etMouseUp, _x, _y, event_dir);
				//add flags for modifier keys
			AddModStates(mouse.flags);
				//and done.
			sgSDLFrame->ProcessEvent(mouse);
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
			key.code = 0;
			
			AddModStates(key.flags, inEvent.key.keysym.mod);
			if (right)
				key.flags |= efLocationRight;
			sgSDLFrame->ProcessEvent(key);
			break;
		}
		case SDL_JOYAXISMOTION:
		{
			Event joystick(etJoyAxisMove);
			joystick.id = inEvent.jaxis.which;
			joystick.code = inEvent.jaxis.axis;
			joystick.value = inEvent.jaxis.value;
			sgSDLFrame->ProcessEvent(joystick);
			break;
		}
		case SDL_JOYBALLMOTION:
		{
			Event joystick(etJoyBallMove, inEvent.jball.xrel, inEvent.jball.yrel);
			joystick.id = inEvent.jball.which;
			joystick.code = inEvent.jball.ball;
			sgSDLFrame->ProcessEvent(joystick);
			break;
		}
		case SDL_JOYBUTTONDOWN:
		{
			Event joystick(etJoyButtonDown);
			joystick.id = inEvent.jbutton.which;
			joystick.code = inEvent.jbutton.button;
			sgSDLFrame->ProcessEvent(joystick);
			break;
		}
		case SDL_JOYBUTTONUP:
		{
			Event joystick(etJoyButtonUp);
			joystick.id = inEvent.jbutton.which;
			joystick.code = inEvent.jbutton.button;
			sgSDLFrame->ProcessEvent(joystick);
			break;
		}
		case SDL_JOYHATMOTION:
		{
			Event joystick(etJoyHatMove);
			joystick.id = inEvent.jhat.which;
			joystick.code = inEvent.jhat.hat;
			joystick.value = inEvent.jhat.value;
			sgSDLFrame->ProcessEvent(joystick);
			break;
		}
	}
};


void CreateMainFrame(FrameCreationCallback inOnFrame, int inWidth, int inHeight, unsigned int inFlags, const char *inTitle, Surface *inIcon)
{
	bool fullscreen = (inFlags & wfFullScreen) != 0;
	bool opengl = (inFlags & wfHardware) != 0;
	bool resizable = (inFlags & wfResizable) != 0;
	bool borderless = (inFlags & wfBorderless) != 0;
	bool vsync = (inFlags & wfVSync) != 0;
	
	sgShaderFlags = (inFlags & (wfAllowShaders|wfRequireShaders) );

	//Rect r(100,100,inWidth,inHeight);
	
	int err = InitSDL();
	if (err == -1)
	{
		fprintf(stderr,"Could not initialize SDL : %s\n", SDL_GetError());
		inOnFrame(0);
	}
	
	//SDL_EnableUNICODE(1);
	//SDL_EnableKeyRepeat(500,30);
	//gSDLIsInit = true;

	#ifdef NME_MIXER
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
		//gSDLIsInit = false;
	}
	#endif
	
	if (SDL_GetNumVideoDisplays() > 0)
	{
		SDL_DisplayMode currentMode;
		SDL_GetDesktopDisplayMode(0, &currentMode);
		sgDesktopWidth = currentMode.w;
		sgDesktopHeight = currentMode.h;
	}
	
	int windowFlags = 0;
	
	if (opengl) windowFlags |= SDL_WINDOW_OPENGL;
	if (resizable) windowFlags |= SDL_WINDOW_RESIZABLE;
	if (borderless) windowFlags |= SDL_WINDOW_BORDERLESS;
	if (fullscreen) windowFlags |= SDL_WINDOW_FULLSCREEN; //SDL_WINDOW_FULLSCREEN_DESKTOP;
	
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
	
	#ifdef HX_LINUX
	int setWidth = inWidth;
	int setHeight = inHeight;
	#else
	int setWidth = fullscreen ? sgDesktopWidth : inWidth;
	int setHeight = fullscreen ? sgDesktopHeight : inHeight;
	#endif
	
	SDL_Window *window = SDL_CreateWindow (inTitle, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, setWidth, setHeight, windowFlags);
	
	if (!window) return;
	windowFlags = SDL_GetWindowFlags (window);
	
	if (fullscreen) {
		
		sgWindowRect = Rect(SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, inWidth, inHeight);
		
	}
	
	int renderFlags = 0;
	
	if (opengl) renderFlags |= SDL_RENDERER_ACCELERATED;
	if (vsync) renderFlags |= SDL_RENDERER_PRESENTVSYNC;
	
	SDL_Renderer *renderer = SDL_CreateRenderer (window, -1, renderFlags);
	
	if (!renderer && opengl) {
		
		opengl = false;
		renderFlags &= ~SDL_RENDERER_ACCELERATED;
		
		renderer = SDL_CreateRenderer (window, -1, renderFlags);
		
	}
	
	if (!renderer) return;
	
	if (opengl) {
		
		sgIsOGL2 = (inFlags & (wfAllowShaders | wfRequireShaders));
		
	}
	
	
/*#if defined(IPHONE) || defined(BLACKBERRY) || defined(EMSCRIPTEN)
	sdl_flags |= SDL_NOFRAME;
#else
	if (inIcon)
	{
		SDL_Surface *sdl = SurfaceToSDL(inIcon);
		SDL_WM_SetIcon( sdl, NULL );
	}
#endif


	#if defined (HX_WINDOWS) || defined (HX_LINUX)
	//SDL_WM_SetCaption( inTitle, 0 );
	#endif

	SDL_Surface* screen = 0;
	bool is_opengl = false;
	sgIsOGL2 = false;

	#ifdef RASPBERRYPI
	bool nmeEgl = true;
	#else
	bool nmeEgl = false;
	#endif

	if (opengl && !nmeEgl)
	{
		int  aa_tries = (inFlags & wfHW_AA) ? ( (inFlags & wfHW_AA_HIRES) ? 2 : 1 ) : 0;
	
		//int bpp = info->vfmt->BitsPerPixel;
		int startingPass = 0;

		// Try for 24:8  depth:stencil
		if (inFlags & wfStencilBuffer)
			startingPass = 1;
 
		#if defined (WEBOS) || defined (BLACKBERRY) || defined(EMSCRIPTEN)
		// Start at 16 bits...
		startingPass = 2;
		#endif

		// No need to loop over depth
		if (!(inFlags & wfDepthBuffer))
			startingPass = 2;

		int oglLevelPasses = 1;

		#if !defined(NME_FORCE_GLES1) && (defined(WEBOS) || defined(BLACKBERRY) || defined(EMSCRIPTEN))
		// Try 2 then 1 ?
		if ( (inFlags & wfAllowShaders) && !(inFlags & wfRequireShaders) )
			oglLevelPasses = 2;
		#endif

		// Find config...

		for(int oglPass = 0; oglPass< oglLevelPasses && !is_opengl; oglPass++)
		{
			#ifdef NME_FORCE_GLES1
			int level = 1;
			#else
			int level = (inFlags & wfRequireShaders) ? 2 : (inFlags & wfAllowShaders) ? 2-oglPass : 1;
			#endif
		  
	
			for(int depthPass=startingPass;depthPass<3 && !is_opengl;depthPass++)
			{
				// Initialize the display
				for(int aa_pass = aa_tries; aa_pass>=0 && !is_opengl; --aa_pass)
				{
					SDL_GL_SetAttribute(SDL_GL_RED_SIZE,  8 );
					SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE,8 );
					SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8 );
	
					#if defined(WEBOS) || defined(BLACKBERRY) || defined(EMSCRIPTEN)
					SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, level);
					#endif
					// try 32 24 or 16 bit depth...
					if (inFlags & wfDepthBuffer)
						SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE,  32 - depthPass*8 );
	
					if (inFlags & wfStencilBuffer)
						SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8 );
	
					SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
				
					if (aa_tries > 0)
					{
						SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, aa_pass>0);
						SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES,  1<<aa_pass );
					}
					
					#ifndef EMSCRIPTEN
					if ( inFlags & wfVSync )
					{
						SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, 1);
					}
					#endif
	
					sdl_flags |= SDL_OPENGL;
				
					//if (!(screen = SDL_SetVideoMode( use_w, use_h, 32, sdl_flags)))
					if (!(screen = SDL_CreateWindow(inTitle, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, use_w, use_h, sdl_flags)))
					{
						if (depthPass==2 && aa_pass==0 && oglPass==oglLevelPasses-1)
						{
							sdl_flags &= ~SDL_OPENGL;
							fprintf(stderr, "Couldn't set OpenGL mode32: %s\n", SDL_GetError());
						}
					}
					else
					{
						is_opengl = true;
						#if defined(WEBOS) || defined(BLACKBERRY) || defined(EMSCRIPTEN)
						sgIsOGL2 = level==2;
						#else
						// TODO: check extensions support
						sgIsOGL2 = (inFlags & (wfAllowShaders | wfRequireShaders) );
						#endif
						break;
					}
				}
			}
		}
	}
 
	if (!screen)
	{
		if (!opengl || !nmeEgl)
			sdl_flags |= SDL_DOUBLEBUF;

		//screen = SDL_SetVideoMode( use_w, use_h, 32, sdl_flags );
		screen = SDL_CreateWindow(inTitle, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, use_w, use_h, sdl_flags);
		if (!screen)
		{
			fprintf(stderr, "Couldn't set video mode: %s\n", SDL_GetError());
			inOnFrame(0);
			gSDLIsInit = false;
			return;
		}
	}

	#ifdef RASPBERRYPI
	if (opengl)
	{
		sgIsOGL2 = (inFlags & (wfAllowShaders | wfRequireShaders) );
			
		use_w = screen->w;
		use_h = screen->h;
		bool ok = nmeEGLCreate( 0, use_w, use_h,
								sgIsOGL2,
								(inFlags & wfDepthBuffer) ? 16 : 0,
								(inFlags & wfStencilBuffer) ? 8 : 0,
								0 );
		if (ok)
			is_opengl = true;
	}
	#endif
	
	HintColourOrder( is_opengl || screen->format->Rmask==0xff );
*/
	
	int numJoysticks = SDL_NumJoysticks();
	
	if (sgJoystickEnabled && numJoysticks > 0)
	{
		for (int i = 0; i < numJoysticks; i++)
		{
			sgJoystick = SDL_JoystickOpen(i);
		}
		SDL_JoystickEventState(SDL_TRUE);
	}
	
	int width, height;
	if (windowFlags & SDL_WINDOW_FULLSCREEN || windowFlags & SDL_WINDOW_FULLSCREEN_DESKTOP)
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
	inOnFrame(sgSDLFrame);
	StartAnimation();
}


bool sgDead = false;


void SetIcon(const char *path)
{
	
}


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
	Mix_CloseAudio();
	#endif
	sgDead = true;
}


static SDL_TimerID sgTimerID = 0;
bool sgTimerActive = false;


Uint32 OnTimer(Uint32 interval, void *)
{
	// Ping off an event - any event will force the frame check.
	SDL_Event event;
	SDL_UserEvent userevent;
	/* In this example, our callback pushes an SDL_USEREVENT event
	into the queue, and causes ourself to be called again at the
	same interval: */
	userevent.type = SDL_USEREVENT;
	userevent.code = 0;
	userevent.data1 = NULL;
	userevent.data2 = NULL;
	event.type = SDL_USEREVENT;
	event.user = userevent;
	sgTimerActive = false;
	sgTimerID = 0;
	SDL_PushEvent(&event);
	return 0;
}


#ifndef SDL_NOEVENT
#define SDL_NOEVENT -1;
#endif


void StartAnimation()
{
	SDL_Event event;
	bool firstTime = true;
	while(!sgDead)
	{
		event.type = SDL_NOEVENT;
		while (!sgDead && (firstTime || SDL_WaitEvent(&event)))
		{
			firstTime = false;
			if (sgTimerActive && sgTimerID)
			{
				SDL_RemoveTimer(sgTimerID);
				sgTimerActive = false;
				sgTimerID = 0;
			}
			
			ProcessEvent(event);
			if (sgDead) break;
			event.type = SDL_NOEVENT;
			
			while (SDL_PollEvent(&event))
			{
				ProcessEvent (event);
				if (sgDead) break;
				event.type = -1;
			}
			
			Event poll(etPoll);
			sgSDLFrame->ProcessEvent(poll);
			
			if (sgDead) break;
			
			double next = sgSDLFrame->GetStage()->GetNextWake() - GetTimeStamp();
			
			if (next > 0.001)
			{
				int snooze = next*1000.0;
				sgTimerActive = true;
				sgTimerID = SDL_AddTimer(snooze, OnTimer, 0);
			}
			else
			{
				OnTimer(0, 0);
			}
		}
	}
	
	Event deactivate(etDeactivate);
	sgSDLFrame->ProcessEvent(deactivate);
	
	Event kill(etDestroyHandler);
	sgSDLFrame->ProcessEvent(kill);
	SDL_Quit();
}


}
