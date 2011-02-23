#include <Display.h>
#include <Utils.h>
#include <Surface.h>
#include <ExternalInterface.h>
#include <KeyCodes.h>
#include <map>

#define _CAANOO_

#include <DGE_Type.h>
#include <DGE_System.h>
#include <DGE_Time.h>
#include <DGE_Math.h>
#include <DGE_Base.h>
#include <DGX_Font.h>
#include <DGX_Media.h>
#include <DGX_Sound.h>
#include <DGX_Input.h>


namespace nme
{

void MainLoop();

static int sgDesktopWidth = 320;
static int sgDesktopHeight = 240;
static bool sgDead = false;

/*
DGE_Cursor *CreateCursor(const char *image[],int inHotX,int inHotY)
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
  return DGE_CreateCursor(data, mask, 32, 32, inHotX, inHotY);
}

DGE_Cursor *sDefaultCursor = 0;
DGE_Cursor *sTextCursor = 0;

*/


class DGESurface : public HardwareSurface
{
	PDGE_DEVICE mDevice;
public:
	DGESurface(PDGE_DEVICE inDevice, HardwareContext *inContext)
		 : HardwareSurface(inContext )
	{
		mDevice = inDevice;
	}

   RenderTarget BeginRender(const Rect &inRect)
   {
		mDevice->BeginScene();
		return HardwareSurface::BeginRender(inRect);
   }
   void EndRender()
	{
		HardwareSurface::EndRender();
		mDevice->EndScene();
	}

};


enum
{
	virLEFT,
	virRIGHT,
	virUP,
	virDOWN,

	virA,
	virB,
	virY,
	virX,

	virESCAPE,
	virSPACE,
	virENTER,

	virLEFT_SHIFT,
	virRIGHT_SHIFT,

	virPAGE_UP,
	virPAGE_DOWN,
	virHOME,
	virEND,

	virSIZE,
};

static int sNMEKey[] =
{
	keyLEFT,
	keyRIGHT,
	keyUP,
	keyDOWN,

	keyA,
	keyB,
	keyY,
	keyX,

	keyESCAPE,
	keySPACE,
	keyENTER,

	keySHIFT,
	keySHIFT,

	keyPAGE_UP,
	keyPAGE_DOWN,
	keyHOME,
	keyEND,

};

static int sUnicodeKey[] =
{
	0,
	0,
	0,
	0,

	'A',
	'B',
	'Y',
	'X',

	27,
	' ',
	'\n',

	0,
	0,

	0,
	0,
	0,
	0,

};





int GetNMEKey(int i)
{
	return sNMEKey[i];
}

int GetUniCode(int i)
{
	return sUnicodeKey[i];
}


class DGEStage : public Stage
{
	DGE_HANDLE m_hWnd;
	PDGE_DEVICE m_pDev;
	PDGX_INPUT m_pInput;
	bool     mWasDown[virSIZE];
	double   mNextAutoKey;

public:
   DGEStage(DGE_HANDLE inHWND,int inWidth, int inHeight,uint32 inFlags)
   {
		m_hWnd = inHWND;
      mWidth = inWidth;
      mHeight = inHeight;
      mFlags = inFlags;
		mNextAutoKey = 0;
		mPrevDown = 0;
		mPrevPos.x = mPrevPos.y = 0;

		memset(mWasDown,0,sizeof(mWasDown));

      displayState = sdsFullscreenInteractive;

		//printf("Create device...\n");
		// Create DGE Rendering Device
		if(DGE_FAILED(DGE_CreateDevice(NULL, &m_pDev, m_hWnd, NULL)))
		{
			printf("DGE_CreateDevice - fatal error.\n");
			exit(1);
		}

		//printf("Create input...\n");

		// Create Input Device
		if(DGE_FAILED(DGX_CreateInput(NULL, &m_pInput, m_pDev, m_hWnd)))
		{
			printf("DGE_CreateInput - fatal error.\n");
			exit(1);
		}

		//printf("Create ogl stuff...\n");

      mOpenGLContext = HardwareContext::CreateOpenGL(0,0);
      mOpenGLContext->IncRef();
      mOpenGLContext->SetWindowSize(inWidth,inHeight);
      mPrimarySurface = new DGESurface(m_pDev,mOpenGLContext);
      mPrimarySurface->IncRef();
   }

   ~DGEStage()
   {
		//printf("~DGEStage...\n");
      mOpenGLContext->DecRef();
      mPrimarySurface->DecRef();
		//printf("DGE_DestroyInput...\n");
		DGX_DestroyInput(&m_pInput);
		//printf("DGE_DestroyDevice...\n");
		DGE_DestroyDevice(&m_pDev);
   }

   void Resize(int inWidth,int inHeight)
   {
		Event resize(etResize);
		resize.x = 320;
		resize.y = 240;
		HandleEvent(resize);
      mOpenGLContext->SetWindowSize(inWidth,inHeight);
   }

   void SetFullscreen(bool inFullscreen)
   {
		// Ignore
      // Event resize(etResize,w,h);
      // ProcessEvent(resize);
   }



   bool isOpenGL() const { return true; }

   void ProcessEvent(Event &inEvent)
   {
      HandleEvent(inEvent);
   }

	#define DOWN(x) (pKey[x]==DGXINPUT_KEYDOWN || pKey[x]==DGXINPUT_KEYPRESS)

	void PollEvents()
	{
		m_pInput->Update();

	   DGXVECTOR3	vcTsbPos = m_pInput->GetTsbPos();
	   DGE_STATE	nTsbState= m_pInput->TsbState();
	   const BYTE*	pKey = m_pInput->GetKeyMap();
	   const BYTE*	pTsb = m_pInput->GetTsbMap();

		if(pKey[DGXKEY_HOME])
		   return TerminateMainLoop();

		double now = GetTimeStamp();

		bool keys[virSIZE];
		memset(keys,0,sizeof(keys));
		keys[virLEFT] = DOWN(DGXKEY_UP_LEFT) || DOWN(DGXKEY_LEFT) || DOWN(DGXKEY_DOWN_LEFT);
		keys[virRIGHT] = DOWN(DGXKEY_UP_RIGHT) || DOWN(DGXKEY_RIGHT) || DOWN(DGXKEY_DOWN_RIGHT);
		keys[virUP] = DOWN(DGXKEY_UP) || DOWN(DGXKEY_UP_LEFT) || DOWN(DGXKEY_UP_RIGHT);
		keys[virDOWN] = DOWN(DGXKEY_DOWN) || DOWN(DGXKEY_DOWN_LEFT) || DOWN(DGXKEY_DOWN_RIGHT);

		keys[virA] = DOWN(DGXKEY_FA);
		keys[virB] = DOWN(DGXKEY_FB);
		keys[virY] = DOWN(DGXKEY_FY);
		keys[virX] = DOWN(DGXKEY_FX);

		keys[virLEFT_SHIFT] = DOWN(DGXKEY_FL);
		keys[virRIGHT_SHIFT] = DOWN(DGXKEY_FR);

		keys[virESCAPE] = DOWN(DGXKEY_SELECT);
		keys[virSPACE] = DOWN(DGXKEY_START);
		keys[virENTER] = DOWN(DGXKEY_TAT);

		keys[virPAGE_UP] = DOWN(DGXKEY_VOL_UP);
		keys[virPAGE_DOWN] = DOWN(DGXKEY_VOL_DOWN);
		keys[virHOME] = DOWN(DGXKEY_HOME);
		keys[virEND] = DOWN(DGXKEY_HOLD);


		for(int i=0;i<virSIZE;i++)
		{
			bool down = keys[i];
			if (!mWasDown[i] && down || (down && now>mNextAutoKey) )
			{
				Event key(etKeyDown);
				key.value = GetNMEKey(i);
            key.code = GetUniCode(i);
            key.flags = i==virRIGHT_SHIFT ? efLocationRight : 0;
				mNextAutoKey = now+0.200;
				ProcessEvent(key);
			}
			else if (!down && mWasDown[i])
			{
				Event key(etKeyUp);
				key.value = GetNMEKey(i);
            key.code = GetUniCode(i);
            key.flags = i==virRIGHT_SHIFT ? efLocationRight : 0;
				ProcessEvent(key);
			}
			mWasDown[i] = down;
		}

		//printf("Touch: %3.f %3.f %d\n", vcTsbPos.x, vcTsbPos.y, nTsbState);
		if (vcTsbPos.x!=mPrevPos.x || vcTsbPos.y!=mPrevPos.y)
		{
			Event move(etMouseMove,vcTsbPos.x, vcTsbPos.y);
			if (mPrevDown) move.flags = efLeftDown;
			ProcessEvent(move);
		   mPrevPos = vcTsbPos;
		}

		if ((mPrevDown!=0)!=(nTsbState!=0))
		{
			Event mouse(nTsbState ? etMouseDown : etMouseUp ,vcTsbPos.x, vcTsbPos.y);
			if (nTsbState) mouse.flags = efLeftDown;
			ProcessEvent(mouse);
		   mPrevDown = nTsbState;
		}

		Event poll(etPoll);
		HandleEvent(poll);
		// Update Input
	}

   void Flip()
   {
		m_pDev->Present(0,0,0,0);
   }

   void GetMouse()
   {
   }

   void SetCursor(Cursor inCursor)
   {
		/*
      if (sDefaultCursor==0)
         sDefaultCursor = DGE_GetCursor();
   
      if (inCursor==curNone)
         DGE_ShowCursor(false);
      else
      {
         DGE_ShowCursor(true);
   
         if (inCursor==curPointer || inCursor==curHand)
            DGE_SetCursor(sDefaultCursor);
         else
         {
            // TODO: Rotated
            if (sTextCursor==0)
               sTextCursor = CreateCursor(sTextCursorData,1,13);
            DGE_SetCursor(sTextCursor);
         }
      }
		*/
   }
   

   Surface *GetPrimarySurface()
   {
      return mPrimarySurface;
   }


	DGXVECTOR3   mPrevPos;
	int          mPrevDown;

   HardwareContext *mOpenGLContext;
   Surface     *mPrimarySurface;
   double       mFrameRate;
   unsigned int mFlags;
   int          mWidth;
   int          mHeight;
};

static LRESULT DGE_WINAPI	WndProc(DGE_HWND, UINT, WPARAM, LPARAM) { return 	DGE_OK; }

class DGEFrame *sgDGEFrame = 0;

class DGEFrame : public Frame
{
	DGE_HANDLE		m_hWnd;

   DGEStage *mStage;
	uint32 mFlags;

public:
   DGEFrame(const char *inTitle,int inW,int inH,uint32 inFlags)
   {
		mFlags = inFlags;

		//printf("DGE_CreateWindow ....\n");
	   // Create Window
	   m_hWnd = DGE_CreateWindow(WndProc, (char *)inTitle, inW, inH);
		if (!m_hWnd)
		{
			printf("DGE_CreateWindow - fatal error.\n");
			exit(1);
		}

		//printf("DGEStage ....\n");
      mStage = new DGEStage(m_hWnd,inW,inH,mFlags);
		//printf("DGEStage done\n");

      mStage->IncRef();
   }

   ~DGEFrame()
   {
		//printf("~DGEFrame...\n");
      //mStage->DecRef();
		//printf("Force stage desruction...\n");
      delete mStage;
		//printf("DestroyWindow...\n");
		DGE_DestroyWindow(m_hWnd);
   }

   int PollEvents( )
	{
		mStage->PollEvents();
		return sgDead;
	}

	static int StaticPollEvents(void *)
	{
		return sgDGEFrame->PollEvents();
	}


   void ProcessEvent(Event &inEvent)
   {
      mStage->ProcessEvent(inEvent);
   }
   void Resize(int inWidth,int inHeight)
   {
      mStage->Resize(inWidth,inHeight);
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

};


// --- When using the simple window class -----------------------------------------------



void CreateMainFrame(FrameCreationCallback inOnFrame,int inWidth,int inHeight,
   unsigned int inFlags, const char *inTitle, const char *inIcon)
{
	DWORD	dVersion=0;
	DWORD	dDate=0;

	// Init Dge Library
	if(DGE_FAILED(DGE_Init()))
	{
		printf("DGE_Init - fatal error.\n");
		exit(1);
	}


	DGE_Version(&dVersion, &dDate);
	//printf("Version: %x Date: %x\n", dVersion, dDate);

	sgDGEFrame = new DGEFrame(inTitle, sgDesktopWidth, sgDesktopHeight, inFlags);

	//printf("DGE_SetMainRunFunc...\n");
	DGE_SetMainRunFunc(DGEFrame::StaticPollEvents);
	//printf("Created main frame.\n");

	inOnFrame(sgDGEFrame);

	sgDGEFrame->Resize(320,240);

   MainLoop();
}


void TerminateMainLoop()
{
	//printf("TerminateMainLoop...\n");
   // Mix_CloseAudio();
   sgDead = true;
}

#if 0
static DGE_TimerID  sgTimerID = 0;
bool sgTimerActive = false;

Uint32 OnTimer(Uint32 interval, void *)
{
    // Ping off an event - any event will force the frame check.
    DGE_Event event;
    DGE_UserEvent userevent;
    /* In this example, our callback pushes an DGE_USEREVENT event
    into the queue, and causes ourself to be called again at the
    same interval: */
    userevent.type = DGE_USEREVENT;
    userevent.code = 0;
    userevent.data1 = NULL;
    userevent.data2 = NULL;
    event.type = DGE_USEREVENT;
    event.user = userevent;
    sgTimerActive = false;
    sgTimerID = 0;
    DGE_PushEvent(&event);
    return 0;
}


void AddModStates(int &ioFlags,int inState = -1)
{
   int state = inState==-1 ? DGE_GetModState() : inState;
   if (state & KMOD_SHIFT) ioFlags |= efShiftDown;
   if (state & KMOD_CTRL) ioFlags |= efCtrlDown;
   if (state & KMOD_ALT) ioFlags |= efAltDown;
   if (state & KMOD_META) ioFlags |= efCommandDown;

   int m = DGE_GetMouseState(0,0);
   if ( m & DGE_BUTTON(1) ) ioFlags |= efLeftDown;
   if ( m & DGE_BUTTON(2) ) ioFlags |= efMiddleDown;
   if ( m & DGE_BUTTON(3) ) ioFlags |= efRightDown;
}

#define DGE_TRANS(x) case DGEK_##x: return key##x;

int DGEKeyToFlash(int inKey,bool &outRight)
{
   outRight = (inKey==DGEK_RSHIFT || inKey==DGEK_RCTRL ||
               inKey==DGEK_RALT || inKey==DGEK_RMETA || inKey==DGEK_RSUPER);
   if (inKey>=keyA && inKey<=keyZ)
      return inKey;
   if (inKey>=DGEK_0 && inKey<=DGEK_9)
      return inKey - DGEK_0 + keyNUMBER_0;
   if (inKey>=DGEK_KP0 && inKey<=DGEK_KP9)
      return inKey - DGEK_KP0 + keyNUMPAD_0;

   if (inKey>=DGEK_F1 && inKey<=DGEK_F15)
      return inKey - DGEK_F1 + keyF1;


   switch(inKey)
   {
      case DGEK_RALT:
      case DGEK_LALT:
         return keyALTERNATE;
      case DGEK_RSHIFT:
      case DGEK_LSHIFT:
         return keySHIFT;
      case DGEK_RCTRL:
      case DGEK_LCTRL:
         return keyCONTROL;
      case DGEK_LMETA:
      case DGEK_RMETA:
         return keyCOMMAND;

      case DGEK_CAPSLOCK: return keyCAPS_LOCK;
      case DGEK_PAGEDOWN: return keyPAGE_DOWN;
      case DGEK_PAGEUP: return keyPAGE_UP;
      case DGEK_EQUALS: return keyEQUAL;
      case DGEK_RETURN:
      case DGEK_KP_ENTER:
         return keyENTER;

      DGE_TRANS(BACKQUOTE)
      DGE_TRANS(BACKSLASH)
      DGE_TRANS(BACKSPACE)
      DGE_TRANS(COMMA)
      DGE_TRANS(DELETE)
      DGE_TRANS(DOWN)
      DGE_TRANS(END)
      DGE_TRANS(ESCAPE)
      DGE_TRANS(HOME)
      DGE_TRANS(INSERT)
      DGE_TRANS(LEFT)
      DGE_TRANS(LEFTBRACKET)
      DGE_TRANS(MINUS)
      DGE_TRANS(PERIOD)
      DGE_TRANS(QUOTE)
      DGE_TRANS(RIGHT)
      DGE_TRANS(RIGHTBRACKET)
      DGE_TRANS(SEMICOLON)
      DGE_TRANS(SLASH)
      DGE_TRANS(SPACE)
      DGE_TRANS(TAB)
      DGE_TRANS(UP)
   }

   return inKey;
}

std::map<int,wchar_t> sLastUnicode;

void ProcessEvent(DGE_Event &inEvent)
{

  switch(inEvent.type)
   {
      case DGE_QUIT:
      {
         Event close(etQuit);
         sgDGEFrame->ProcessEvent(close);
         break;
      }
      case DGE_MOUSEMOTION:
      {
         Event mouse(etMouseMove,inEvent.motion.x,inEvent.motion.y);
         AddModStates(mouse.flags);
         sgDGEFrame->ProcessEvent(mouse);
         break;
      }
      case DGE_MOUSEBUTTONDOWN:
      {
         Event mouse(etMouseDown,inEvent.button.x,inEvent.button.y);
         AddModStates(mouse.flags);
         sgDGEFrame->ProcessEvent(mouse);
         break;
      }
      case DGE_MOUSEBUTTONUP:
      {
         Event mouse(etMouseUp,inEvent.button.x,inEvent.button.y);
         AddModStates(mouse.flags);
         sgDGEFrame->ProcessEvent(mouse);

         // TODO: based on timer/motion?
         Event click(etMouseClick, inEvent.button.x,inEvent.button.y);
         sgDGEFrame->ProcessEvent(click);
         break;
      }

      case DGE_KEYDOWN:
      case DGE_KEYUP:
      {
         Event key(inEvent.type==DGE_KEYDOWN ? etKeyDown : etKeyUp );
         bool right;
         key.value = DGEKeyToFlash(inEvent.key.keysym.sym,right);
         if (inEvent.type==DGE_KEYDOWN)
         {
            key.code = inEvent.key.keysym.unicode;
            sLastUnicode[inEvent.key.keysym.scancode] = key.code;
         }
         else
            // DGE does not provide unicode on key up, so remember it,
            //  keyed by scancode
            key.code = sLastUnicode[inEvent.key.keysym.scancode];

         AddModStates(key.flags,inEvent.key.keysym.mod);
         if (right)
            key.flags |= efLocationRight;
         sgDGEFrame->ProcessEvent(key);
         break;
      }

      case DGE_VIDEORESIZE:
      {
         Event resize(etResize,inEvent.resize.w,inEvent.resize.h);
         sgDGEFrame->Resize(inEvent.resize.w,inEvent.resize.h);
         sgDGEFrame->ProcessEvent(resize);
         break;
      }
   }
}

#endif


void MainLoop()
{
	//printf("MainLoop....\n");
	// Run Program
	static int idx = 0;
	while(!sgDead)
	{
		if(DGE_FAILED(DGE_Run()))
			break;

		sgDGEFrame->PollEvents();
	}
	
	// Release Window
	//printf("Delete Frame...\n");
	delete sgDGEFrame;

	// Release DGE
	//printf("DGE_Close...\n");
	DGE_Close();

}


} // end namespace nme



