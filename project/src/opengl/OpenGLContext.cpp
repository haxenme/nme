#include "./OGL.h"
#include <NMEThread.h>
#include <HardwareImpl.h>

#if HX_LINUX
#include <dlfcn.h>
#endif

#ifdef ANDROID
#include <EGL/egl.h>
#endif

#ifdef NME_DYNAMIC_ANGLE
bool nmeEglMode = true;
#endif


#ifdef NEED_EXTENSIONS
#define DEFINE_EXTENSION
#include "OGLExtensions.h"
#undef DEFINE_EXTENSION
#endif


namespace nme
{

const double one_on_255 = 1.0/255.0;
const double one_on_256 = 1.0/256.0;

static GLuint sgOpenglType[] =
  { GL_TRIANGLE_FAN, GL_TRIANGLE_STRIP, GL_TRIANGLES, GL_LINE_STRIP, GL_POINTS, GL_LINES, 0, 0 /* Quads / Full */ };


void ReloadExtentions();


// --- HardwareRenderer Interface ---------------------------------------------------------

void ResetHardwareContext()
{
   //__android_log_print(ANDROID_LOG_ERROR, "NME", "ResetHardwareContext");
   gTextureContextVersion++;
   if (HardwareRenderer::current)
      HardwareRenderer::current->OnContextLost();
}

glStatsStruct gStats;
glStatsStruct gCurrStats;
void GetGLStats(int * statsArray, int n)
{
   gStats.get(statsArray, n);
}

class OGLContext : public HardwareRenderer
{
   int mContextId;
   ThreadId mThreadId;

   WinDC mDC;
   GLCtx mOGLCtx;

   //HardwareData mBitmapBuffer;
   //Texture *mBitmapTexture;

   // TODO - mutex in case finalizer is run from thread
   bool             mHasZombie;
   QuickVec<GLuint> mZombieTextures;
   QuickVec<GLuint> mZombieVbos;
   QuickVec<GLuint> mZombiePrograms;
   QuickVec<GLuint> mZombieShaders;
   QuickVec<GLuint> mZombieFramebuffers;
   QuickVec<GLuint> mZombieRenderbuffers;
   QuickVec<GLuint> mZombieQueries;
   QuickVec<GLuint> mZombieVertexArrays;
   QuickVec<GLuint> mZombieTransformFeedback;

   GPUProg *mProg[PROG_COUNT];


   GLuint mFullTexCoordsBuffer;
   GLuint mFullTexCoordsSize;

   GLuint mQuadsBuffer;
   GLenum mQuadsBufferSize;
   GLenum mQuadsBufferType;

   bool hasDrawBufferBlend;


public:



   OGLContext(WinDC inDC, GLCtx inOGLCtx)
   {
      mDC = inDC;
      mOGLCtx = inOGLCtx;
      mThreadId = GetThreadId();
      mHasZombie = false;
      mContextId = gTextureContextVersion;
      mQuadsBuffer = 0;
      mFullTexCoordsBuffer = 0;
      hasDrawBufferBlend = false;

      for(int i=0;i<PROG_COUNT;i++)
         mProg[i] = 0;


      makeCurrent();

      #ifdef NME_GFX_DEBUG
      printf("Vendor: %s\n", (char *)glGetString(GL_VENDOR) );
      printf("Renderer: %s\n", (char *)glGetString(GL_RENDERER) );
      printf("Sahder: %s\n", (char *)glGetString(GL_SHADING_LANGUAGE_VERSION) );
      #endif

      #ifdef EMSCRIPTEN
      for(int i=0;i<4;i++)
         glDisableVertexAttribArray(i);
      #endif

      const char *ext = (const char *)glGetString(GL_EXTENSIONS);
      if (ext && *ext)
      {
         while(true)
         {
            const char *next = ext;
            while(*next && *next!=' ')
               next++;
            std::string e(ext, next);
            // GL_KHR_blend_equation_advanced
            //printf("  ext >%s<\n", e.c_str() );
            if ( e=="ARB_draw_buffers_blend" || e=="GL_ARB_draw_buffers_blend" )
               hasDrawBufferBlend = true;
            if (!*next || !next[1])
              break;
            ext = next+1;
         }
      }
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

   void DestroyVbo(unsigned int inVbo,void *)
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

   void DestroyQuery(unsigned int inBuffer)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieQueries.push_back(inBuffer);
      }
      else
      {
         #if NME_GL_LEVEL>=300
         glDeleteQueries(1,&inBuffer);
         #endif
      }
   }

   void DestroyVertexArray(unsigned int inArray)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieVertexArrays.push_back(inArray);
      }
      else
      {
         #if NME_GL_LEVEL>=300
         glDeleteVertexArrays(1,&inArray);
         #endif
      }
   }


   void DestroyTransformFeedback(unsigned int inFeedback)
   {
      if ( !IsMainThread() )
      {
         mHasZombie = true;
         mZombieTransformFeedback.push_back(inFeedback);
      }
      else
      {
         #if NME_GL_LEVEL>=300
         glDeleteTransformFeedbacks(1,&inFeedback);
         #endif
      }
   }


   void OnContextLost()
   {
      mZombieTextures.resize(0);
      mZombieVbos.resize(0);
      mZombiePrograms.resize(0);
      mZombieShaders.resize(0);
      mZombieFramebuffers.resize(0);
      mZombieRenderbuffers.resize(0);
      mZombieQueries.resize(0);
      mZombieVertexArrays.resize(0);
      mZombieTransformFeedback.resize(0);
      mHasZombie = false;
   }

   bool supportsComponentAlpha() const
   {
      return hasDrawBufferBlend;
   }


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
         //glClearColor((rand()%256)/255.0, (rand()%256)/255.0, (rand()%256)/255.0, alpha );
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

   void makeCurrent()
   {
      #ifndef NME_GLES
      #ifndef SDL_OGL
      #ifndef GLFW_OGL
      if (!nmeEglMode)
         wglMakeCurrent(mDC,mOGLCtx);
      #endif
      #endif
      #endif
   }


   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
      if (!inForHitTest)
      {
         if (mContextId!=gTextureContextVersion)
         {
            updateContext();
         }

         makeCurrent();

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

            if (mZombieQueries.size())
            {
               #if NME_GL_LEVEL>=300
               glDeleteQueries(mZombieQueries.size(),&mZombieQueries[0]);
               #endif
               mZombieQueries.resize(0);
            }

            if (mZombieVertexArrays.size())
            {
               #if NME_GL_LEVEL>=300
               glDeleteQueries(mZombieVertexArrays.size(),&mZombieVertexArrays[0]);
               #endif
               mZombieVertexArrays.resize(0);
            }

            if (mZombieTransformFeedback.size())
            {
               #if NME_GL_LEVEL>=300
               glDeleteQueries(mZombieTransformFeedback.size(),&mZombieTransformFeedback[0]);
               #endif
               mZombieTransformFeedback.resize(0);
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
         gCurrStats.clear();
      }
   }
   void EndRender()
   {
      gCurrStats.get(&gStats);
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
      mZombieQueries.resize(0);
      mZombieVertexArrays.resize(0);
      mZombieTransformFeedback.resize(0);

      ReloadExtentions();
   }


   void Flip()
   {
      #ifndef NME_GLES
      #ifndef SDL_OGL
      #ifndef GLFW_OGL
      if (!nmeEglMode)
         SwapBuffers(mDC);
      #endif
      #endif
      #endif
   }

   void BeginDirectRender()
   {
      gDirectMaxAttribArray = 0;
      #ifndef NME_NO_GETERROR
      int err0 = glGetError();
      if (err0 != GL_NO_ERROR)
           ELOG("GL Error Before BeginDirectRender %d\n", err0);
      #endif
   }

   void EndDirectRender()
   {
      for(int i=0;i<gDirectMaxAttribArray;i++)
         glDisableVertexAttribArray(i);

      #ifndef NME_NO_GETERROR
      int err = glGetError();
      if (err != GL_NO_ERROR)
           ELOG("GL Error in DirectRender %d\n", err);
      #endif
   }


   void RenderData(const HardwareData &inData, const ColorTransform *ctrans,const Trans4x4 &inTrans)
   {
      // data will be 0 if a VBO is bounds, and offsets will be relative to the VBO data
      // Otherwise, it will be a raw pointer
      const uint8 *data = 0;

      // We can generally just bind the VBO once, and draw all the elements.
      // However, sometimes the texture coordinates come from a different VBO which invalidates
      //  the "current" GL_ARRAY_BUFFER.  Since this is done at the end of one element, we can check
      //  at the beginning of the next element to see if we need to re-bind.
      bool rebindVboNext = false;

      if (inData.mVertexBo)
      {
         if (inData.mContextId!=gTextureContextVersion)
         {
            if (inData.mVboOwner)
               inData.mVboOwner->DecRef();
            inData.mVboOwner = 0;
            // Create one right away...
            inData.mRendersWithoutVbo = 0x7ffffff0;
            inData.mVertexBo = 0;
            inData.mContextId = 0;
         }
         else
            rebindVboNext = true;
      }

      if (!inData.mVertexBo)
      {
         data = &inData.mArray[0];

         // Always use VBOs on EMSCRIPTEN and ANGLE
         #if ( !defined(EMSCRIPTEN) && !defined(NME_ANGLE) )
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
      else
         rebindVboNext = true;

      GPUProg *lastProg = 0;
 
      for(int e=0;e<inData.mElements.size();e++)
      {
         const DrawElement &element = inData.mElements[e];
         int n = element.mCount;
         if (!n)
            continue;

         if (rebindVboNext)
         {
            if (inData.mVertexBo)
               glBindBuffer(GL_ARRAY_BUFFER, inData.mVertexBo);
            else
               // Restore the meaning of vertex attributes to be raw pointers
               glBindBuffer(GL_ARRAY_BUFFER, 0);

            rebindVboNext = false;
         }

         unsigned progId = getProgId(element, ctrans);
         bool premAlpha = progId & PROG_PREM_ALPHA;
         progId &= ~PROG_PREM_ALPHA;
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
            case bmComponentAlpha:
               if (hasDrawBufferBlend)
               {
                  glBlendFunc(0x88F9/*GL_SRC1_COLOR*/, 0x88FA /*GL_ONE_MINUS_SRC1_COLOR*/ );
                  //glBlendFunc( GL_ONE, GL_ZERO);
                  break;
               }
               else
               {
                  // Fallthough
               }
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
            #ifdef NME_FLOAT32_VERT_VALUES
            glVertexAttribPointer(prog->colourSlot, 4, GL_FLOAT, GL_FALSE, stride,
                data + element.mColourOffset);
            #else
            glVertexAttribPointer(prog->colourSlot, 4, GL_UNSIGNED_BYTE, GL_TRUE, stride,
                data + element.mColourOffset);
            #endif
            glEnableVertexAttribArray(prog->colourSlot);
         }

         if (prog->normalSlot >= 0)
         {
            glVertexAttribPointer(prog->normalSlot, 2, GL_FLOAT, GL_FALSE, stride,
                data + element.mNormalOffset);
            glEnableVertexAttribArray(prog->normalSlot);
            if (prog->normScaleSlot>=0)
               prog->setNormScale(
                      sqrt( 0.5*( mModelView.m00*mModelView.m00 + mModelView.m01*mModelView.m01 +
                                  mModelView.m10*mModelView.m10 + mModelView.m11*mModelView.m11 ) ) );
         }


         // Do texture last since it might mess with GL_ARRAY_BUFFER
         if (prog->textureSlot >= 0)
         {
            if (element.mPrimType==ptQuadsFull)
            {
               BindFullQuadTextures(element.mCount);
               glVertexAttribPointer(prog->textureSlot, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), 0);
               rebindVboNext = true;
            }
            else
            {
               glVertexAttribPointer(prog->textureSlot,  2 , GL_FLOAT, GL_FALSE, stride, data + element.mTexOffset);
            }

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
 
         if (element.mPrimType==ptQuads || element.mPrimType==ptQuadsFull)
         {
            BindQuadsBufferIndices(element.mCount);
            GLsizei nVerts = element.mCount*3/2;
            glDrawElements(GL_TRIANGLES, nVerts, mQuadsBufferType, 0 );
            gCurrStats.record(nVerts, NME_GL_STATS_DRAW_ELEMENTS);
         }
         else
         {
            glDrawArrays(sgOpenglType[element.mPrimType], 0, element.mCount );
            gCurrStats.record(element.mCount, NME_GL_STATS_DRAW_ARRAYS);
         }
      }

      if (lastProg)
        lastProg->disableSlots();

      if (inData.mVertexBo || rebindVboNext)
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




};



// ----------------------------------------------------------------------------



#ifdef HX_WINDOWS
static HMODULE gEGLLibraryHandle = 0;
static HMODULE gOGLLibraryHandle = 0;
typedef PROC (*wglGetProcAddressFunc)(const char * unnamedParam1);
wglGetProcAddressFunc dynamicWglGetProcAddress = nullptr;
wglGetProcAddressFunc dynamicEglGetProcAddress = nullptr;
#else
//static void * gEGLLibraryHandle = 0;
static void * gOGLLibraryHandle = 0;
#endif

static bool extentions_init = false;


void *GetGlFunction(const char *functionName)
{
   void *result = nullptr;
   #if defined(NME_DYNAMIC_ANGLE)
      #ifdef HX_WINDOWS
      if (!result && dynamicEglGetProcAddress)
      {
         result = dynamicEglGetProcAddress(functionName);
      }
      if (!result && dynamicWglGetProcAddress)
      {
         result = dynamicWglGetProcAddress(functionName);
      }
      if (!result && gOGLLibraryHandle)
      {
         result = (void *)GetProcAddress(gOGLLibraryHandle,functionName);
      }
      //if (!result)
      //   printf("Could not get %p/%p %s\n", dynamicWglGetProcAddress, dynamicEglGetProcAddress ,functionName);
      #endif
   #elif defined(NME_ANGLE)
      //result = (void *)eglGetProcAddress(functionName);
      result = nullptr;
   #elif defined(HX_WINDOWS)
      result = (void *)wglGetProcAddress(functionName);
      if (!result && gOGLLibraryHandle)
         result = (void *)GetProcAddress(gOGLLibraryHandle,functionName);
   #elif defined(ANDROID)
      result = (void *)eglGetProcAddress(functionName);
   #elif defined(HX_LINUX)
      result = dlsym(nme::gOGLLibraryHandle,functionName);
   #endif

   return result;
}

// Loads eglGetProcAddress, if wanted by nmeEglMode.
// Otherwise sets up to load opengl32
bool InitDynamicGLES()
{
   static bool isinit = false;
   if (!isinit)
   {
      isinit = true;

      #ifdef NME_DYNAMIC_ANGLE
      if (nmeEglMode)
      {
         #ifdef HX_WINDOWS
         gEGLLibraryHandle = LoadLibraryA("libEGL.dll");
         if (!gEGLLibraryHandle)
         {
            fprintf(stderr,"ERROR: Could not open libEGL\n");
            nmeEglMode = false;
         }
         else
         {
            dynamicEglGetProcAddress = (wglGetProcAddressFunc)GetProcAddress(gEGLLibraryHandle, "eglGetProcAddress");
         }
         #endif

         if (dynamicEglGetProcAddress)
            return true;
      }
      #endif

      #ifdef HX_WINDOWS
      gOGLLibraryHandle = LoadLibraryA("opengl32.dll");
      if (!gOGLLibraryHandle)
      {
         printf("Error - could not load hardware driver\n");
         return false;
      }

      dynamicWglGetProcAddress = (wglGetProcAddressFunc)GetProcAddress(gOGLLibraryHandle, "wglGetProcAddress");
      if (!dynamicWglGetProcAddress)
      {
         printf("Error - could not load hardware interface\n");
         return false;
      }
      #endif
   }

   #ifdef HX_WINDOWS
   return dynamicEglGetProcAddress;
   #else
   return false;
   #endif
}

bool InitOGLFunctions()
{
   static bool result = true;
   if (!extentions_init)
   {
      extentions_init = true;

      InitDynamicGLES();


      #ifdef HX_LINUX
      if (!gOGLLibraryHandle)
      {
         gOGLLibraryHandle = dlopen("libGL.so.1", RTLD_NOW|RTLD_GLOBAL);
         if (!gOGLLibraryHandle)
            gOGLLibraryHandle = dlopen("libGL.so", RTLD_NOW|RTLD_GLOBAL);
      }
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

extern "C" {
   void nmeInitOGLFunctions() { nme::InitOGLFunctions(); }
}

