#include <Graphics.h>
#include <Display.h>
#include <Surface.h>
#include <windows.h>
#include <map>

#include <gl/GL.h>

// --- DIB   ------------------------------------------------------------------------

typedef std::map<HWND,class WindowsFrame *> FrameMap;
static FrameMap sgFrameMap;

class DIBSurface : public SimpleSurface
{
public:
   DIBSurface(int inW,int inH) : SimpleSurface( (inW+3) & ~3 ,inH,pfXRGB,4)
   {
      memset(&mInfo,0,sizeof(mInfo));
      BITMAPINFOHEADER &h = mInfo.bmiHeader;
      h.biSize = sizeof(BITMAPINFOHEADER);
      h.biWidth = mWidth;
      h.biHeight = -mHeight;
      h.biPlanes = 1;
      h.biBitCount = 32;
      h.biCompression = BI_RGB;

		memset(mBase, 0, mWidth*mHeight*4);
   }

   void RenderTo(HDC inDC)
   {
       SetDIBitsToDevice(inDC,0,0,mWidth,mHeight,
                        0,0, 0,mHeight, mBase, &mInfo, DIB_RGB_COLORS);
   }

   BITMAPINFO mInfo;

private:
	~DIBSurface() { }
};

// --- OGLSurface Interface ---------------------------------------------------------

class OGLSurface : public HardwareSurface
{
public:
   OGLSurface(HDC inDC, HGLRC inOGLCtx)
	{
		mDC = inDC;
		mOGLCtx = inOGLCtx;
		mWidth = 0;
		mHeight = 0;
	}

	void SetSize(int inWidth,int inHeight)
	{
		mWidth = inWidth;
		mHeight = inHeight;
	}

   int Width() const { return mWidth; }
   int Height() const { return mHeight; }
   PixelFormat Format()  const { return pfHardware; }
	const uint8 *GetBase() const { return 0; }
	int GetStride() const { return 0; }

	void Clear(uint32 inColour)
	{
		glViewport(0,0,mWidth,mHeight);
		glClearColor((GLclampf)( ((inColour >>16) & 0xff) /255.0),
                   (GLclampf)( ((inColour >>8 ) & 0xff) /255.0),
                   (GLclampf)( ((inColour     ) & 0xff) /255.0),
                   (GLclampf)1.0 );
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

   RenderTarget BeginRender(const Rect &inRect)
	{
		wglMakeCurrent(mDC,mOGLCtx);
		glMatrixMode(GL_PROJECTION);
      glLoadIdentity();
		glMatrixMode(GL_MODELVIEW);
      glLoadIdentity();
		glViewport(inRect.x, mHeight-inRect.y1(), inRect.w, inRect.h);
		glOrtho(inRect.x,inRect.x1(), inRect.y,inRect.y1(), -1, 1);

		RenderTarget ogl_target;
		ogl_target.mRect = inRect;
		ogl_target.format = pfHardware;
		ogl_target.hardware = this;
		return ogl_target;
	}
   void EndRender()
	{
	}

   void BlitTo(const RenderTarget &outTarget, const Rect &inSrcRect,int inPosX, int inPosY,
							  BlendMode inBlend, const BitmapCache *inMask,
                       uint32 inTint )
	{
		// Should not get here...
	}

	HDC mDC;
	HGLRC mOGLCtx;
	int mWidth,mHeight;
};

// --- Stage ------------------------------------------------------------------------

enum
{
   timerFrame,
};

class WindowsStage : public Stage
{
public:
   WindowsStage(HWND inHWND,uint32 inFlags)
   {
      mHWND = inHWND;
      mDC = GetDC(mHWND);
		SetICMMode(mDC,ICM_OFF);
      mHandler = 0;
      mHandlerData = 0;
      mFlags = inFlags;
      mBMP = 0;
		mOGLSurface = 0;
		mOGLCtx = 0;
		HintColourOrder(false);

		mIsHardware = inFlags & wfHardware;

		if (mIsHardware)
		{
			if (!CreateHardware())
				mIsHardware = false;
		}
		if (!mIsHardware)
         CreateBMP();
   }

   ~WindowsStage()
   {
		if (mBMP)
			mBMP->DecRef();
		if (mOGLSurface)
			mOGLSurface->DecRef();
		if (mOGLCtx)
			wglDeleteContext( mOGLCtx );
   }

	bool CreateHardware()
	{
		PIXELFORMATDESCRIPTOR pfd;
		ZeroMemory( &pfd, sizeof( pfd ) );
		pfd.nSize = sizeof( pfd );
		pfd.nVersion = 1;
		pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL |
						  PFD_DOUBLEBUFFER;
		pfd.iPixelType = PFD_TYPE_RGBA;
		pfd.cColorBits = 24;
		pfd.cDepthBits = 16;
		pfd.iLayerType = PFD_MAIN_PLANE;
		int fmt = ChoosePixelFormat( mDC, &pfd );
		if (!fmt)
			return false;
		if (!SetPixelFormat( mDC, fmt, &pfd ))
			return false;

      mOGLCtx = wglCreateContext( mDC );
		if (!mOGLCtx)
			return false;

		mOGLSurface = new OGLSurface(mDC, mOGLCtx);
		mOGLSurface->IncRef();
		UpdateOGL();
		return true;
	}


   void UpdateOGL()
	{
		WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (GetWindowInfo(mHWND,&info))
      {
         int w =  info.rcClient.right - info.rcClient.left;
         int h =  info.rcClient.bottom - info.rcClient.top;
			mOGLSurface->SetSize(w,h);
      }
	}

   void CreateBMP()
   {
      if (mBMP)
      {
         mBMP->DecRef();
         mBMP = 0;
      }

      WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (GetWindowInfo(mHWND,&info))
      {
         int w =  info.rcClient.right - info.rcClient.left;
         int h =  info.rcClient.bottom - info.rcClient.top;
         mBMP = new DIBSurface(w,h);
			mBMP->IncRef();
      }
   }

   void Flip()
   {
		if (mOGLCtx)
			SwapBuffers(mDC);
		else if (mBMP)
         mBMP->RenderTo(mDC);
   }
   void GetMouse()
   {
   }
   virtual void SetEventHandler(EventHandler inHander,void *inUserData)
   {
      mHandler = inHander;
      mHandlerData = inUserData;
   }

   Surface *GetPrimarySurface()
   {
		if (mOGLSurface)
			return mOGLSurface;
      return mBMP;
   }

   void HandleEvent(Event &inEvent)
   {
      switch(inEvent.mType)
      {
         case etRedraw:
            Flip();
            break;
         case etResize:
				if (mOGLSurface)
					UpdateOGL();
				else
               CreateBMP();
            break;
         case etTimer:
            if (inEvent.mValue==timerFrame)
            {
               FrameCheck();
               return;
            }
            break;
      }

      if (mHandler)
         mHandler(inEvent,mHandlerData);
   }

   void FrameCheck()
   {
      if (mHandler)
      {
         Event evt(etNextFrame);
         mHandler(evt,mHandlerData);
      }
   }

   // --- IRenderTarget Interface ------------------------------------------
   int Width()
   {
      WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (!GetWindowInfo(mHWND,&info))
         return 0;
      return info.rcClient.right - info.rcClient.left;
   }

   int Height()
   {
      WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (!GetWindowInfo(mHWND,&info))
         return 0;

      return info.rcClient.bottom - info.rcClient.top;
   }


   HWND         mHWND;
   HDC          mDC;
	HGLRC        mOGLCtx;
   uint32       mFlags;
   double       mFrameRate;
   EventHandler mHandler;
   DIBSurface   *mBMP;
	OGLSurface   *mOGLSurface;
   void         *mHandlerData;
	bool         mIsHardware;
};


// --- Frame ------------------------------------------------------------------------


class WindowsFrame : public Frame
{
public:
   WindowsFrame(HWND inHandle, uint32 inFlags)
   {
      mFlags = inFlags;
      mHandle = inHandle;
      sgFrameMap[mHandle] = this;
      mStage = new WindowsStage(inHandle,mFlags);
      mOldProc = (WNDPROC)SetWindowLongPtr(mHandle,GWL_WNDPROC,(LONG)StaticCallback);
      ShowWindow(mHandle,true);
      SetTimer(mHandle,timerFrame, 10,0);
   }
   ~WindowsFrame()
   {
      SetWindowLongPtr(mHandle,GWL_WNDPROC,(LONG)mOldProc);
      sgFrameMap.erase(mHandle);
   }

   LRESULT Callback(UINT uMsg, WPARAM wParam, LPARAM lParam)
   {
      switch (uMsg)
      {
         case WM_CLOSE:
            TerminateMainLoop();
            break;
         case WM_PAINT:
            {
            PAINTSTRUCT ps;
            HDC dc;
            BeginPaint(mHandle,&ps);
            Event evt(etRedraw);
            mStage->HandleEvent(evt);
            EndPaint(mHandle,&ps);
            }
            break;
         case WM_SIZE:
            {
            Event evt(etResize);
            mStage->HandleEvent(evt);
            }
            break;
         case WM_TIMER:
            {
            Event evt(etTimer);
            evt.mValue = wParam;
            mStage->HandleEvent(evt);
            }
            break;
      }

      return mOldProc(mHandle, uMsg, wParam, lParam);
   }

   static LRESULT CALLBACK StaticCallback( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
   {
      FrameMap::iterator i = sgFrameMap.find(hwnd);
      if (i!=sgFrameMap.end())
         return i->second->Callback(uMsg,wParam,lParam);
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
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


   WindowsStage *mStage;

   uint32 mFlags;
   HWND mHandle;
   WNDPROC mOldProc;
};


// --- When using the simple window class -----------------------------------------------

Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, wchar_t *inTitle)
{
   Rect r(100,100,inWidth,inHeight);

   WNDCLASSEXW wc;
   memset(&wc,0,sizeof(wc));
   wc.cbSize = sizeof(wc);
   wc.style = CS_OWNDC | CS_DBLCLKS | CS_HREDRAW | CS_VREDRAW;
   wc.hbrBackground = 0; //(HBRUSH)GetStockObject(WHITE_BRUSH);
   wc.lpfnWndProc =  DefWindowProc;
   wc.lpszClassName = L"NME";

   RegisterClassExW(&wc);

   DWORD ex_style = WS_EX_ACCEPTFILES;
   DWORD style = 0;
   if (inFlags & wfResizable)
      style |= WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_MAXIMIZEBOX;
   if (inFlags & wfBorderless)
      style |= WS_POPUP;
   else
      style |= WS_OVERLAPPEDWINDOW;

   HWND win = CreateWindowExW(ex_style, L"NME", inTitle,
                              style,
                              r.x, r.y, r.w, r.h,
                              0,
                              0,
                              0,
                              0);

   Frame *frame = new WindowsFrame(win,inFlags);
   SetCursor(LoadCursor(0, IDC_ARROW));
   return frame;
}


bool sgDead = false;

void TerminateMainLoop()
{
   sgDead =true;
}

void MainLoop()
{
   MSG msg;
   while( !sgDead && (GetMessage(&msg, NULL, 0, 0) > 0) )
   {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
   }
}

