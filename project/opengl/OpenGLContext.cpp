#include "./OGL.h"


#ifdef HX_WINDOWS
typedef void (APIENTRY * glBindBufferARB_f)(GLenum target, GLuint buffer);
typedef void (APIENTRY * glDeleteBuffersARB_f)(GLsizei n, const GLuint *buffers);
typedef void (APIENTRY * glGenBuffersARB_f)(GLsizei n, GLuint *buffers);
typedef void (APIENTRY * glBufferDataARB_f)(GLenum target, GLsizeiptrARB size, const GLvoid *data, GLenum usage);

glBindBufferARB_f glBindBuffer=0;
glDeleteBuffersARB_f glDeleteBuffers=0;
glGenBuffersARB_f glGenBuffers=0;
glBufferDataARB_f glBufferData=0;
#endif



int sgDrawCount = 0;
int sgBufferCount = 0;
int sgDrawBitmap = 0;

namespace nme
{

const double one_on_256 = 1.0/256.0;

static GLuint sgOpenglType[] =
  { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES, GL_LINE_STRIP, GL_POINTS };


void ResetHardwareContext()
{
   //__android_log_print(ANDROID_LOG_ERROR, "NME", "ResetHardwareContext");
   gTextureContextVersion++;
}

// --- HardwareContext Interface ---------------------------------------------------------


HardwareContext* nme::HardwareContext::current = NULL;


class OGLContext : public HardwareContext
{
public:
   OGLContext(WinDC inDC, GLCtx inOGLCtx)
   {
      HardwareContext::current = this;
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
      mPointSmooth = true;
      const char *str = (const char *)glGetString(GL_VENDOR);
      if (str && !strncmp(str,"Intel",5))
         mPointSmooth = false;
      #if defined(NME_GLES)
      mQuality = sqLow;
      #else
      mQuality = sqBest;
      #endif
   }
   ~OGLContext()
   {
   }

   void SetWindowSize(int inWidth,int inHeight)
   {
      mWidth = inWidth;
      mHeight = inHeight;
      #ifdef ANDROID
      //__android_log_print(ANDROID_LOG_ERROR, "NME", "SetWindowSize %d %d", inWidth, inHeight);
      #endif

   }

   int Width() const { return mWidth; }
   int Height() const { return mHeight; }

   void Clear(uint32 inColour, const Rect *inRect)
   {
      Rect r = inRect ? *inRect : Rect(mWidth,mHeight);
     
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
         // TODO: Clear with a rect
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


         glDisable(GL_TEXTURE_2D);
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

   virtual void setOrtho(float x0,float x1, float y0, float y1)
   {
      glMatrixMode(GL_PROJECTION);
      glLoadIdentity();
      #if defined(NME_GLES)
      glOrthof
      #else
      glOrtho
      #endif
            //(0,inRect.w, inRect.h,0, -1, 1);
         (x0,x1,y0,y1, -1, 1);
      glMatrixMode(GL_MODELVIEW);
      glLoadIdentity();
      mModelView = Matrix();
   }

   void SetViewport(const Rect &inRect)
   {
      if (inRect!=mViewport)
      {
         setOrtho(inRect.x,inRect.x1(), inRect.y1(),inRect.y);
         mViewport = inRect;
         glViewport(inRect.x, mHeight-inRect.y1(), inRect.w, inRect.h);
      }
   }


   void BeginRender(const Rect &inRect)
   {
      #ifndef NME_GLES
      #ifndef SDL_OGL
      wglMakeCurrent(mDC,mOGLCtx);
      #endif
      #endif

      // Force dirty
      mViewport.w = -1;
      SetViewport(inRect);

      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

      #ifdef WEBOS
      glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
      #endif

      if (mQuality>=sqHigh)
      {
         if (mPointSmooth)
            glEnable(GL_POINT_SMOOTH);
      }
      if (mQuality>=sqBest)
         glEnable(GL_LINE_SMOOTH);
      mLineWidth = 99999;
      glEnableClientState(GL_VERTEX_ARRAY);
      // printf("DrawArrays: %d, DrawBitmaps:%d  Buffers:%d\n", sgDrawCount, sgDrawBitmap, sgBufferCount );
      sgDrawCount = 0;
      sgDrawBitmap = 0;
      sgBufferCount = 0;
   }
   void EndRender()
   {

   }


   void Flip()
   {
      #ifndef NME_GLES
      #ifndef SDL_OGL
      SwapBuffers(mDC);
      #endif
      #endif
   }

   virtual void CombineModelView(const Matrix &inModelView)
   {
      // Do not combine ModelView and Projection in fixed-function
      float matrix[] =
      {
         mModelView.m00, mModelView.m10, 0, 0,
         mModelView.m01, mModelView.m11, 0, 0,
         0,           0,           1, 0,
         mModelView.mtx, mModelView.mty, 0, 1
      };
      glLoadMatrixf(matrix);
 
   }

   void Render(const RenderState &inState, const HardwareCalls &inCalls )
   {
      
      glEnable( GL_BLEND );
      SetViewport(inState.mClipRect);

      if (mModelView!=*inState.mTransform.mMatrix)
      {
         mModelView=*inState.mTransform.mMatrix;
         CombineModelView(mModelView);
         mLineScaleV = -1;
         mLineScaleH = -1;
         mLineScaleNormal = -1;
      }

      uint32 last_col = 0;
      for(int c=0;c<inCalls.size();c++)
      {
         HardwareArrays &arrays = *inCalls[c];
         DrawElements &elements = arrays.mElements;
         if (elements.empty())
            continue;

         Vertices &vert = arrays.mVertices;
         Vertices &tex_coords = arrays.mTexCoords;
         bool persp = arrays.mPerspectiveCorrect;
         
         if ( !arrays.mViewport.empty() ) {
            SetViewport( Rect( arrays.mViewport[ 0 ], arrays.mViewport[ 1 ], arrays.mViewport[ 2 ], arrays.mViewport[ 3 ] ) );   
         }
         
         if ( arrays.mBlendMode == bmAdd ) {
           glBlendFunc( GL_SRC_ALPHA, GL_ONE );
         } else {
           glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
         }
         
         #ifdef NME_USE_VBO
         {
            if (!arrays.mVertexBO)
            {
               glGenBuffers(1,&arrays.mVertexBO);
               glBindBuffer(GL_ARRAY_BUFFER, arrays.mVertexBO);
               glBufferData(GL_ARRAY_BUFFER,sizeof(float)*(persp ?4:2)*vert.size(),
                              &vert[0].x, GL_STATIC_DRAW);
            }
            else
               glBindBuffer(GL_ARRAY_BUFFER, arrays.mVertexBO);
            glVertexPointer(persp ? 4 : 2,GL_FLOAT,0,0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
         }
         else
         #endif
         {
            SetPositionData(&vert[0].x,persp);
         }

         Texture *boundTexture = 0;
         bool tex = arrays.mSurface && tex_coords.size();
         if (tex)
         {
            boundTexture = arrays.mSurface->GetOrCreateTexture(*this);
            SetTexture(arrays.mSurface,&tex_coords[0].x);
            last_col = -1;
            SetTextureColourTransform(inState.mColourTransform);
         }
         else
         {
            boundTexture = 0;
            SetTexture(0,0);
         }

         if (arrays.mColours.size() == vert.size())
            SetColourArray(&arrays.mColours[0]);

   
         PrepareDrawing();

         sgBufferCount++;
         for(int e=0;e<elements.size();e++)
         {
            DrawElement draw = elements[e];

            if (boundTexture)
            {
               boundTexture->BindFlags(draw.mBitmapRepeat,draw.mBitmapSmooth);
               #ifdef NME_DITHER
               if (!inSmooth)
                  glDisable(GL_DITHER);
               #endif
            }
            else
            {
                int col = inState.mColourTransform->Transform(draw.mColour);
                if (c==0 || last_col!=col)
                {
                    last_col = col; 
                    SetElementColour(
                      (float) ((col >> 16) & 0xFF) *  one_on_256,
                      (float) ((col >> 8) & 0xFF) * one_on_256,
                      (float) (col & 0xFF) * one_on_256,
                      (float) ((col >> 24) & 0xFF) * one_on_256);
                }
            }
            
   
            if ( (draw.mPrimType == ptLineStrip || draw.mPrimType==ptPoints) && draw.mCount>1)
            {
               if (draw.mWidth<0)
                  SetLineWidth(1.0);
               else if (draw.mWidth==0)
                  SetLineWidth(0.0);
               else
                  switch(draw.mScaleMode)
                  {
                     case ssmNone: SetLineWidth(draw.mWidth); break;
                     case ssmNormal:
                        if (mLineScaleNormal<0)
                           mLineScaleNormal =
                              sqrt( 0.5*( mModelView.m00*mModelView.m00 + mModelView.m01*mModelView.m01 +
                                          mModelView.m10*mModelView.m10 + mModelView.m11*mModelView.m11 ) );
                        SetLineWidth(draw.mWidth*mLineScaleNormal);
                        break;
                     case ssmVertical:
                        if (mLineScaleV<0)
                           mLineScaleV =
                              sqrt( mModelView.m00*mModelView.m00 + mModelView.m01*mModelView.m01 );
                        SetLineWidth(draw.mWidth*mLineScaleV);
                        break;

                     case ssmHorizontal:
                        if (mLineScaleH<0)
                           mLineScaleH =
                              sqrt( mModelView.m10*mModelView.m10 + mModelView.m11*mModelView.m11 );
                        SetLineWidth(draw.mWidth*mLineScaleH);
                        break;
                  }

               if (mPointsToo && mLineWidth>1.5)
                  glDrawArrays(GL_POINTS, draw.mFirst, draw.mCount );
            }
   
            //printf("glDrawArrays %d : %d x %d\n", draw.mPrimType, draw.mFirst, draw.mCount );

            sgDrawCount++;
            glDrawArrays(sgOpenglType[draw.mPrimType], draw.mFirst, draw.mCount );

            #ifdef NME_DITHER
            if (boundTexture && !draw.mBitmapSmooth)
               glEnable(GL_DITHER);
            #endif
         }

         if (arrays.mColours.size() == vert.size())
            SetColourArray(0);
      }
   }

   virtual void PrepareDrawing()
   {
   }

   virtual void SetElementColour(float r, float g, float b, float a)
   {
       glColor4f(r,g,b,a);
   }

   virtual void SetTexture(Surface *inSurface,const float *inTexCoords)
   {
      if (!inSurface)
      {
         glDisable(GL_TEXTURE_2D);
         glDisableClientState(GL_TEXTURE_COORD_ARRAY);
      }
      else
      {
         glEnable(GL_TEXTURE_2D);
         inSurface->Bind(*this,0);
         glEnableClientState(GL_TEXTURE_COORD_ARRAY);
         glTexCoordPointer(2,GL_FLOAT,0,inTexCoords);
      }
   }

   virtual void SetPositionData(const float *inData,bool inPerspective)
   {
      glVertexPointer(inPerspective ? 4 : 2,GL_FLOAT,0,inData);
   }

   virtual void SetTextureColourTransform(const ColorTransform *inTransform)
   {
      glColor4f( inTransform->redMultiplier,
                 inTransform->greenMultiplier,
                 inTransform->blueMultiplier,
                 inTransform->alphaMultiplier);
   }


   virtual void SetColourArray(const int *inData)
   {
      if (inData)
      {
         glEnableClientState(GL_COLOR_ARRAY);
         glColorPointer(4,GL_UNSIGNED_BYTE,0,inData);
      }
      else
      {
         glDisableClientState(GL_COLOR_ARRAY);
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
      glColor4f((float) ((inTint >> 16) & 0xFF) / 256,
        (float) ((inTint >> 8) & 0xFF) / 256,
        (float) (inTint & 0xFF) / 256,
        (float) ((inTint >> 24) & 0xFF) / 256);
      inSurface->Bind(*this,0);
      mBitmapTexture = inSurface->GetOrCreateTexture(*this);
      mBitmapTexture->BindFlags(inRepeat,inSmooth);
      glEnable(GL_TEXTURE_2D);
      #ifdef NME_DITHER
      if (!inSmooth)
        glDisable(GL_DITHER);
      #endif
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
      sgDrawBitmap++;
   }

   void EndBitmapRender()
   {
      if (mUsingBitmapMatrix)
      {
         mUsingBitmapMatrix = false;
         glPopMatrix();
      }

      #ifdef NME_DITHER
      glEnable(GL_DITHER);
      #endif
      mBitmapTexture = 0;
      mBitmapSurface = 0;
   }

   void SetLineWidth(double inWidth)
   {
      if (inWidth!=mLineWidth)
      {
         double w = inWidth;
         if (mQuality>=sqBest)
         {
            if (w>1)
               glDisable(GL_LINE_SMOOTH);
            else
            {
               w = 1;
               if (inWidth==0)
               {
                  glDisable(GL_LINE_SMOOTH);
               }
               else
                  glEnable(GL_LINE_SMOOTH);
            }
         }

         mLineWidth = inWidth;
         glLineWidth(w);

         if (mPointsToo)
            glPointSize(inWidth);
      }
   }



   Texture *CreateTexture(Surface *inSurface,unsigned int inFlags)
   {
      return OGLCreateTexture(inSurface,inFlags);
   }

   void SetQuality(StageQuality inQ)
   {
      inQ = sqMedium;
      if (inQ!=mQuality)
      {
         mQuality = inQ;
         if (mQuality>=sqHigh)
         {
            if (mPointSmooth)
               glEnable(GL_POINT_SMOOTH);
         }
         else
            glDisable(GL_POINT_SMOOTH);

         if (mQuality>=sqBest)
            glEnable(GL_LINE_SMOOTH);
         else
            glDisable(GL_LINE_SMOOTH);
         mLineWidth = 99999;
      }
   }

   Matrix mModelView;

   double mLineScaleV;
   double mLineScaleH;
   double mLineScaleNormal;
   StageQuality mQuality;


   Rect mViewport;
   WinDC mDC;
   GLCtx mOGLCtx;
   uint32 mTint;
   int mWidth,mHeight;
   bool   mPointsToo;
   bool   mPointSmooth;
   bool   mUsingBitmapMatrix;
   double mLineWidth;
   Surface *mBitmapSurface;
   Texture *mBitmapTexture;
};

#ifdef NME_USE_VBO
void ReleaseVertexBufferObject(unsigned int inVBO)
{
   if (glDeleteBuffers)
      glDeleteBuffers(1,&inVBO);
}
#endif


class OGL2Context : public OGLContext
{
public:
   OGL2Context(WinDC inDC, GLCtx inOGLCtx) : OGLContext(inDC,inOGLCtx)
   {
   }

   virtual void setOrtho(float x0,float x1, float y0, float y1)
   {
      mScaleX = 2.0/(x1-x0);
      mScaleY = 2.0/(y1-y0);
      mOffsetX = (x0+x1)/(x0-x1);
      mOffsetY = (y0+y1)/(y0-y1);
   } 

   virtual void CombineModelView(const Matrix &inModelView)
   {
      mTrans[0][0] = inModelView.m00 * mScaleX;
      mTrans[0][1] = inModelView.m01 * mScaleX;
      mTrans[0][2] = 0;
      mTrans[0][3] = inModelView.mtx * mScaleX + mOffsetX;

      mTrans[1][0] = inModelView.m10 * mScaleY;
      mTrans[1][1] = inModelView.m11 * mScaleY;
      mTrans[1][2] = 0;
      mTrans[1][3] = inModelView.mty * mScaleY + mOffsetY;
   }

   virtual void SetTexture(Surface *inSurface,const float *inTexCoords)
   {
      mTextureSurface = inSurface;
      mTexCoords = inTexCoords;
   }

   virtual void SetPositionData(const float *inData,bool inPerspective)
   {
      mPosition = inData;
      mPositionPerspective = inData;
   }

   virtual void SetTextureColourTransform(const ColorTransform &inTransform)
   {
   }

   virtual void SetColourArray(const int *inData)
   {
   }

   virtual void PrepareDrawing()
   {
   }

   virtual void SetElementColour(float r, float g, float b, float a)
   {
   }

   Surface   *mTextureSurface;
   const int *mColourArray;
   const float *mTexCoords;
   const float *mPosition;
   bool  mPositionPerspective;
   ColorTransform *mTextureTransform;


   double mScaleX;
   double mOffsetX;
   double mScaleY;
   double mOffsetY;

   float mTrans[2][4];
};


void InitExtensions()
{
   static bool extentions_init = false;
   if (!extentions_init)
   {
      extentions_init = true;
      #ifdef HX_WINDOWS
      #ifndef SDL_OGL
         wglMakeCurrent( (WinDC)inWindow,(GLCtx)inGLCtx);
      #endif
      glBindBuffer=(glBindBufferARB_f) wglGetProcAddress("glBindBufferARB");
      glDeleteBuffers=(glDeleteBuffersARB_f) wglGetProcAddress("glDeleteBuffersARB");
      glGenBuffers=(glGenBuffersARB_f) wglGetProcAddress("glGenBuffersARB");
      glBufferData=(glBufferDataARB_f) wglGetProcAddress("glBufferDataARB");
      #ifdef NME_USE_VBO
      if (glBindBuffer)
         sgUSEVBO = false;
      #endif
      #endif
   }
}

HardwareContext *HardwareContext::CreateOpenGL(void *inWindow, void *inGLCtx)
{
   #if 0
   HardwareContext *ctx =  new OGL2Context( (WinDC)inWindow, (GLCtx)inGLCtx );
   #else
   HardwareContext *ctx =  new OGLContext( (WinDC)inWindow, (GLCtx)inGLCtx );
   #endif

   InitExtensions();
   return ctx;
}

} // end namespace nme

