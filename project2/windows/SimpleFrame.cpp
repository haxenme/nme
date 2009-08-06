#include <Graphics.h>
#include <windows.h>
#include <map>


typedef std::map<HWND,class WindowsFrame *> FrameMap;
static FrameMap sgFrameMap;

class DIBSurface : public Surface
{


};


class WindowsStage : public Stage
{
public:
   WindowsStage(HWND inHWND,uint32 inFlags)
   {
      mHWND = inHWND;
      mHandler = 0;
      mHandlerData = 0;
      mFlags = inFlags;
   }

   void Flip()
   {
   }
   void GetMouse()
   {
   }
   virtual void SetEventHandler(EventHandler inHander,void *inUserData)
   {
      mHandler = inHander;
      mHandlerData = inUserData;
   }

   void HandleEvent(Event &inEvent)
   {
      if (mHandler)
         mHandler(inEvent,mHandlerData);
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
   uint32       mFlags;
   EventHandler mHandler;
   void         *mHandlerData;
};


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
   wc.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
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

