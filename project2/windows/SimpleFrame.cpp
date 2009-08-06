#include <Graphics.h>
#include <windows.h>
#include <map>


// --- DIB   ------------------------------------------------------------------------

typedef std::map<HWND,class WindowsFrame *> FrameMap;
static FrameMap sgFrameMap;

class DIBSurface : public SimpleSurface
{
public:
   DIBSurface(int inW,int inH) : SimpleSurface(inW,inH,pfXBGR,4)
	{
		memset(&mInfo,0,sizeof(mInfo));
		BITMAPINFOHEADER &h = mInfo.bmiHeader;
		h.biSize = sizeof(BITMAPINFOHEADER);
		h.biWidth = mWidth;
		h.biHeight = mHeight;
		h.biPlanes = 1;
		h.biBitCount = 32;
		h.biCompression = BI_RGB;
	}

	void RenderTo(HDC inDC)
	{
      SetDIBitsToDevice(inDC,0,0,mWidth,mHeight,
								0,0,0,mHeight, mBase, &mInfo, DIB_RGB_COLORS);
	}

   BITMAPINFO mInfo;
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
      mHandler = 0;
      mHandlerData = 0;
      mFlags = inFlags;
		mBMP = 0;
		CreateBMP();
   }
	~WindowsStage()
	{
		delete mBMP;
		delete mSurfaceRenderTarget;
	}

	void CreateBMP()
	{
		if (mBMP)
		{
			delete mBMP;
			mBMP = 0;
		}

		WINDOWINFO info;
      info.cbSize = sizeof(WINDOWINFO);

      if (GetWindowInfo(mHWND,&info))
		{
			int w =  info.rcClient.right - info.rcClient.left;
			int h =  info.rcClient.bottom - info.rcClient.top;
			mBMP = new DIBSurface(w,h);
		}

		if (mSurfaceRenderTarget)
		{
			delete mSurfaceRenderTarget;
			mSurfaceRenderTarget = 0;
		}
	}

   void Flip()
   {
      if (mBMP)
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

	IRenderTarget *GetRenderTarget()
	{
		if (!mSurfaceRenderTarget && mBMP)
			mSurfaceRenderTarget = CreateSurfaceRenderTarget(mBMP);
		return mSurfaceRenderTarget;
	}

   void HandleEvent(Event &inEvent)
   {
		switch(inEvent.mType)
		{
			case etRedraw:
				Flip();
				break;
			case etResize:
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

   void ViewPort(int inOX,int inOY, int inW,int inH)
   {
   }
   void BeginRender()
   {
   }
   void Render(DisplayList &inDisplayList, const Transform &inTransform)
   {
   }
   void Render(TextList &inTextList, const Transform &inTransform)
   {
   }
   void Blit(BlitData &inBitmap, int inOX, int inOY, double inScale, int Rotation)
   {
   }
   void EndRender()
   {
   }


   HWND         mHWND;
	HDC          mDC;
   uint32       mFlags;
	int          mFrameRate;
   EventHandler mHandler;
	DIBSurface   *mBMP;
	IRenderTarget *mSurfaceRenderTarget;
   void         *mHandlerData;
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
		SetTimer(mHandle,timerFrame, 40,0);
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

Frame *CreateMainFrame(int inWidth,int inHeight,unsigned int inFlags, String inTitle)
{
   Rect r(100,100,inWidth,inHeight);

   WNDCLASSEX wc;
   memset(&wc,0,sizeof(wc));
   wc.cbSize = sizeof(wc);
   wc.style = CS_OWNDC | CS_DBLCLKS | CS_HREDRAW | CS_VREDRAW;
   wc.hbrBackground = 0; //(HBRUSH)GetStockObject(WHITE_BRUSH);
   wc.lpfnWndProc =  DefWindowProc;
   wc.lpszClassName = "NME";

   RegisterClassEx(&wc);

   DWORD ex_style = WS_EX_ACCEPTFILES;
   DWORD style = 0;
   if (inFlags & wfResizable)
      style |= WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_MAXIMIZEBOX;
   if (inFlags & wfBorderless)
      style |= WS_POPUP;
   else
      style |= WS_OVERLAPPEDWINDOW;

   HWND win = CreateWindowEx(ex_style, "NME", inTitle,
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

