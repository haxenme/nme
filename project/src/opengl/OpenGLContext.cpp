#include "./OGL.h"
#include <NMEThread.h>

#if HX_LINUX
#include <dlfcn.h>
#endif


#ifdef NEED_EXTENSIONS
#define DEFINE_EXTENSION
#include "OGLExtensions.h"
#undef DEFINE_EXTENSION
#endif


int sgDrawCount = 0;
int sgDrawBitmap = 0;


namespace nme
{

const double one_on_255 = 1.0/255.0;
const double one_on_256 = 1.0/256.0;

static GLuint sgOpenglType[] =
  { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES, GL_LINE_STRIP, GL_POINTS, GL_LINES, 0, 0 /* Quads / Full */ };


void ReloadExtentions();


// --- HardwareRenderer Interface ---------------------------------------------------------


HardwareRenderer* nme::HardwareRenderer::current = NULL;


void ResetHardwareContext()
{
   //__android_log_print(ANDROID_LOG_ERROR, "NME", "ResetHardwareContext");
   gTextureContextVersion++;
   if (HardwareRenderer::current)
      HardwareRenderer::current->OnContextLost();
}



class OGLContext : public HardwareRenderer
{
public:

   OGLContext(WinDC inDC, GLCtx inOGLCtx)
   {
      HardwareRenderer::current = this;
      mDC = inDC;
      mOGLCtx = inOGLCtx;
      mWidth = 0;
      mHeight = 0;
      mLineWidth = -1;
      mLineScaleNormal = -1;
      mLineScaleV = -1;
      mLineScaleH = -1;
      mThreadId = GetThreadId();
      mHasZombie = false;
      mContextId = gTextureContextVersion;
      mQuadsBuffer = 0;
      mFullTexCoordsBuffer = 0;
      mQuality = sqBest;

      for(int i=0;i<PROG_COUNT;i++)
         mProg[i] = 0;
      for(int i=0;i<4;i++)
         for(int j=0;j<4;j++)
            mTrans[i][j] = i==j;
   }
   ~OGLContext()
   {
      for(int i=0;i<PROG_COUNT;i++)
         delete mProg[i];
   }
   bool IsOpenGL() const { return true; }



   void DestroyNativeTexture(void *inNativeTexture)
   {
      GLuint tid = (GLuint)(size_t)inNativeTexture;
      DestroyTexture(tid);
   }

   void DestroyTexture(unsigned int inTex)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieTextures.push_back(inTex);
      }
      else
      {
         glDeleteTextures(1,&inTex);
      }
   }

   void DestroyVbo(unsigned int inVbo)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieVbos.push_back(inVbo);
      }
      else
         glDeleteBuffers(1,&inVbo);
   }

   void DestroyProgram(unsigned int inProg)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombiePrograms.push_back(inProg);
      }
      else
         glDeleteProgram(inProg);
   }
   void DestroyShader(unsigned int inShader)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieShaders.push_back(inShader);
      }
      else
         glDeleteShader(inShader);
   }
   void DestroyFramebuffer(unsigned int inBuffer)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieFramebuffers.push_back(inBuffer);
      }
      else
         glDeleteFramebuffers(1,&inBuffer);
   }

   void DestroyRenderbuffer(unsigned int inBuffer)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieRenderbuffers.push_back(inBuffer);
      }
      else
         glDeleteRenderbuffers(1,&inBuffer);
   }
   void DestroyVertexarray(unsigned int inBuffer)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieVertexarrays.push_back(inBuffer);
      }
#ifndef NME_NO_GLES3COMPAT
      else
         glDeleteVertexArrays(1,&inBuffer);
#endif
   }


   void OnContextLost()
   {
      mZombieTextures.resize(0);
      mZombieVbos.resize(0);
      mZombiePrograms.resize(0);
      mZombieShaders.resize(0);
      mZombieFramebuffers.resize(0);
      mZombieRenderbuffers.resize(0);
      mZombieVertexarrays.resize(0);
      mHasZombie = false;
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


      float alpha = ((inColour >>24) & 0xff) /255.0;
      float red =   ((inColour >>16) & 0xff) /255.0;
      float green = ((inColour >>8 ) & 0xff) /255.0;
      float blue  = ((inColour     ) & 0xff) /255.0;
      red *= alpha;
      green *= alpha;
      blue *= alpha;

      if (r==Rect(mWidth,mHeight))
      {
         glClearColor(red, green, blue, alpha );
         glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
      }
      else
      {
         //printf(" - partial clear\n");
      }


      if (r!=mViewport)
         glViewport(mViewport.x, mHeight-mViewport.y1(), mViewport.w, mViewport.h);
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
         if (mContextId!=gTextureContextVersion)
         {
            updateContext();
         }

         #ifndef NME_GLES
         #ifndef SDL_OGL
         #ifndef GLFW_OGL
         wglMakeCurrent(mDC,mOGLCtx);
         #endif
         #endif
         #endif

         if (mHasZombie)
         {
            mHasZombie = false;
            if (mZombieTextures.size())
            {
               glDeleteTextures(mZombieTextures.size(),&mZombieTextures[0]);
               mZombieTextures.resize(0);
            }

            if (mZombieVbos.size())
            {
               glDeleteBuffers(mZombieVbos.size(),&mZombieVbos[0]);
               mZombieVbos.resize(0);
            }

            if (mZombiePrograms.size())
            {
               for(int i=0;i<mZombiePrograms.size();i++)
                  glDeleteProgram(mZombiePrograms[i]);
               mZombiePrograms.resize(0);
            }

            if (mZombieShaders.size())
            {
               for(int i=0;i<mZombieShaders.size();i++)
                  glDeleteShader(mZombieShaders[i]);
               mZombieShaders.resize(0);
            }

            if (mZombieFramebuffers.size())
            {
               glDeleteFramebuffers(mZombieFramebuffers.size(),&mZombieFramebuffers[0]);
               mZombieFramebuffers.resize(0);
            }

            if (mZombieRenderbuffers.size())
            {
               glDeleteRenderbuffers(mZombieRenderbuffers.size(),&mZombieRenderbuffers[0]);
               mZombieRenderbuffers.resize(0);
            }

            if (mZombieVertexarrays.size())
            {
               #ifndef NME_NO_GLES3COMPAT
               glDeleteVertexArrays(mZombieVertexarrays.size(),&mZombieVertexarrays[0]);
               #endif
               mZombieVertexarrays.resize(0);
            }
         }


         // Force dirty
         mViewport.w = -1;
         SetViewport(inRect);


         glEnable(GL_BLEND);

        #ifdef WEBOS
         glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
         #endif

         mLineWidth = 99999;

         // printf("DrawArrays: %d, DrawBitmaps:%d  Buffers:%d\n", sgDrawCount, sgDrawBitmap, sgBufferCount );
         sgDrawCount = 0;
         sgDrawBitmap = 0;
      }
   }
   void EndRender()
   {

   }

   void updateContext()
   {
      mContextId = gTextureContextVersion;
      mThreadId = GetThreadId();
      mQuadsBuffer = 0;
      mFullTexCoordsBuffer = 0;
      mHasZombie = false;
      mZombieTextures.resize(0);
      mZombieVbos.resize(0);
      mZombiePrograms.resize(0);
      mZombieShaders.resize(0);
      mZombieFramebuffers.resize(0);
      mZombieRenderbuffers.resize(0);
      mZombieVertexarrays.resize(0);

      ReloadExtentions();
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

   void BeginDirectRender()
   {
      gDirectMaxAttribArray = 0;
   }

   void EndDirectRender()
   {
      for(int i=0;i<gDirectMaxAttribArray;i++)
         glDisableVertexAttribArray(i);
   }


   void Render(const RenderState &inState, const HardwareData &inData )
   {
      if (!inData.mArray.size())
         return;

      SetViewport(inState.mClipRect);

      if (mModelView!=*inState.mTransform.mMatrix)
      {
         mModelView=*inState.mTransform.mMatrix;
         CombineModelView(mModelView);
         mLineScaleV = -1;
         mLineScaleH = -1;
         mLineScaleNormal = -1;
      }
      const ColorTransform *ctrans = inState.mColourTransform;
      if (ctrans && ctrans->IsIdentity())
         ctrans = 0;

      RenderData(inData,ctrans,mTrans);
   }

   void RenderData(const HardwareData &inData, const ColorTransform *ctrans,const Trans4x4 &inTrans)
   {
      const uint8 *data = 0;
      if (inData.mVertexBo)
      {
         if (inData.mContextId!=gTextureContextVersion)
         {
            if (inData.mVboOwner)
               inData.mVboOwner->DecRef();
            inData.mVboOwner = 0;
            // Create one right away...
            inData.mRendersWithoutVbo = 5;
            inData.mVertexBo = 0;
            inData.mContextId = 0;
         }
         else
            glBindBuffer(GL_ARRAY_BUFFER, inData.mVertexBo);
      }

      if (!inData.mVertexBo)
      {
         data = &inData.mArray[0];
         #ifndef EMSCRIPTEN
         inData.mRendersWithoutVbo++;
         if ( inData.mRendersWithoutVbo>4)
         #endif
         {
            glGenBuffers(1,&inData.mVertexBo);
            inData.mVboOwner = this;
            IncRef();
            inData.mContextId = gTextureContextVersion;
            glBindBuffer(GL_ARRAY_BUFFER, inData.mVertexBo);
            // printf("VBO DATA %d\n", inData.mArray.size());
            glBufferData(GL_ARRAY_BUFFER, inData.mArray.size(), data, GL_STATIC_DRAW);
            data = 0;
         }
      }

      GPUProg *lastProg = 0;
      bool rebind = false;
 
      for(int e=0;e<inData.mElements.size();e++)
      {
         const DrawElement &element = inData.mElements[e];
         int n = element.mCount;
         if (!n)
            continue;

         if (rebind && inData.mVertexBo)
         {
            glBindBuffer(GL_ARRAY_BUFFER, inData.mVertexBo);
            rebind = false;
         }

         int progId = 0;
         bool premAlpha = false;
         if ((element.mFlags & DRAW_HAS_TEX) && element.mSurface)
         {
            if (IsPremultipliedAlpha(element.mSurface->Format()))
               premAlpha = true;
            progId |= PROG_TEXTURE;
            if (element.mSurface->BytesPP()==1)
               progId |= PROG_ALPHA_TEXTURE;
         }

         if (element.mFlags & DRAW_HAS_COLOUR)
            progId |= PROG_COLOUR_PER_VERTEX;

         if (element.mFlags & DRAW_HAS_NORMAL)
            progId |= PROG_NORMAL_DATA;

         if (element.mFlags & DRAW_RADIAL)
         {
            progId |= PROG_RADIAL;
            if (element.mRadialPos!=0)
               progId |= PROG_RADIAL_FOCUS;
         }

         if (ctrans || element.mColour != 0xffffffff)
         {
            progId |= PROG_TINT;
            if (ctrans && ctrans->HasOffset())
               progId |= PROG_COLOUR_OFFSET;
         }

         bool persp = element.mFlags & DRAW_HAS_PERSPECTIVE;

         GPUProg *prog = mProg[progId];
         if (!prog)
             mProg[progId] = prog = GPUProg::create(progId);
         if (!prog)
            continue;

         switch(element.mBlendMode)
         {
            case bmAdd:
               glBlendFunc( GL_SRC_ALPHA, GL_ONE );
               break;
            case bmMultiply:
               glBlendFunc( GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
               break;
            case bmScreen:
               glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_COLOR);
               break;
            default:
               glBlendFunc(premAlpha ? GL_ONE : GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
         }


         if (prog!=lastProg)
         {
            if (lastProg)
               lastProg->disableSlots();

            prog->bind();
            prog->setTransform(inTrans);
            lastProg = prog;
         }

         int stride = element.mStride;
         if (prog->vertexSlot >= 0)
         {
            glVertexAttribPointer(prog->vertexSlot, persp ? 4 : 2 , GL_FLOAT, GL_FALSE, stride,
                data + element.mVertexOffset);
            glEnableVertexAttribArray(prog->vertexSlot);
         }

         if (prog->colourSlot >= 0)
         {
            glVertexAttribPointer(prog->colourSlot, 4, GL_UNSIGNED_BYTE, GL_TRUE, stride,
                data + element.mColourOffset);
            glEnableVertexAttribArray(prog->colourSlot);
         }

         if (prog->normalSlot >= 0)
         {
            glVertexAttribPointer(prog->normalSlot, 2, GL_FLOAT, GL_FALSE, stride,
                data + element.mNormalOffset);
            glEnableVertexAttribArray(prog->normalSlot);
         }


         if (prog->textureSlot >= 0)
         {
            if (element.mPrimType==ptQuadsFull)
            {
               BindFullQuadTextures(element.mCount);
               glVertexAttribPointer(prog->textureSlot, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), 0);
               if (data)
                  glBindBuffer(GL_ARRAY_BUFFER, 0);
               else
                  rebind = true;
            }
            else
               glVertexAttribPointer(prog->textureSlot,  2 , GL_FLOAT, GL_FALSE, stride, data + element.mTexOffset);

            glEnableVertexAttribArray(prog->textureSlot);

            if (element.mSurface)
            {
               Texture *boundTexture = element.mSurface->GetTexture(this);
               element.mSurface->Bind(*this,0);
               boundTexture->BindFlags(element.mFlags & DRAW_BMP_REPEAT,element.mFlags & DRAW_BMP_SMOOTH);
            }
         }



         if (element.mFlags & DRAW_RADIAL)
         {
            prog->setGradientFocus(element.mRadialPos * one_on_256);
         }

         if (progId & (PROG_TINT | PROG_COLOUR_OFFSET) )
         {
            prog->setColourTransform(ctrans, element.mColour, premAlpha );
         }

         if ( (element.mPrimType == ptLineStrip || element.mPrimType==ptPoints || element.mPrimType==ptLines)
                 && element.mCount>1)
         {
            if (element.mWidth<0)
               SetLineWidth(1.0);
            else if (element.mWidth==0)
               SetLineWidth(0.0);
            else
               switch(element.mScaleMode)
               {
                  case ssmNone: SetLineWidth(element.mWidth); break;
                  case ssmNormal:
                  case ssmOpenGL:
                     if (mLineScaleNormal<0)
                        mLineScaleNormal =
                           sqrt( 0.5*( mModelView.m00*mModelView.m00 + mModelView.m01*mModelView.m01 +
                                          mModelView.m10*mModelView.m10 + mModelView.m11*mModelView.m11 ) );
                     SetLineWidth(element.mWidth*mLineScaleNormal);
                     break;
                  case ssmVertical:
                     if (mLineScaleV<0)
                        mLineScaleV =
                           sqrt( mModelView.m00*mModelView.m00 + mModelView.m01*mModelView.m01 );
                     SetLineWidth(element.mWidth*mLineScaleV);
                     break;

                  case ssmHorizontal:
                     if (mLineScaleH<0)
                        mLineScaleH =
                           sqrt( mModelView.m10*mModelView.m10 + mModelView.m11*mModelView.m11 );
                     SetLineWidth(element.mWidth*mLineScaleH);
                     break;
               }
         }
   
            //printf("glDrawArrays %d : %d x %d\n", element.mPrimType, element.mFirst, element.mCount );

         sgDrawCount++;
         
         if (element.mPrimType==ptQuads || element.mPrimType==ptQuadsFull)
         {
            BindQuadsBufferIndices(element.mCount);
            glDrawElements(GL_TRIANGLES, element.mCount*3/2, mQuadsBufferType, 0 );
         }
         else
            glDrawArrays(sgOpenglType[element.mPrimType], 0, element.mCount );

      }

      if (lastProg)
        lastProg->disableSlots();

      if (inData.mVertexBo)
         glBindBuffer(GL_ARRAY_BUFFER,0);
   }

   void BindFullQuadTextures(int inVertexCount)
   {
      int quadCount = inVertexCount/4;
      if (mFullTexCoordsBuffer==0 || mFullTexCoordsSize<quadCount)
      {
         if (quadCount<256)
            quadCount = 256;
 
         if (mFullTexCoordsBuffer==0)
            glGenBuffers(1,&mFullTexCoordsBuffer);

         mFullTexCoordsSize = quadCount;
         glBindBuffer(GL_ARRAY_BUFFER, mFullTexCoordsBuffer);

         std::vector<float> tex(quadCount*2*4);
         int idx = 0;
         for(int i=0;i<quadCount;i++)
         {
            tex[idx++] = 0.0; tex[idx++] = 0.0;
            tex[idx++] = 1.0; tex[idx++] = 0.0;
            tex[idx++] = 0.0; tex[idx++] = 1.0;
            tex[idx++] = 1.0; tex[idx++] = 1.0;
         }
         glBufferData(GL_ARRAY_BUFFER, sizeof(float)*tex.size(), &tex[0], GL_STATIC_DRAW);
      }
      else
         glBindBuffer(GL_ARRAY_BUFFER, mFullTexCoordsBuffer);
   }

   void BindQuadsBufferIndices(int inVertexCount)
   {
      int quadCount = inVertexCount/4;
      if (mQuadsBuffer==0 || mQuadsBufferSize<quadCount)
      {
         if (mQuadsBuffer==0)
            glGenBuffers(1,&mQuadsBuffer);
         else
         {
            // Seems to be a bug in intel driver that kills some calls if we do not flush here
            glFlush();
         }

         if (quadCount< 4096)
            quadCount = 4096;

         mQuadsBufferSize = quadCount;
         glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mQuadsBuffer);

         if (quadCount*4<65536)
         {
            mQuadsBufferType = GL_UNSIGNED_SHORT;
            std::vector<unsigned short> data(quadCount*6);
            int idx = 0;
            int v0 = 0;
            for(int i=0;i<quadCount;i++)
            {
               data[idx++] = v0;
               data[idx++] = v0+1;
               data[idx++] = v0+2;
               data[idx++] = v0+1;
               data[idx++] = v0+3;
               data[idx++] = v0+2;
               v0 += 4;
            }
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(short)*data.size(), &data[0], GL_STATIC_DRAW);
         }
         else
         {
            mQuadsBufferType = GL_UNSIGNED_INT;
            std::vector<unsigned int> data(quadCount*6);
            int idx = 0;
            int v0 = 0;
            for(int i=0;i<quadCount;i++)
            {
               data[idx++] = v0;
               data[idx++] = v0+1;
               data[idx++] = v0+2;
               data[idx++] = v0+1;
               data[idx++] = v0+3;
               data[idx++] = v0+2;
               v0 += 4;
            }
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*data.size(), &data[0], GL_STATIC_DRAW);
         }
      }
      else
         glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mQuadsBuffer);
   }


   inline void SetLineWidth(double inWidth)
   {
      if (inWidth!=mLineWidth)
      {
         // TODO mQuality -> tessellate_lines/tessellate_lines_aa
         mLineWidth = inWidth;
         glLineWidth(inWidth<=0.25 ? 0.25 : inWidth);
      }
   }



   Texture *CreateTexture(Surface *inSurface,unsigned int inFlags)
   {
      return OGLCreateTexture(inSurface,inFlags);
   }

   void SetQuality(StageQuality inQ)
   {
      if (inQ!=mQuality)
      {
         mQuality = inQ;
         mLineWidth = 99999;
      }
   }



   void setOrtho(float x0,float x1, float y0, float y1)
   {
      mScaleX = 2.0/(x1-x0);
      mScaleY = 2.0/(y1-y0);
      mOffsetX = (x0+x1)/(x0-x1);
      mOffsetY = (y0+y1)/(y0-y1);
      mModelView = Matrix();

      CombineModelView(mModelView);
   } 

   void CombineModelView(const Matrix &inModelView)
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


   int mWidth,mHeight;
   Matrix mModelView;
   ThreadId mThreadId;
   int mContextId;

   double mLineScaleV;
   double mLineScaleH;
   double mLineScaleNormal;
   StageQuality mQuality;


   Rect mViewport;
   WinDC mDC;
   GLCtx mOGLCtx;

   //HardwareData mBitmapBuffer;
   //Texture *mBitmapTexture;

   double mLineWidth;
   
   // TODO - mutex in case finalizer is run from thread
   bool             mHasZombie;
   QuickVec<GLuint> mZombieTextures;
   QuickVec<GLuint> mZombieVbos;
   QuickVec<GLuint> mZombiePrograms;
   QuickVec<GLuint> mZombieShaders;
   QuickVec<GLuint> mZombieFramebuffers;
   QuickVec<GLuint> mZombieRenderbuffers;
   QuickVec<GLuint> mZombieVertexarrays;

   GPUProg *mProg[PROG_COUNT];

   double mScaleX;
   double mOffsetX;
   double mScaleY;
   double mOffsetY;

   GLuint mFullTexCoordsBuffer;
   GLuint mFullTexCoordsSize;

   GLuint mQuadsBuffer;
   GLenum mQuadsBufferSize;
   GLenum mQuadsBufferType;


   Trans4x4 mTrans;
};



// ----------------------------------------------------------------------------


void * gOGLLibraryHandle = 0;

static bool extentions_init = false;

bool InitOGLFunctions()
{
   static bool result = true;
   if (!extentions_init)
   {
      extentions_init = true;

      #ifdef HX_LINUX
      gOGLLibraryHandle = dlopen("libGL.so.1", RTLD_NOW|RTLD_GLOBAL);
      if (!gOGLLibraryHandle)
         gOGLLibraryHandle = dlopen("libGL.so", RTLD_NOW|RTLD_GLOBAL);
      if (!gOGLLibraryHandle)
      {
         //printf("Could not load %s (%s)\n",path, dlerror());
         result = false;
         return result;
      }
      #endif

      #ifdef NEED_EXTENSIONS
         #define GET_EXTENSION
         #include "OGLExtensions.h"
         #undef DEFINE_EXTENSION
      #endif
   }
   return result;
}

void ReloadExtentions()
{
   // Spec says this might be required - but do not think so in practice
   /*
   #ifdef ANDROID
   extentions_init = false;
   InitOGLFunctions();
   #endif
   */
}



HardwareRenderer *HardwareRenderer::CreateOpenGL(void *inWindow, void *inGLCtx, bool shaders)
{
   if (!InitOGLFunctions())
      return 0;

   HardwareRenderer *ctx = new OGLContext( (WinDC)inWindow, (GLCtx)inGLCtx );

   return ctx;
}

} // end namespace nme
