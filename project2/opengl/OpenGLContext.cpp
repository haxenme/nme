#include <windows.h>
#include <gl/GL.h>
#include <Graphics.h>

// --- HardwareContext Interface ---------------------------------------------------------

class OGLContext : public HardwareContext
{
public:
   OGLContext(HDC inDC, HGLRC inOGLCtx)
	{
		mDC = inDC;
		mOGLCtx = inOGLCtx;
		mWidth = 0;
		mHeight = 0;
	}

	void SetWindowSize(int inWidth,int inHeight)
	{
		mWidth = inWidth;
		mHeight = inHeight;
	}

   int Width() const { return mWidth; }
   int Height() const { return mHeight; }

	void Clear(uint32 inColour)
	{
		mViewport = Rect();
		glViewport(0,0,mWidth,mHeight);
		glClearColor((GLclampf)( ((inColour >>16) & 0xff) /255.0),
                   (GLclampf)( ((inColour >>8 ) & 0xff) /255.0),
                   (GLclampf)( ((inColour     ) & 0xff) /255.0),
                   (GLclampf)1.0 );
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

	void SetViewport(const Rect &inRect)
	{
		if (inRect!=mViewport)
		{
			glMatrixMode(GL_PROJECTION);
			glLoadIdentity();
			glMatrixMode(GL_MODELVIEW);
			glLoadIdentity();
			glViewport(inRect.x, mHeight-inRect.y1(), inRect.w, inRect.h);
			glOrtho(inRect.x,inRect.x1(), inRect.y,inRect.y1(), -1, 1);
			mViewport = inRect;
		}
	}


   void BeginRender(const Rect &inRect)
	{
		wglMakeCurrent(mDC,mOGLCtx);
		SetViewport(inRect);
	}
   void EndRender()
	{
	}


	void Flip()
	{
		SwapBuffers(mDC);
	}

	Rect mViewport;
	HDC mDC;
	HGLRC mOGLCtx;
	int mWidth,mHeight;
};


HardwareContext *HardwareContext::CreateOpenGL(void *inWindow, void *inGLCtx)
{
	return new OGLContext( (HDC)inWindow, (HGLRC)inGLCtx );
}

