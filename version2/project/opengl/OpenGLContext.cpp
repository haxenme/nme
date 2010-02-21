#ifdef IPHONE

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

//typedef CAEAGLLayer *WinDC;
//typedef EAGLContext *GLCtx;
typedef void *WinDC;
typedef void *GLCtx;

#elif defined(SDL_OGL)

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

namespace nme
{

static GLuint sgOpenglType[] = { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES, GL_LINE_STRIP };


class OGLTexture : public Texture
{
public:
   OGLTexture(Surface *inSurface)
   {
      mPixelWidth = inSurface->Width();
      mPixelHeight = inSurface->Height();
      mDirtyRect = Rect(0,0);

      int w = UpToPower2(mPixelWidth);
      int h = UpToPower2(mPixelHeight);
		mTextureWidth = w;
		mTextureHeight = h;
      bool is_pow2 = w==mPixelWidth && h==mPixelHeight;

      Surface *load = inSurface;
      if (!is_pow2)
      {
         int pw = inSurface->Format()==pfAlpha ? 1 : 4;
         load = new SimpleSurface(w,h,inSurface->Format());
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
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );

      PixelFormat fmt = load->Format();
      GLuint src_format = fmt==pfAlpha ? GL_ALPHA : GL_RGBA;
      GLuint store_format = src_format;
      glTexImage2D(GL_TEXTURE_2D, 0, store_format, w, h, 0, src_format,
            GL_UNSIGNED_BYTE, load->Row(0) );

		mSmooth = true;
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);


      if (!is_pow2)
         load->DecRef();

      //int err = glGetError();
   }
   ~OGLTexture()
   {
      glDeleteTextures(1,&mTextureID);
   }

   void Bind(class Surface *inSurface,int inSlot)
   {
      glBindTexture(GL_TEXTURE_2D,mTextureID);
      if (mDirtyRect.HasPixels())
      {
         PixelFormat fmt = inSurface->Format();
         GLuint src_format = fmt==pfAlpha ? GL_ALPHA : GL_RGBA;
         glGetError();
         const uint8 *p0 = 
            inSurface->Row(mDirtyRect.y) + mDirtyRect.x*inSurface->BytesPP();
         #ifdef IPHONE
         for(int y=0;y<mDirtyRect.h;y++)
         {
            glTexSubImage2D(GL_TEXTURE_2D, 0, mDirtyRect.x,mDirtyRect.y + y,
               mDirtyRect.w, 1,
               src_format, GL_UNSIGNED_BYTE,
               p0 + y*inSurface->GetStride());
         }
         #else
         glPixelStorei(GL_UNPACK_ROW_LENGTH, inSurface->Width());
         glTexSubImage2D(GL_TEXTURE_2D, 0, mDirtyRect.x,mDirtyRect.y,
            mDirtyRect.w, mDirtyRect.h,
            src_format, GL_UNSIGNED_BYTE,
            p0);
         glPixelStorei(GL_UNPACK_ROW_LENGTH,0);
         #endif
         int err = glGetError();
         mDirtyRect = Rect();
      }
   }

	void BindFlags(bool inRepeat,bool inSmooth)
	{
      if (mRepeat!=inRepeat)
		{
			mRepeat = inRepeat;
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
		}

		if (mSmooth!=inSmooth)
		{
			mSmooth = inSmooth;
			if (mSmooth)
			{
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			}
			else
			{
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			}
		}

	}

   UserPoint PixelToTex(const UserPoint &inPixels)
   {
      return UserPoint(inPixels.x/mTextureWidth, inPixels.y/mTextureHeight);
   }


   GLuint mTextureID;
   bool mRepeat;
   bool mSmooth;
   int mPixelWidth;
   int mPixelHeight;
   int mTextureWidth;
   int mTextureHeight;
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
      mLineWidth = -1;
      mPointsToo = true;
      mBitmapSurface = 0;
      mBitmapTexture = 0;
      mUsingBitmapMatrix = false;
      mLineScaleNormal = -1;
      mLineScaleV = -1;
      mLineScaleH = -1;
   }

   void SetWindowSize(int inWidth,int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
   }

   int Width() const { return mWidth; }
   int Height() const { return mHeight; }

   void Clear(uint32 inColour, const Rect *inRect)
   {
      Rect r = inRect ? *inRect : Rect(mWidth,mHeight);
     
      if (r!=mViewport)
         glViewport(r.x,mHeight-r.y1(),r.w,r.h);

      if (r==Rect(mWidth,mHeight))
      {
         glClearColor((GLclampf)( ((inColour >>16) & 0xff) /255.0),
                      (GLclampf)( ((inColour >>8 ) & 0xff) /255.0),
                      (GLclampf)( ((inColour     ) & 0xff) /255.0),
                      (GLclampf)1.0 );
         glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
      }
      else
      {
         glColor4f((GLclampf)( ((inColour >>16) & 0xff) /255.0),
                   (GLclampf)( ((inColour >>8 ) & 0xff) /255.0),
                   (GLclampf)( ((inColour     ) & 0xff) /255.0),
                   (GLclampf)1.0 );
         glMatrixMode(GL_MODELVIEW);
         glPushMatrix();
         glLoadIdentity();
         glMatrixMode(GL_PROJECTION);
         glPushMatrix();
         glLoadIdentity();

         static GLfloat rect[4][2] = { { -2,-2 }, { 2,-2 }, { 2, 2 }, {-2, 2 } };
         glVertexPointer(2, GL_FLOAT, 0, rect[0]);
         glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

         glPopMatrix();
         glMatrixMode(GL_MODELVIEW);
         glPopMatrix();
      }

      if (r!=mViewport)
         glViewport(mViewport.x, mHeight-mViewport.y1(), mViewport.w, mViewport.h);
   }

   void SetViewport(const Rect &inRect)
   {
      if (inRect!=mViewport)
      {
         glMatrixMode(GL_PROJECTION);
         glLoadIdentity();
         #ifdef IPHONE
         glOrthof(inRect.x,inRect.x1(), inRect.y1(),inRect.y, -1, 1);
         #else
         glOrtho(inRect.x,inRect.x1(), inRect.y1(),inRect.y, -1, 1);
         #endif
         glMatrixMode(GL_MODELVIEW);
         glLoadIdentity();
         mMatrix = Matrix();
         mViewport = inRect;
         glViewport(inRect.x, mHeight-inRect.y1(), inRect.w, inRect.h);
      }
   }


   void BeginRender(const Rect &inRect)
   {
      #ifndef IPHONE
      #ifndef SDL_OGL
      wglMakeCurrent(mDC,mOGLCtx);
      #endif
      #endif

      SetViewport(inRect);

      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
      glEnable(GL_POINT_SMOOTH);
      #ifndef IPHONE
      glEnable(GL_LINE_SMOOTH);
      #endif
      glEnableClientState(GL_VERTEX_ARRAY);
   }
   void EndRender()
   {
   }


   void Flip()
   {
      #ifndef IPHONE
      #ifndef SDL_OGL
      SwapBuffers(mDC);
      #endif
      #endif
   }


   void Render(const RenderState &inState, const HardwareCalls &inCalls )
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
         mLineScaleV = -1;
         mLineScaleH = -1;
         mLineScaleNormal = -1;
      }


      uint32 last_col = 0;
      Texture *bound_texture = 0;
      for(int c=0;c<inCalls.size();c++)
      {
         HardwareArrays &arrays = *inCalls[c];
         Vertices &vert = arrays.mVertices;
         Vertices &tex_coords = arrays.mTexCoords;

         glVertexPointer(2,GL_FLOAT,0,&vert[0].x);
         bool tex = arrays.mSurface && tex_coords.size()==vert.size();
         if (tex)
         {
            glEnable(GL_TEXTURE_2D);
            arrays.mSurface->Bind(*this,0);
				bound_texture = arrays.mSurface->GetTexture();
            const ColorTransform &t = *inState.mColourTransform;
            glColor4f(t.redScale,t.greenScale,t.blueScale,t.alphaScale);
				last_col = -1;
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            glTexCoordPointer(2,GL_FLOAT,0,&tex_coords[0].x);
         }
         else
         {
				bound_texture = 0;
            glDisable(GL_TEXTURE_2D);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
         }
   
         DrawElements &elements = arrays.mElements;
         for(int e=0;e<elements.size();e++)
         {
            DrawElement draw = elements[e];

				if (bound_texture)
				{
					bound_texture->BindFlags(draw.mBitmapRepeat,draw.mBitmapSmooth);
				}
				else if (c==0 || last_col!=draw.mColour)
            {
               last_col = draw.mColour;
               glColor4ub(last_col>>16,last_col>>8,last_col,last_col>>24);
            }
				
   
            if ( (draw.mPrimType == ptLineStrip) && draw.mCount>1)
            {
               if (draw.mWidth<=0)
                  SetLineWidth(1.0);
               else
                  switch(draw.mScaleMode)
                  {
                     case ssmNone: SetLineWidth(draw.mWidth); break;
                     case ssmNormal:
                        if (mLineScaleNormal<0)
                           mLineScaleNormal =
                              sqrt( 0.5*( mMatrix.m00*mMatrix.m00 + mMatrix.m01*mMatrix.m01 +
                                          mMatrix.m10*mMatrix.m10 + mMatrix.m11*mMatrix.m11 ) );
                        SetLineWidth(draw.mWidth*mLineScaleNormal);
                        break;
                     case ssmVertical:
                        if (mLineScaleV<0)
                           mLineScaleV =
                              sqrt( mMatrix.m00*mMatrix.m00 + mMatrix.m01*mMatrix.m01 );
                        SetLineWidth(draw.mWidth*mLineScaleV);
                        break;

                     case ssmHorizontal:
                        if (mLineScaleH<0)
                           mLineScaleH =
                              sqrt( mMatrix.m10*mMatrix.m10 + mMatrix.m11*mMatrix.m11 );
                        SetLineWidth(draw.mWidth*mLineScaleH);
                        break;
                  }

               if (mPointsToo)
                  glDrawArrays(GL_POINTS, draw.mFirst, draw.mCount );
            }
   
            glDrawArrays(sgOpenglType[draw.mPrimType], draw.mFirst, draw.mCount );
         }
      }
   }

   void BeginBitmapRender(Surface *inSurface,uint32 inTint,bool inRepeat,bool inSmooth)
   {
      if (!mUsingBitmapMatrix)
      {
         mUsingBitmapMatrix = true;
         glPushMatrix();
         glLoadIdentity();
      }

      if (mBitmapSurface==inSurface && mTint==inTint)
         return;

      mTint = inTint;
      mBitmapSurface = inSurface;
      glColor4ub(inTint>>16,inTint>>8,inTint,inTint>>24);
      inSurface->Bind(*this,0);
		mBitmapTexture->BindFlags(inRepeat,inSmooth);
      mBitmapTexture = inSurface->GetTexture();
      glEnable(GL_TEXTURE_2D);
   }

   void RenderBitmap(const Rect &inSrc, int inX, int inY)
   {
      UserPoint vertex[4];
      UserPoint tex[4];
      
      for(int i=0;i<4;i++)
      {
         UserPoint t(inSrc.x + ((i&1)?inSrc.w:0), inSrc.y + ((i>1)?inSrc.h:0) ); 
         tex[i] = mBitmapTexture->PixelToTex(t);
         vertex[i] =  UserPoint(inX + ((i&1)?inSrc.w:0), inY + ((i>1)?inSrc.h:0) ); 
      }

      glVertexPointer(2, GL_FLOAT, 0, &vertex[0].x);
      glTexCoordPointer(2, GL_FLOAT, 0, &tex[0].x);
      glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
   }

   void EndBitmapRender()
   {
      if (mUsingBitmapMatrix)
      {
         mUsingBitmapMatrix = false;
         glPopMatrix();
      }

      mBitmapTexture = 0;
      mBitmapSurface = 0;
   }

   void SetLineWidth(double inWidth)
   {
      if (inWidth!=mLineWidth)
      {
         double w = inWidth;
         #ifdef IPHONE
         if (w>1)
            glDisable(GL_LINE_SMOOTH);
         else
         {
            w = 1;
            glEnable(GL_LINE_SMOOTH);
         }
         #endif
         mLineWidth = inWidth;
         glLineWidth(w);

         if (mPointsToo)
            glPointSize(inWidth);
      }
   }



   Texture *CreateTexture(Surface *inSurface)
   {
      return new OGLTexture(inSurface);
   }


   Matrix mMatrix;
   double mLineScaleV;
   double mLineScaleH;
   double mLineScaleNormal;

   Rect mViewport;
   WinDC mDC;
   GLCtx mOGLCtx;
   uint32 mTint;
   int mWidth,mHeight;
   bool   mPointsToo;
   bool   mUsingBitmapMatrix;
   double mLineWidth;
   Surface *mBitmapSurface;
   Texture *mBitmapTexture;
};


HardwareContext *HardwareContext::CreateOpenGL(void *inWindow, void *inGLCtx)
{
   return new OGLContext( (WinDC)inWindow, (GLCtx)inGLCtx );
}

} // end namespace nme

