#include "./OGL.h"
#include "./OGLShaders.h"
#include <NMEThread.h>


#ifdef NEED_EXTENSIONS
#define DEFINE_EXTENSION
#include "OGLExtensions.h"
#undef DEFINE_EXTENSION
#endif



int sgDrawCount = 0;
int sgBufferCount = 0;
int sgDrawBitmap = 0;


namespace nme
{

const double one_on_255 = 1.0/255.0;

static GLuint sgOpenglType[] =
  { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES, GL_LINE_STRIP, GL_POINTS, GL_LINES };


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
      mColourArrayEnabled = false;
      mThreadId = GetThreadId();
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

   void DestroyNativeTexture(void *inNativeTexture)
   {
      GLuint tid = (GLuint)(size_t)inNativeTexture;
      if ( !IsMainThread() )
      {
         //printf("Warning - leaking texture %d", tid );
		 mZombieTextures.push_back(tid);
      }
      else
         glDeleteTextures(1,&tid);
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
         #ifndef NME_FORCE_GLES2
         // TODO: Clear with a rect
         // TODO: Need replacement call for GLES2
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
         #endif
      }


      if (r!=mViewport)
         glViewport(mViewport.x, mHeight-mViewport.y1(), mViewport.w, mViewport.h);
   }

   virtual void setOrtho(float x0,float x1, float y0, float y1)
   {
      #ifndef NME_FORCE_GLES2
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
      #endif
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


   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
      if (!inForHitTest)
      {
         #ifndef NME_GLES
         #ifndef SDL_OGL
         #ifndef GLFW_OGL
         wglMakeCurrent(mDC,mOGLCtx);
         #endif
         #endif
         #endif
		 
         if (mZombieTextures.size())
         {
            glDeleteTextures(mZombieTextures.size(),&mZombieTextures[0]);
            mZombieTextures.resize(0);
         }

         // Force dirty
         mViewport.w = -1;
         SetViewport(inRect);

         glEnable(GL_BLEND);
         #ifdef NME_PREMULTIPLIED_ALPHA
         glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
         #else
         glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
         #endif

         #ifdef WEBOS
         glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
         #endif

         #ifndef NME_FORCE_GLES2
         if (mQuality>=sqHigh)
         {
            if (mPointSmooth)
               glEnable(GL_POINT_SMOOTH);
         }
         if (mQuality>=sqBest)
            glEnable(GL_LINE_SMOOTH);
         #endif
         mLineWidth = 99999;

         // printf("DrawArrays: %d, DrawBitmaps:%d  Buffers:%d\n", sgDrawCount, sgDrawBitmap, sgBufferCount );
         sgDrawCount = 0;
         sgDrawBitmap = 0;
         sgBufferCount = 0;
         OnBeginRender();
      }
   }
   void EndRender()
   {

   }

   virtual void OnBeginRender()
   {
      #ifndef NME_FORCE_GLES2
      glEnableClientState(GL_VERTEX_ARRAY);
      #endif
   }


   void Flip()
   {
      #ifndef NME_GLES
      #ifndef SDL_OGL
      #ifndef GLFW_OGL
      SwapBuffers(mDC);
      #endif
      #endif
      #endif
   }

   virtual void CombineModelView(const Matrix &inModelView)
   {
      #ifndef NME_FORCE_GLES2
      // Do not combine ModelView and Projection in fixed-function
      float matrix[] =
      {
         mModelView.m00, mModelView.m10, 0, 0,
         mModelView.m01, mModelView.m11, 0, 0,
         0,           0,           1, 0,
         mModelView.mtx, mModelView.mty, 0, 1
      };
      glLoadMatrixf(matrix);
      #endif
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

         mCustomProg = arrays.mProgram;
         Vertices &vert = arrays.mVertices;
         Vertices &tex_coords = arrays.mTexCoords;
         bool persp = arrays.mFlags & HardwareArrays::PERSPECTIVE;
         
         if ( !arrays.mViewport.empty() ) {
            SetViewport( Rect( arrays.mViewport[ 0 ], arrays.mViewport[ 1 ], arrays.mViewport[ 2 ], arrays.mViewport[ 3 ] ) );   
         }
         
         if ( arrays.mFlags & HardwareArrays::BM_ADD ) {
           glBlendFunc( GL_SRC_ALPHA, GL_ONE );
		 } else if (  arrays.mFlags & HardwareArrays::BM_MULTIPLY ) {
           glBlendFunc( GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
		 } else if (  arrays.mFlags & HardwareArrays::BM_SCREEN ) {
           glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_COLOR);
         } else {
           #ifdef NME_PREMULTIPLIED_ALPHA
           glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
           #else
           glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
           #endif 
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
            SetModulatingTransform(inState.mColourTransform);
            if (arrays.mFlags & HardwareArrays::RADIAL )
            {
               float focus = ((arrays.mFlags & HardwareArrays::FOCAL_MASK)>>8) / 256.0;
               if (arrays.mFlags & HardwareArrays::FOCAL_SIGN)
                  focus = -focus;
               SetRadialGradient(true, focus );
            }
            else
               SetRadialGradient(0,0);
         }
         else
         {
            boundTexture = 0;
            SetTexture(0,0);
            SetModulatingTransform(0);
         }

         if (arrays.mColours.size() == vert.size() )
         {
            SetColourArray(&arrays.mColours[0]);
            SetModulatingTransform(inState.mColourTransform);
         }
         else
            SetColourArray(0);

   
         int n = elements.size();
         if (!PrepareDrawing())
            n = 0;

         sgBufferCount++;
         for(int e=0;e<n;e++)
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
                    SetSolidColour(col);
                }
            }
            
   
            if ( (draw.mPrimType == ptLineStrip || draw.mPrimType==ptPoints || draw.mPrimType==ptLines) && draw.mCount>1)
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
                     case ssmOpenGL:
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

               if (mPointsToo && mLineWidth>1.5 && draw.mPrimType!=ptLines )
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
         FinishDrawing();
      }
   }

   virtual void SetRadialGradient(bool inIsRadial, float inFocus)
   {
   }

   virtual bool PrepareDrawing()
   {
      return true;
   }

   virtual void FinishDrawing()
   {
      SetColourArray(0);
   }

   virtual void SetSolidColour(unsigned int col)
   {
       #ifndef NME_FORCE_GLES2
       float a = (float) ((col >> 24) & 0xFF) * one_on_255;
       float c0 = (float) ((col >> 16) & 0xFF) * one_on_255;
       float c1 = (float) ((col >> 8) & 0xFF) * one_on_255;
       float c2 = (float) (col & 0xFF) * one_on_255;
       #ifdef NME_PREMULTIPLIED_ALPHA
       glColor4f(c0*a,c1*a,c2*a,a);
       #else
       glColor4f(c0,c1,c2,a);
       #endif
       #endif
   }

   virtual void SetTexture(Surface *inSurface,const float *inTexCoords)
   {
      #ifndef NME_FORCE_GLES2
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
      #endif
   }

   virtual void SetPositionData(const float *inData,bool inPerspective)
   {
      #ifndef NME_FORCE_GLES2
      glVertexPointer(inPerspective ? 4 : 2,GL_FLOAT,0,inData);
      #endif
   }

   virtual void SetModulatingTransform(const ColorTransform *inTransform)
   {
      #ifndef NME_FORCE_GLES2
      if (inTransform)
         #ifdef NME_PREMULTIPLIED_ALPHA
         glColor4f( inTransform->redMultiplier*inTransform->alphaMultiplier,
                    inTransform->greenMultiplier*inTransform->alphaMultiplier,
                    inTransform->blueMultiplier*inTransform->alphaMultiplier,
                    inTransform->alphaMultiplier);
         #else
         glColor4f( inTransform->redMultiplier,
                    inTransform->greenMultiplier,
                    inTransform->blueMultiplier,
                    inTransform->alphaMultiplier);
         #endif
      #endif
   }

   virtual void SetColourArray(const int *inData)
   {
      #ifndef NME_FORCE_GLES2
      if (inData)
      {
         mColourArrayEnabled = true;
         glEnableClientState(GL_COLOR_ARRAY);
         glColorPointer(4,GL_UNSIGNED_BYTE,0,inData);
      }
      else if (mColourArrayEnabled)
      {
         mColourArrayEnabled = false;
         glDisableClientState(GL_COLOR_ARRAY);
      }
      #endif
   }

   virtual void PushBitmapMatrix()
   {
      #ifndef NME_FORCE_GLES2
      glPushMatrix();
      glLoadIdentity();
      #endif
   }

   virtual void PopBitmapMatrix()
   {
      #ifndef NME_FORCE_GLES2
      glPopMatrix();
      #endif
   }

   virtual void PrepareBitmapRender()
   {
      #ifndef NME_FORCE_GLES2
      float a = (float) ((mTint >> 24) & 0xFF) *one_on_255;
      float c0 = (float) ((mTint >> 16) & 0xFF) *one_on_255;
      float c1 = (float) ((mTint >> 8) & 0xFF) *one_on_255;
      float c2 = (float) (mTint & 0xFF) *one_on_255;
      #ifdef NME_PREMULTIPLIED_ALPHA
      glColor4f(c0*a,c1*a,c2*a,a);
      #else
      glColor4f(c0,c1,c2,a);
      #endif
      glEnable(GL_TEXTURE_2D);
      glEnableClientState(GL_TEXTURE_COORD_ARRAY);
      #ifdef NME_DITHER
      if (!inSmooth)
        glDisable(GL_DITHER);
      #endif
      #endif
   }

   virtual void FinishBitmapRender()
   {
      glDisable(GL_TEXTURE_2D);
      #ifdef NME_DITHER
      glEnable(GL_DITHER);
      #endif
   }


   void BeginBitmapRender(Surface *inSurface,uint32 inTint,bool inRepeat,bool inSmooth)
   {
      if (!mUsingBitmapMatrix)
      {
         mUsingBitmapMatrix = true;
         PushBitmapMatrix();
      }

      if (mBitmapSurface==inSurface && mTint==inTint)
         return;

      mTint = inTint;
      mBitmapSurface = inSurface;
      inSurface->Bind(*this,0);
      mBitmapTexture = inSurface->GetOrCreateTexture(*this);
      mBitmapTexture->BindFlags(inRepeat,inSmooth);

      PrepareBitmapRender();
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

      SetBitmapData(&vertex[0].x,&tex[0].x);

      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
      sgDrawBitmap++;
   }
   
   virtual void SetBitmapData(const float *inPos, const float *inTex)
   {
      #ifndef NME_FORCE_GLES2
      glVertexPointer(2,GL_FLOAT,0,inPos);
      glTexCoordPointer(2,GL_FLOAT,0,inTex);
      #endif
   }

   void EndBitmapRender()
   {
      if (mUsingBitmapMatrix)
      {
         mUsingBitmapMatrix = false;
         PopBitmapMatrix();
      }

      mBitmapTexture = 0;
      mBitmapSurface = 0;
      FinishBitmapRender();
   }

   void SetLineWidth(double inWidth)
   {
      if (inWidth!=mLineWidth)
      {
         double w = inWidth;
         #ifndef NME_FORCE_GLES2
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
         #endif

         mLineWidth = inWidth;
         glLineWidth(w);
         
         // TODO: Need replacement call for GLES2?
         #ifndef NME_FORCE_GLES2
         if (mPointsToo)
            glPointSize(inWidth);
         #endif
      }
   }



   Texture *CreateTexture(Surface *inSurface,unsigned int inFlags)
   {
      return OGLCreateTexture(inSurface,inFlags);
   }

   void SetQuality(StageQuality inQ)
   {
      #ifndef NME_FORCE_GLES2
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
      #endif
   }

   Matrix mModelView;
   ThreadId mThreadId;

   double mLineScaleV;
   double mLineScaleH;
   double mLineScaleNormal;
   StageQuality mQuality;


   Rect mViewport;
   WinDC mDC;
   GLCtx mOGLCtx;
   uint32 mTint;
   int mWidth,mHeight;
   bool   mColourArrayEnabled;
   bool   mPointsToo;
   bool   mPointSmooth;
   bool   mUsingBitmapMatrix;
   double mLineWidth;
   Surface *mBitmapSurface;
   Texture *mBitmapTexture;
   GPUProg *mCustomProg;
   
   QuickVec<GLuint> mZombieTextures;
};

#ifdef NME_USE_VBO
void ReleaseVertexBufferObject(unsigned int inVBO)
{
   if (glDeleteBuffers)
      glDeleteBuffers(1,&inVBO);
}
#endif




// --- OGL2 -------------------------------------------------------------------

class OGL2Context : public OGLContext
{
public:
   OGL2Context(WinDC inDC, GLCtx inOGLCtx) : OGLContext(inDC,inOGLCtx)
   {
      mIsRadial = false;
      for(int i=0;i<gpuSIZE;i++)
         mProg[i] = 0;
      for(int i=0;i<4;i++)
         for(int j=0;j<4;j++)
            mBitmapTrans[i][j] = mTrans[i][j] = i==j;
      //mBitmapTrans[2][2] = 0.0;
   }
   ~OGL2Context()
   {
      for(int i=0;i<gpuSIZE;i++)
         delete mProg[i];
   }

   void OnBeginRender()
   {
      // Do nothing
   }

   virtual void setOrtho(float x0,float x1, float y0, float y1)
   {
      mScaleX = 2.0/(x1-x0);
      mScaleY = 2.0/(y1-y0);
      mOffsetX = (x0+x1)/(x0-x1);
      mOffsetY = (y0+y1)/(y0-y1);
      mModelView = Matrix();

      mBitmapTrans[0][0] = mScaleX;
      mBitmapTrans[0][3] = mOffsetX;
      mBitmapTrans[1][1] = mScaleY;
      mBitmapTrans[1][3] = mOffsetY;

      CombineModelView(mModelView);
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
      mPositionPerspective = inPerspective;
   }


   virtual void SetModulatingTransform(const ColorTransform *inTransform)
   {
      mColourTransform = inTransform;
   }

   virtual void SetColourArray(const int *inData)
   {
      mColourArray = inData;
   }

   GPUProg *createDefaultShader(GPUProgID inID)
   {
      switch(inID)
      {
         case gpuSolid:
            return GPUProg::create( gSolidVert, gSolidFrag );
         case gpuColourTransform:
            return GPUProg::create( gColourVert, gColourTransFrag );
         case gpuColour:
            return GPUProg::create( gColourVert, gColourFrag );
         case gpuRadialGradient:
            return GPUProg::create( gTextureVert, gRadialTextureFrag );
         case gpuRadialFocusGradient:
            return GPUProg::create( gTextureVert, gRadialFocusTextureFrag );
         case gpuTexture:
            return GPUProg::create( gTextureVert, gTextureFrag );
         case gpuTextureColourArray:
            return GPUProg::create( gTextureColourVert, gTextureColourFrag );
         case gpuTextureTransform:
            return GPUProg::create( gTextureVert, gTextureTransFrag );
         case gpuBitmap:
            return GPUProg::create( gTextureVert, gBitmapFrag );
         case gpuBitmapAlpha:
            return GPUProg::create( gTextureVert, gBitmapAlphaFrag );
         default:
           break;
      }
      return 0;
   }

   virtual bool PrepareDrawing()
   {
      GPUProgID id = gpuNone;
      GPUProg *prog = 0;
      // check for custom program
      if (mCustomProg)
         prog = mCustomProg;

      // fallback if custom program not defined
      if (!prog)
      {
         if (mTexCoords)
         {
            if (mIsRadial)
            {
               if (mRadialFocus!=0)
                  id = gpuRadialFocusGradient;
               else
                  id = gpuRadialGradient;
            }
            else if (mColourTransform && !mColourTransform->IsIdentity())
               id = gpuTextureTransform;
            else if (mColourArray)
               id = gpuTextureColourArray;
            else
               id = gpuTexture;
         }
         else
         {
            if (mColourArray)
            {
               if (mColourTransform && !mColourTransform->IsIdentity())
                  id = gpuColourTransform;
               else
                  id = gpuColour;
            }
            else
               id = gpuSolid;
         }

         if (id==gpuNone)
            return false;

         if (!mProg[id])
            mProg[id] = createDefaultShader(id);

         if (!mProg[id])
            return false;

         prog = mProg[id];
      }

      mCurrentProg = prog;
      mCurrentProg->bind();


      mCurrentProg->setPositionData(mPosition,mPositionPerspective);
      mCurrentProg->setTransform(mTrans);
      if (mTexCoords)
      {
         mCurrentProg->setTexCoordData(mTexCoords);
         mTextureSurface->Bind(*this,0);
      }
      if (mColourArray)
         mCurrentProg->setColourData(mColourArray);
      
      if (mColourTransform)
         mCurrentProg->setColourTransform(mColourTransform);

      if (id==gpuRadialFocusGradient)
         mCurrentProg->setGradientFocus(mRadialFocus);

      return true;
   }

   virtual void SetBitmapData(const float *inPos, const float *inTex)
   {
      mCurrentProg->setPositionData(inPos,false);
      mCurrentProg->setTexCoordData(inTex);
   }



   virtual void FinishDrawing()
   {
      if (mCurrentProg)
         mCurrentProg->finishDrawing();
   }


   virtual void SetSolidColour(unsigned int col)
   {
      if (mCurrentProg)
         mCurrentProg->setTint(col);
   }


   virtual void PushBitmapMatrix() { }

   virtual void PopBitmapMatrix() { }


   virtual void PrepareBitmapRender()
   {
      GPUProgID id = mBitmapSurface->BytesPP() == 1 ? gpuBitmapAlpha : gpuBitmap;
      if (!mProg[id])
         mProg[id] = createDefaultShader(id);
      mCurrentProg = mProg[id];
      if (!mCurrentProg)
         return;

      mCurrentProg->bind();
      mCurrentProg->setTint(mTint);
      mBitmapSurface->Bind(*this,0);
      mCurrentProg->setTransform(mBitmapTrans);
      // TODO: Need replacement call for GLES2
      //#ifndef NME_FORCE_GLES2
      //glEnableClientState(GL_TEXTURE_COORD_ARRAY);
      //#endif
   }

   virtual void FinishBitmapRender()
   {
      // TODO: Need replacement call for GLES2
      //#ifndef NME_FORCE_GLES2
      //glDisableClientState(GL_TEXTURE_COORD_ARRAY);
      //#endif
   }

   virtual void SetRadialGradient(bool inIsRadial, float inFocus)
   {
      mIsRadial = inIsRadial;
      mRadialFocus = inFocus;
   }


   const float *mPosition;
   bool  mPositionPerspective;
   bool  mIsRadial;
   float mRadialFocus;
   Surface   *mTextureSurface;
   const int *mColourArray;
   const float *mTexCoords;
   const ColorTransform *mColourTransform;

   GPUProg *mCurrentProg;
   GPUProg *mProg[gpuSIZE];

   double mScaleX;
   double mOffsetX;
   double mScaleY;
   double mOffsetY;

   Trans4x4 mTrans;
   Trans4x4 mBitmapTrans;
};



// ----------------------------------------------------------------------------


void InitExtensions()
{
   static bool extentions_init = false;
   if (!extentions_init)
   {
      extentions_init = true;
      #ifdef HX_WINDOWS
      #ifndef SDL_OGL
	  #ifndef GLFW_OGL
         wglMakeCurrent( (WinDC)inWindow,(GLCtx)inGLCtx);
      #endif
      #endif


      #ifdef NEED_EXTENSIONS
      #define GET_EXTENSION
      #include "OGLExtensions.h"
      #undef DEFINE_EXTENSION
      #endif

      #endif
   }
}


HardwareContext *HardwareContext::CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders)
{
   HardwareContext *ctx;

   #ifdef ANDROID
   const char *version = (const char *)glGetString(GL_VERSION);
   if (version)
      shaders = version[10] == '2';
   ELOG("VERSION %s (%c), pipeline = %s", version, version==0 ? '?' : version[10], shaders ? "programmable" : "fixed");
   #endif
   
   #ifdef NME_FORCE_GLES2
   //printf ("Force GLES2\n");
   shaders = true;
   #elif defined(NME_FORCE_GLES1)
   //printf ("Force GLES1\n");
   shaders = false;
   #endif
   
   if (shaders)
   {
	  //printf("Using OGL2\n");
      ctx = new OGL2Context( (WinDC)inWindow, (GLCtx)inGLCtx );
   }
   else
   {
	  //printf("Using OGL1\n");
      ctx = new OGLContext( (WinDC)inWindow, (GLCtx)inGLCtx );
   }

   InitExtensions();
   return ctx;
}

} // end namespace nme
