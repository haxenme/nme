#ifdef SDL_OGL

#include <SDL_opengl.h>
typedef void *WinDC;
typedef void *GLCtx;

#else

#include <windows.h>
#include <gl/GL.h>

typedef HDC WinDC;
typedef HGLRC GLCtx;

#endif


#include <Graphics.h>
#include <Surface.h>

#ifndef GL_CLAMP_TO_EDGE
  #define GL_CLAMP_TO_EDGE 0x812F
#endif



class OGLTexture : public Texture
{
public:
   OGLTexture(Surface *inSurface)
   {
      mPixelWidth = inSurface->Width();
      mPixelHeight = inSurface->Height();
      mDirtyRect = Rect(inSurface->Width(),inSurface->Height());

      int w = UpToPower2(mPixelWidth);
      int h = UpToPower2(mPixelHeight);
      bool is_pow2 = w==mPixelWidth && h==mPixelHeight;

      Surface *load = inSurface;
      if (!is_pow2)
      {
         int pw = inSurface->Format()==pfAlpha ? 1 : 4;
         Surface *load = new SimpleSurface(w,h,inSurface->Format());
         load->IncRef();
         for(int y=0;y<mPixelHeight;y++)
         {
             memcpy((void *)load->Row(y),inSurface->Row(y),mPixelWidth*pw);
             if (w!=mPixelWidth)
                memcpy((void *)(load->Row(y)+mPixelWidth*pw),inSurface->Row(y),mPixelWidth*pw);
         }
         if (h!=mPixelHeight)
            memcpy((void *)load->Row(mPixelHeight),load->Row(mPixelHeight-1),
                   (mPixelWidth + (w!=mPixelWidth))*pw);
      }

      glGenTextures(1, &mTextureID);
      glBindTexture(GL_TEXTURE_2D,mTextureID);
      mRepeat = true;
      if (mRepeat)
      {
         glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
         glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
      }
      else
      {
         glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
         glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
      }

      PixelFormat fmt = load->Format();
      GLuint src_format = fmt==pfAlpha ? GL_ALPHA : GL_RGBA;
      GLuint store_format = src_format;
      glTexImage2D(GL_TEXTURE_2D, 0, store_format, w, h, 0, src_format,
            GL_UNSIGNED_BYTE, load->Row(0) );

      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);


      if (!is_pow2)
         load->DecRef();

      int err = glGetError();
   }
   ~OGLTexture()
   {
      glDeleteTextures(1,&mTextureID);
   }

   void Bind(class Surface *inSurface,int inSlot)
   {
      glBindTexture(GL_TEXTURE_2D,mTextureID);
   }
   UserPoint PixelToTex(const UserPoint &inPixels)
   {
      return UserPoint(inPixels.x/mPixelWidth, inPixels.y/mPixelHeight);
   }


   GLuint mTextureID;
   bool mRepeat;
   int mPixelWidth;
   int mPixelHeight;
};

// --- HardwareContext Interface ---------------------------------------------------------

class OGLContext : public HardwareContext
{
public:
   OGLContext(WinDC inDC, GLCtx inOGLCtx)
   {
      mDC = inDC;
      mOGLCtx = inOGLCtx;
      mWidth = 0;
      mHeight = 0;
      mBitmapSurface = 0;
      mBitmapTexture = 0;
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
         glOrtho(inRect.x,inRect.x1(), inRect.y1(),inRect.y, -1, 1);
         glMatrixMode(GL_MODELVIEW);
         glLoadIdentity();
         mMatrix = Matrix();
         mViewport = inRect;
         glViewport(inRect.x, mHeight-inRect.y1(), inRect.w, inRect.h);
         glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
      }
   }


   void BeginRender(const Rect &inRect)
   {
      #ifndef SDL_OGL
      wglMakeCurrent(mDC,mOGLCtx);
      #endif
      SetViewport(inRect);
   }
   void EndRender()
   {
   }


   void Flip()
   {
      #ifndef SDL_OGL
      SwapBuffers(mDC);
      #endif
   }


   void Render(const RenderState &inState,
               const DrawElements &inElements,
               const Vertices &inVertices,
               const Vertices &inTexCoords,
               Surface *inSurface,
               uint32 inColour)
   {
      if (mMatrix!=*inState.mTransform.mMatrix)
      {
         mMatrix=*inState.mTransform.mMatrix;
         float matrix[] =
         {
            mMatrix.m00, mMatrix.m10, 0, 0,
            mMatrix.m01, mMatrix.m11, 0, 0,
            0,           0,           1, 0,
            mMatrix.mtx, mMatrix.mty, 0, 1
         };
         glLoadMatrixf(matrix);
      }

      bool tex = inSurface && inTexCoords.size()==inVertices.size();
      if (tex)
      {
         glEnable(GL_TEXTURE_2D);
         inSurface->Bind(*this,0);
         const ColorTransform &t = *inState.mColourTransform;
         glColor4f(t.redScale,t.greenScale,t.blueScale,t.alphaScale);
      }
      else
      {
         glDisable(GL_TEXTURE_2D);
         glColor4ub(inColour>>16,inColour>>8,inColour,255);
      }

      static GLuint type[] = { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES };

      glEnable(GL_BLEND);

      for(int e=0;e<inElements.size();e++)
      {
         DrawElement draw = inElements[e];
         glBegin(type[draw.mType]);
         for(int i=0;i<draw.mCount;i++)
         {
            if (tex)
               glTexCoord2fv( &inTexCoords[draw.mFirst+i].x );
            glVertex2fv( &inVertices[draw.mFirst+i].x );
         }
         glEnd();
      }
   }

   void BeginBitmapRender(Surface *inSurface,uint32 inTint)
   {
      if (mBitmapSurface==inSurface && mTint==inTint)
         return;

      mTint = inTint;
      mBitmapSurface = inSurface;
      glColor4ub(inTint>>16,inTint>>8,inTint,inTint>>24);
      inSurface->Bind(*this,0);
      mBitmapTexture = inSurface->GetTexture();
      glEnable(GL_TEXTURE_2D);
      glEnable(GL_BLEND);
   }

   void RenderBitmap(const Rect &inSrc, int inX, int inY)
   {
      glBegin(GL_TRIANGLE_STRIP);
      for(int i=0;i<4;i++)
      {
         UserPoint t(inSrc.x + ((i&1)?inSrc.w:0), inSrc.y + ((i>1)?inSrc.h:0) ); 
         UserPoint tex = mBitmapTexture->PixelToTex(t);
         UserPoint p(inX + ((i&1)?inSrc.w:0), inY + ((i>1)?inSrc.h:0) ); 

         glTexCoord2fv(&tex.x);
         glVertex2fv(&p.x);
      }
      glEnd();
   }

   void EndBitmapRender()
   {
      mBitmapTexture = 0;
      mBitmapSurface = 0;
   }


   Texture *CreateTexture(Surface *inSurface)
   {
      return new OGLTexture(inSurface);
   }


   Matrix mMatrix;
   Rect mViewport;
   WinDC mDC;
   GLCtx mOGLCtx;
   uint32 mTint;
   int mWidth,mHeight;
   Surface *mBitmapSurface;
   Texture *mBitmapTexture;
};


HardwareContext *HardwareContext::CreateOpenGL(void *inWindow, void *inGLCtx)
{
   return new OGLContext( (WinDC)inWindow, (GLCtx)inGLCtx );
}

