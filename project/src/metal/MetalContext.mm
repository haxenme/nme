#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <Hardware.h>
#include <HardwareImpl.h>
#include <simd/simd.h>

#ifdef NME_SDL2
#include <SDL.h>
#endif


#if !defined(_STRINGIFY)
#define __STRINGIFY( _x )   # _x
#define _STRINGIFY( _x )   __STRINGIFY( _x )
#endif

// Extra bit for 'fan' type
#define PROG_FAN PROG_COUNT
#define TOTAL_PROGS (PROG_COUNT*2)

namespace nme
{
#ifdef NME_SDL2
void *GetMetalLayerFromRenderer(SDL_Renderer *renderer)
{
   const CAMetalLayer *swapchain = (__bridge CAMetalLayer *)SDL_RenderGetMetalLayer(renderer);
   return (void *)swapchain;
}
#endif

typedef NSString *(^StringifyArrayOfIncludes)(NSArray <NSString *> *includes);
static NSString *(^stringifyHeaderFileNamesArray)(NSArray <NSString *> *) = ^(NSArray <NSString *> *includes) {
    NSMutableString *importStatements = [NSMutableString new];
    [includes enumerateObjectsUsingBlock:^(NSString * _Nonnull include, NSUInteger idx, BOOL * _Nonnull stop) {
        [importStatements appendString:@"#include <"];
        [importStatements appendString:include];
        [importStatements appendString:@">\n"];
    }];

    return [NSString new];
};

typedef NSString *(^StringifyArrayOfHeaderFileNames)(NSArray <NSString *> *headerFileNames);
static NSString *(^stringifyIncludesArray)(NSArray *) = ^(NSArray *headerFileNames) {
    NSMutableString *importStatements = [NSMutableString new];
    [headerFileNames enumerateObjectsUsingBlock:^(NSString * _Nonnull headerFileName, NSUInteger idx, BOOL * _Nonnull stop) {
        [importStatements appendString:@"#import "];
        [importStatements appendString:@_STRINGIFY("")];
        [importStatements appendString:headerFileName];
        [importStatements appendString:@_STRINGIFY("")];
        [importStatements appendString:@"\n"];
    }];

    return [NSString new];
};

const char *shaderHead = 
         "#import <metal_stdlib>\n"
         "#include <simd/simd.h>\n"

         "using namespace metal;\n";

const char *shaderFrag = 
         "struct RasterizerData\n"
         "{\n"
         "    float4 position [[position]];\n"
         "    float4 colour;\n"
         "};\n"

        "fragment float4 fragmentShader(RasterizerData in [[stage_in]])\n"
        "{\n"
        "    // Return the interpolated colour.\n"
        "    return in.colour;\n"
        "}\n"

        "vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],\n"
        "    constant float2 *vertices [[buffer(0)]],\n"
        "    constant Uniforms *uniforms [[buffer(1)]]\n"
        ;

const char *shaderTop = 
         ")\n"
         "{\n"
         "   RasterizerData out;\n";

const char *shaderTail = 
         "   vector_float4 pos(vertices[vertexID].x, vertices[vertexID].y, 0.0, 1.0);\n"
         "   out.position.x = dot(pos,uniforms->trans[0]);\n"
         "   out.position.y = dot(pos,uniforms->trans[1]);\n"
         "   out.position.z = 0;\n"
         "   out.position.w = 1;\n"

         "   out.colour = uniforms->colour;\n"

         "   return out;\n"
         "}\n";


static float one_on_255 = 1.0/255.0;
struct MetalProgram
{
   id<MTLRenderPipelineState> pipelineState;
   std::vector<uint8> uniformBuf;

   int vertexSlot;
   int uniformSlot;
   int textureSlot;
   int normalSlot;
   int colourSlot;

   int matrixOffset;
   int tintOffset;

   MetalProgram(id<MTLDevice> device, MTLPixelFormat pixelFormat, unsigned int progId)
      : pipelineState(nil)
   {
      vertexSlot = textureSlot = normalSlot = colourSlot = -1;
      matrixOffset = tintOffset = -1;

      std::string uniformDef = "typedef struct _uniforms {\n"
                               "  vector_float4 trans[4];\n";

      vertexSlot = 0;
      uniformSlot = 1;
      matrixOffset = 0;
      uniformBuf.resize( uniformBuf.size() + sizeof(Trans4x4) );

      if (progId & PROG_TINT)
      {
         tintOffset = (int)uniformBuf.size();
         uniformBuf.resize( uniformBuf.size() + sizeof(float)*4 );
         uniformDef += "  vector_float4 colour;\n";
      }

      uniformDef += "} Uniforms;\n";

      std::string shader = shaderHead;
      shader += uniformDef;
      shader += shaderFrag;
      shader += shaderTop;

      // Fan
      if (progId & PROG_FAN)
      {
         // Remap vertexID sequence to 0,1,2, 0,2,3, 0,3,4, 0,4,5 ...
         //                         =  0,1,2, 0,1,2, 0,1,2, 0,1,2 ...
         //                         +  0,0,0, 0,1,1, 0,2,2, 0,3,3, ...
         shader += "    int tri=vertexID/3;\n"
                   "    int corner=vertexID-tri*3;\n"
                   "    vertexID = corner + min(corner,(int)1) * tri;\n";
      }

      shader += shaderTail;

      __autoreleasing NSError *error = nil;

      NSString* librarySrc = [NSString stringWithCString:shader.c_str() encoding:[NSString defaultCStringEncoding]];

      id<MTLLibrary> lib  = [device newLibraryWithSource:librarySrc options:nil error:&error];
      if(!lib) {
          [NSException raise:@"Failed to compile shaders" format:@"%@", [error localizedDescription]];
      }

      id<MTLFunction> vertexFunction = [lib newFunctionWithName:@"vertexShader"];
      id<MTLFunction> fragmentFunction = [lib newFunctionWithName:@"fragmentShader"];

      MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
      pipelineStateDescriptor.label = @"Pipeline";
      pipelineStateDescriptor.vertexFunction = vertexFunction;
      pipelineStateDescriptor.fragmentFunction = fragmentFunction;
      pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat;

      pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
   }

   ~MetalProgram() {}


   void setTransform(const Trans4x4 &inTrans)
   {
      memcpy(&uniformBuf[matrixOffset], &inTrans, sizeof(Trans4x4));
   }

   void setColourTransform(const ColorTransform *inTransform, unsigned int inColour,
                                    bool inPremultiplyAlpha)
   {
      if (tintOffset>=0)
      {
         float *dest = (float *)&uniformBuf[tintOffset];
         if (inColour==0xffffffff)
         {
            *dest++ = 1.0;
            *dest++ = 1.0;
            *dest++ = 1.0;
            *dest++ = 1.0;
         }
         else
         {
            *dest++ = ( (inColour>>16) & 0xff ) * one_on_255;
            *dest++ = ( (inColour>>8 ) & 0xff ) * one_on_255;
            *dest++ = ( (inColour    ) & 0xff ) * one_on_255;
            *dest++ = ( (inColour>>24) & 0xff ) * one_on_255;
         }
      }
   }
   void setGradientFocus(float inFocus);

   void bindUniforms(id<MTLRenderCommandEncoder> renderEncoder)
   {
      [renderEncoder setVertexBytes:&uniformBuf[0]  length:uniformBuf.size()  atIndex:uniformSlot];
   }

};



static  MTLPrimitiveType sgMetalType[] = {
        MTLPrimitiveTypeTriangle, // Fan
        MTLPrimitiveTypeTriangleStrip,
        MTLPrimitiveTypeTriangle,
        MTLPrimitiveTypeLineStrip,
        MTLPrimitiveTypePoint,
        MTLPrimitiveTypeLine,

        MTLPrimitiveTypeTriangle, // Quad
        MTLPrimitiveTypeTriangle // Quad - full
};

class MetalContext : public HardwareRenderer
{
   MTLRenderPassDescriptor *pass;
   CAMetalLayer *swapchain;
   id<MTLDevice> _device;
   id<MTLCommandQueue> queue;
   id<MTLCommandBuffer> commandBuffer;
   id<MTLRenderCommandEncoder> renderEncoder;
   #ifndef OBJC_ARC
   NSAutoreleasePool *pool;// = [[NSAutoreleasePool alloc] init];
   #endif
   id<CAMetalDrawable> surface;
   //id<CAMetalDrawable> surface = [swapchain nextDrawable];
   int frame;

   int width,height;
   bool first;

   MetalProgram *allPrograms[TOTAL_PROGS];


public:

   MetalContext(void *inCAMetalLayer) :
      swapchain(0),
      _device(nil),
      queue(nil),
      commandBuffer(nil),
      renderEncoder(nil),
      surface(nullptr)
   {
     frame = 0;
     swapchain = (__bridge CAMetalLayer *)inCAMetalLayer;
     _device = swapchain.device;
     queue =  [_device newCommandQueue];
     width = height = 0;
     for(int i=0;i<TOTAL_PROGS;i++)
        allPrograms[i] = nullptr;
   }

   void OnContextLost()
   {
   }

   bool IsOpenGL() const { return false; }

   Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags)
   {
      return 0;
   }

   // Could be common to multiple implementations...

   void SetWindowSize(int inWidth,int inHeight)
   {
      width = inWidth;
      height = inHeight;
   }
   void SetQuality(StageQuality inQuality)
   {
   }
   void BeginRender(const Rect &inRect,bool inForHitTest)
   {
      #ifndef OBJC_ARC
      pool = [[NSAutoreleasePool alloc] init];
      #endif
      surface = [swapchain nextDrawable];

      MTLClearColor colour = MTLClearColorMake(0, 0, 0, 1);

      pass = [MTLRenderPassDescriptor renderPassDescriptor];
      //pass.colorAttachments[0].clearColor = colour;
      pass.colorAttachments[0].loadAction  = MTLLoadActionClear;
      pass.colorAttachments[0].storeAction = MTLStoreActionStore;
      pass.colorAttachments[0].texture = surface.texture;
      first = true;

   }
   void EndRender()
   {
      [renderEncoder endEncoding];
      [commandBuffer presentDrawable:surface];
      [commandBuffer commit];
      commandBuffer = nil;

      surface=nil;
      renderEncoder = nil;
      #ifndef OBJC_ARC
      [pool drain];
      pool = nullptr;
      #endif
   }
   void SetViewport(const Rect &inRect)
   {
      setOrtho(inRect.x,inRect.x1(), inRect.y1(),inRect.y);
      // Set the region of the drawable to draw into.
      [renderEncoder setViewport:(MTLViewport){inRect.x, inRect.y, inRect.w, inRect.h, 0.0, 1.0 }];
   }
   void Clear(uint32 inColour,const Rect *inRect=0)
   {
      MTLClearColor colour = MTLClearColorMake(
         ((inColour>>16)&0xff)/255.0,
         ((inColour>>8)&0xff)/255.0,
         ((inColour)&0xff)/255.0,
         1);
      pass.colorAttachments[0].clearColor = colour;
      commandBuffer = [queue commandBuffer];
      renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:pass];
   }
   void Flip() {  }

   int Width() const { return width; }
   int Height() const { return height; }


   void RenderData(const HardwareData &inData, const ColorTransform *ctrans,const Trans4x4 &inTrans)
   {
      const uint8 *data = inData.mArray.size()>0 ? &inData.mArray[0] : nullptr;
      MetalProgram *lastProg = nullptr;
      for(int e=0;e<inData.mElements.size();e++)
      {
         const DrawElement &element = inData.mElements[e];
         int n = element.mCount;
         if (!n)
            continue;


         bool premAlpha;
         unsigned progId = getProgId(element, ctrans, premAlpha);
         if (element.mPrimType==ptTriangleFan)
            progId |= PROG_FAN;

         bool persp = element.mFlags & DRAW_HAS_PERSPECTIVE;

         switch(element.mBlendMode)
         {
            case bmAdd:
               break;
            case bmMultiply:
               break;
            case bmScreen:
               break;
            default:
               ;
         }

         bool uniformsDirty = false;
         MetalProgram *prog = allPrograms[progId];
         if (!prog)
            prog = allPrograms[progId] = new MetalProgram(_device, swapchain.pixelFormat, progId);


         if (prog!=lastProg)
         {
            [renderEncoder setRenderPipelineState:prog->pipelineState];
            prog->setTransform(inTrans);
            uniformsDirty = true;
         }
         lastProg = prog;

         [renderEncoder setVertexBytes:data  + element.mVertexOffset
                              length:n*2*sizeof(float)
                              atIndex:prog->vertexSlot];


         if (progId & (PROG_TINT | PROG_COLOUR_OFFSET) )
         {
            prog->setColourTransform(ctrans, element.mColour, premAlpha );
            uniformsDirty = true;
         }

         if (uniformsDirty)
            prog->bindUniforms(renderEncoder);

         if (element.mPrimType==ptTriangleFan)
            n = (n-2)*3;
         [renderEncoder drawPrimitives:sgMetalType[element.mPrimType] vertexStart:0 vertexCount:n];
      }
   }

   void BeginDirectRender() { }
   void EndDirectRender() { }
};


HardwareRenderer *HardwareRenderer::CreateMetal(void *inLayer)
{
   HardwareRenderer *ctx = new MetalContext(inLayer);

   return ctx;
}


} // end namespace nme



