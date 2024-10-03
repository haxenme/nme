#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <Hardware.h>
#include <HardwareImpl.h>
#include <simd/simd.h>
#include <vector>

#ifdef NME_SDL2
#include <SDL.h>
#endif


#if !defined(_STRINGIFY)
#define __STRINGIFY( _x )   # _x
#define _STRINGIFY( _x )   __STRINGIFY( _x )
#endif

// Extra bit for 'geom' type
#define WHOLE_TEXTURE (PROG_COUNT*0x01)
#define SMOOTH_TEXTURE (PROG_COUNT*0x02)
#define REPEAT_TEXTURE (PROG_COUNT*0x04)

#define GEOM_BASE (PROG_COUNT*0x08)

#define GEOM_NORMAL 0
#define GEOM_FAN    1
#define GEOM_QUAD   2
#define TOTAL_PROGS (GEOM_BASE*3)

namespace nme
{



static const double one_on_256 = 1.0/256.0;


struct MetalTexture : public Texture
{
   int width,height;
   id<MTLTexture> tex;
   Rect dirtyRect;
   Surface *surface;
   int bpp;
   bool conversionRequired;

   MetalTexture(id<MTLDevice> inDevice, Surface *inSurface, unsigned int inFlags)
   {
      surface = inSurface;
      width = inSurface->Width();
      height = inSurface->Height();
      conversionRequired = false;
      bpp = 0;
      @autoreleasepool {
         MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
         // Indicate that each pixel has a blue, green, red, and alpha channel, where each channel is
         // an 8-bit unsigned normalized value (i.e. 0 maps to 0.0 and 255 maps to 1.0)
         switch(surface->Format())
         {
            case pfRGB: 
               textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
               conversionRequired = true;
               bpp = 3;
               break;
            case pfBGRA: 
            case pfBGRPremA: 
               textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
               bpp = 4;
               break;
            case pfAlpha: 
               textureDescriptor.pixelFormat = MTLPixelFormatA8Unorm;
               bpp = 1;
               break;
            case pfARGB4444: 
               conversionRequired = true;
               bpp = 2;
               //textureDescriptor.pixelFormat = MTLPixelFormatABGR4Unorm;
               textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
               break;
            case pfRGB565: 
               //textureDescriptor.pixelFormat = MTLPixelFormatB5G6R5Unorm;
               textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
               conversionRequired = true;
               bpp = 2;
               break;
            case pfLuma: 
               textureDescriptor.pixelFormat = MTLPixelFormatR8Unorm;
               bpp = 1;
               break;
            case pfLumaAlpha: 
               textureDescriptor.pixelFormat = MTLPixelFormatRG8Unorm;
               bpp = 2;
               break;

            default:
               textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
               conversionRequired = true;
               bpp = BytesPerPixel(surface->Format());
         }


         // Set the pixel dimensions of the texture
         textureDescriptor.width = width;
         textureDescriptor.height = height;

         if (inFlags & surfMipmaps)
         {
            int heightLevels = ceil(log2(height));
            int widthLevels = ceil(log2(width));
            int mipCount = (heightLevels > widthLevels) ? heightLevels : widthLevels;

            textureDescriptor.mipmapLevelCount = mipCount;
         }


         // Create the texture from the device by using the descriptor
         tex = [inDevice newTextureWithDescriptor:textureDescriptor];
      }
      dirtyRect = Rect(0,0,width,height);

   }
   ~MetalTexture()
   {
   }

   void update()
   {
      if (dirtyRect.HasPixels())
      {
         MTLRegion region = {
           { (NSUInteger)dirtyRect.x, (NSUInteger)dirtyRect.y, 0 },       // MTLOrigin
           { (NSUInteger)dirtyRect.w,  (NSUInteger)dirtyRect.h, 1} // MTLSize
         };
         NSUInteger bytesPerRow = width*bpp;
         if (conversionRequired)
         {
            const uint8 *p0 = surface->Row(dirtyRect.y) + dirtyRect.x*bpp;
            std::vector<uint8> buf(dirtyRect.w*dirtyRect.h*4);
            PixelConvert(dirtyRect.w,dirtyRect.h,
                            surface->Format(), p0, surface->GetStride(), surface->GetPlaneOffset(),
                            pfBGRPremA, &buf[0], dirtyRect.w*4, dirtyRect.w*dirtyRect.h*4 );

            [tex replaceRegion:region
               mipmapLevel:0
               withBytes:&buf[0]
               bytesPerRow:dirtyRect.w*4];
         }
         else
         {
            [tex replaceRegion:region
               mipmapLevel:0
               withBytes:surface->GetBase() + dirtyRect.y*bytesPerRow + dirtyRect.x*bpp
               bytesPerRow:bytesPerRow];
         }

         dirtyRect = Rect();
      }
   }

   UserPoint PixelToTex(const UserPoint &inPixels)
   {
      return UserPoint(inPixels.x/width, inPixels.y/height);
   }

   UserPoint TexToPaddedTex(const UserPoint &inPixels)
   {
      // Not padded
      return inPixels;
   }

   int GetWidth() { return width; }
   int GetHeight() { return height; }

   void Bind(int inSlot)
   {
      update();
   }

   void BindFlags(bool inRepeat,bool inSmooth)
   {
   }

   void Dirty(const Rect &inRect)
   {
      if (!dirtyRect.HasPixels())
         dirtyRect = inRect;
      else
         dirtyRect = dirtyRect.Union(inRect);
   }

   bool IsCurrentVersion() { return true; }
};


const char *shaderHead = 
         "#import <metal_stdlib>\n"
         "#include <simd/simd.h>\n"

         "using namespace metal;\n";


const char *vertexShader = 
        "vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],\n"
        "    constant VertexData *vertexData [[buffer(0)]],\n"
        "    constant Uniforms *uniforms [[buffer(1)]] ) {\n"
        "   RasterizerData out;\n";

const char *shaderPos = 
         "   vector_float4 pos(vertexData[vertexID].pos.x, vertexData[vertexID].pos.y, 0.0, 1.0);\n"
         "   out.position.x = dot(pos,uniforms->trans[0]);\n"
         "   out.position.y = dot(pos,uniforms->trans[1]);\n"
         "   out.position.z = 0;\n"
         "   out.position.w = 1;\n";


const char *shaderPos4D = 
         "   vector_float4 pos;\n"
         "   pos.xy = vertexData[vertexID].posA;\n"
         "   pos.zw = vertexData[vertexID].posB;\n"
         "   out.position = pos * uniforms->trans;\n";

const char *shaderTail = 
         "   return out;\n"
         "}\n";

enum
{
   VERTEX_SLOT = 0,
   UNIFORM_SLOT = 1,
   FRAG_UNIFORM_SLOT = 0,
};

static float one_on_255 = 1.0/255.0;
struct MetalProgram
{
   id<MTLRenderPipelineState> pipelineState;
   std::vector<uint8> uniformBuf;

   int matrixOffset;
   int tintSlot;
   int colourOffsetSlot;
   int focusOffset;
   int stride;

   MetalProgram(id<MTLDevice> device, MTLPixelFormat pixelFormat, unsigned int progId)
      : pipelineState(nil)
   {
      matrixOffset = tintSlot = focusOffset = colourOffsetSlot = -1;

      std::string shader = shaderHead;

      bool wholeTexture = progId & WHOLE_TEXTURE;
      int geom = progId/(GEOM_BASE);

      // RasterizerData - passed from frag to pixel
      shader +=
         "struct RasterizerData\n"
         "{\n"
         "    float4 position [[position]];\n";
      if (progId & (PROG_TINT | PROG_COLOUR_PER_VERTEX ) )
         shader += "   float4 colour;\n";
      if (progId & PROG_NORMAL_DATA)
         shader += "   float2 norm;\n";
      if ( progId & PROG_TEXTURE )
         shader += "    float2 rtex;\n";
      shader += "};\n";


      // Uniform data - same for each vertex/pixel
      shader += "typedef struct _uniforms {\n"
                "  matrix_float4x4 trans;\n";
      matrixOffset = 0;
      uniformBuf.resize( uniformBuf.size() + sizeof(Trans4x4) );
      if (progId & PROG_TINT)
      {
         tintSlot = (int)uniformBuf.size();
         uniformBuf.resize( uniformBuf.size() + sizeof(float)*4 );
         shader += "  vector_float4 colour;\n";
      }

      if (progId & PROG_COLOUR_OFFSET)
      {
         colourOffsetSlot = (int)uniformBuf.size();
         uniformBuf.resize( uniformBuf.size() + sizeof(float)*4 );
         shader += "  vector_float4 colourOffset;\n";
      }

      if (progId & PROG_RADIAL_FOCUS)
      {
         focusOffset = (int)uniformBuf.size();
         uniformBuf.resize( uniformBuf.size() + sizeof(float)*3 );
         shader +=
            "  float mA;\n"
            "  float mFX;\n"
            "  float mOn2A;\n";
       }

      shader += "} Uniforms;\n";

      // VertexData
      stride = sizeof(float)*( (progId & PROG_4D_INPUT) ? 4 : 2 );
      shader +=
         "struct VertexData\n"
         "{\n";
      if (progId & PROG_4D_INPUT)
      {
         shader += "   float2 posA;\n";
         shader += "   float2 posB;\n";
      }
      else
         shader += "   float2 pos;\n";


      if (progId & PROG_NORMAL_DATA)
      {
         shader += "   float2 norm;\n";
         stride += sizeof(float)*2;
      }

      if ((progId & PROG_TEXTURE) && !wholeTexture)
      {
         shader += "   float2 tex;\n";
         stride += sizeof(float)*2;
      }

      if (progId & PROG_COLOUR_PER_VERTEX)
      {
        #ifdef NME_FLOAT32_VERT_VALUES
         shader += "   float4 vcol;\n";
         stride += sizeof(float)*4;
        #else
         shader += "   uchar4 vcol;\n";
         shader += "   uchar4 pad;\n";
         stride += sizeof(float)*2;
        #endif
      }

      shader += "};\n";


      if ( progId & PROG_TEXTURE )
      {
         if (progId & (PROG_RADIAL_FOCUS|PROG_COLOUR_OFFSET) )
            shader += 
                "fragment float4 fragmentShader(RasterizerData in [[stage_in]],\n"
                   " texture2d<float> colourTexture [[ texture(0) ]],\n"
                   " constant Uniforms *uniforms [[buffer(0)]] )\n"
                "{\n";
        else
            shader += 
                "fragment float4 fragmentShader(RasterizerData in [[stage_in]],\n"
                   " texture2d<float> colourTexture [[ texture(0) ]])\n"
                "{\n";

         if (progId & REPEAT_TEXTURE)
         {
            if (progId & SMOOTH_TEXTURE)
               shader += " constexpr sampler textureSampler(address::repeat,mag_filter::linear, min_filter::linear);\n";
            else
               shader += " constexpr sampler textureSampler(address::repeat,mag_filter::nearest, min_filter::nearest);\n";
         }
         else
         {
            if (progId & SMOOTH_TEXTURE)
               shader += " constexpr sampler textureSampler(address::clamp_to_edge,mag_filter::linear, min_filter::linear);\n";
            else
               shader += " constexpr sampler textureSampler(address::clamp_to_edge,mag_filter::nearest, min_filter::nearest);\n";
         }



         if (false)
            shader += "    float4 col = float4( in.rtex.x, in.rtex.y, 0, 1);\n";
         else if (progId & PROG_RADIAL)
         {
            if (progId & PROG_RADIAL_FOCUS)
            {
               shader += 
                  "   float GX = in.rtex.x - uniforms->mFX;\n"
                  "   float C = GX*GX + in.rtex.y*in.rtex.y;\n"
                  "   float B = 2.0*GX * uniforms->mFX;\n"
                  "   float det =B*B - uniforms->mA*C;\n"
                  "   float radius;\n"
                  "   if (det<0.0)\n"
                  "      radius = -B * uniforms->mOn2A;\n"
                  "   else\n"
                  "      radius = (-B - sqrt(det)) * uniforms->mOn2A;\n";
            }
            else
            {
               shader += 
                  "   float radius = sqrt(in.rtex.x*in.rtex.x + in.rtex.y*in.rtex.y);\n";
            }
            shader += "    float4 col = colourTexture.sample(textureSampler, radius);\n";
         }
         else if (progId & PROG_ALPHA_TEXTURE)
         {
            shader += "    float4 col = float4(1,1,1,colourTexture.sample(textureSampler, in.rtex).a);\n";
         }
         else
            shader += "    float4 col = colourTexture.sample(textureSampler, in.rtex);\n";

         if (progId & (PROG_TINT | PROG_COLOUR_PER_VERTEX) )
            shader += "   col *= in.colour;\n";
      }
      else
      {
         if (progId & PROG_COLOUR_OFFSET)
            shader += "fragment float4 fragmentShader(RasterizerData in [[stage_in]],"
                       " constant Uniforms *uniforms [[buffer(0)]] ) {\n";
         else
            shader += "fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {\n";

         if (progId&(PROG_COUNT-1)&~(PROG_NORMAL_DATA))
            shader += "    float4 col = in.colour;\n";
         else
            shader += "    float4 col = float4(1,1,1,1);\n";
      }

      if ( progId & PROG_COLOUR_OFFSET )
         shader += "   col += uniforms->colourOffset;\n";

      if (progId&PROG_NORMAL_DATA)
         shader += "   col *= min(in.norm.x-abs(in.norm.y),1.0);";

      shader += 
        "    return col;\n"
        "}\n";

      shader += vertexShader;
      // Fan
      if (geom==GEOM_FAN)
      {
         // Remap vertexID sequence to 0,1,2, 0,2,3, 0,3,4, 0,4,5 ...
         //                         =  0,1,2, 0,1,2, 0,1,2, 0,1,2 ...
         //                         +  0,0,0, 0,1,1, 0,2,2, 0,3,3, ...
         shader += "    int tri=vertexID/3;\n"
                   "    int corner=vertexID-tri*3;\n"
                   "    vertexID = corner + min(corner,(int)1) * tri;\n";
      }
      else if (geom==GEOM_QUAD)
      {
         // 0 - 1    012345 - 012,321
         // | / |
         // 2 - 3
         // Remap vertexID sequence to 0,1,2, 3,2,1, 4,5,6, 7,6,5, ...
         //                         =  0,1,2, 3,2,1, 0,1,2, 3,2,1 ...
         //                         +  0,0,0, 0,0,0, 4,4,4, 4,4,4, ...
         shader += "    int quad=vertexID/6;\n"
                   "    int corner=vertexID-quad*6;\n"
                   "    if (corner>2) corner=6-corner;\n"
                   "    vertexID = corner + (quad<<2);\n";

         if (wholeTexture)
            shader += "   out.rtex = float2( corner&1, corner>1 );\n";
      }

      if (progId & PROG_4D_INPUT)
         shader += shaderPos4D;
      else
         shader += shaderPos;

      if (progId & PROG_NORMAL_DATA)
      {
         shader += "   out.norm = vertexData[vertexID].norm;\n";
      }
      if ( (progId & PROG_TEXTURE) && !wholeTexture )
      {
         shader += "   out.rtex = vertexData[vertexID].tex;\n";
      }
      if (progId & PROG_TINT)
      {
         shader += "   out.colour = uniforms->colour;\n";
      }
      if (progId & PROG_COLOUR_PER_VERTEX)
      {
         #ifdef NME_FLOAT32_VERT_VALUES
         shader += "   out.colour = vertexData[vertexID].vcol;\n";
         #else
         shader += "   out.colour = float4(vertexData[vertexID].vcol)/255.0;\n";
         #endif
      }


      shader += shaderTail;



      __autoreleasing NSError *error = nil;

      NSString* librarySrc = [NSString stringWithCString:shader.c_str() encoding:[NSString defaultCStringEncoding]];

      id<MTLLibrary> lib  = [device newLibraryWithSource:librarySrc options:nil error:&error];
      if(!lib) {
          printf("Shader compile failed: %x whole=%d\n%s\n\n",progId, wholeTexture, shader.c_str() );
          [NSException raise:@"Failed to compile shaders" format:@"%@", [error localizedDescription]];
      }

      id<MTLFunction> vertexFunction = [lib newFunctionWithName:@"vertexShader"];
      id<MTLFunction> fragmentFunction = [lib newFunctionWithName:@"fragmentShader"];

      MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
      pipelineStateDescriptor.label = @"Pipeline";
      pipelineStateDescriptor.vertexFunction = vertexFunction;
      pipelineStateDescriptor.fragmentFunction = fragmentFunction;
      pipelineStateDescriptor.colorAttachments[0].pixelFormat = pixelFormat;

      MTLRenderPipelineColorAttachmentDescriptor *blend = pipelineStateDescriptor.colorAttachments[0];
      blend.blendingEnabled = YES;
      blend.rgbBlendOperation = MTLBlendOperationAdd;
      blend.alphaBlendOperation = MTLBlendOperationAdd;

      blend.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
      blend.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

      //glBlendFunc(premAlpha ? GL_ONE : GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
      if (progId & PROG_PREM_ALPHA)
      {
         blend.sourceRGBBlendFactor = MTLBlendFactorOne;
         blend.sourceAlphaBlendFactor = MTLBlendFactorOne;
         //blend.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
      }
      else
      {
         blend.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
         blend.sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
      }

      pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
   }

   ~MetalProgram() {}


   void setTransform(const Trans4x4 &inTrans)
   {
      memcpy(&uniformBuf[matrixOffset], &inTrans, sizeof(Trans4x4));
      //for(int y=0;y<4;y++)
         //printf("%d]  %f %f %f %f\n",y, inTrans[y][0], inTrans[y][1], inTrans[y][2], inTrans[y][3] );
      //printf("---\n");
   }

   void setGradientFocus(float inFocus)
   {
      if (focusOffset>=0)
      {
         double fx = inFocus;
         if (fx < -0.99)
            fx = -0.99;
         else if (fx > 0.99)
            fx = 0.99;

         // mFY = 0; mFY can be set to zero, since rotating the matrix
         //  can also compensate for this.

         double a = (fx * fx - 1.0);
         double on2a = 1.0 / (2.0 * a);
         a *= 4.0;

         float *uni = (float *)&uniformBuf[focusOffset];
         uni[0] = a;
         uni[1] = fx;
         uni[2] = on2a;
      }
   }

   void setColourTransform(const ColorTransform *inTransform, unsigned int inColour,
                                    bool inPremultiplyAlpha)
   {
      if (inTransform && !inTransform->IsIdentity())
      {
          if (colourOffsetSlot>=0)
          {
             float *dest = (float *)&uniformBuf[colourOffsetSlot];
             if (inPremultiplyAlpha)
             {
                dest[0] = inTransform->redOffset*one_on_255*inTransform->alphaMultiplier;
                dest[1] = inTransform->greenOffset*one_on_255*inTransform->alphaMultiplier;
                dest[2] = inTransform->blueOffset*one_on_255*inTransform->alphaMultiplier;
                dest[3] = inTransform->alphaOffset*one_on_255;
             }
             else
             {
                dest[0] = inTransform->redOffset*one_on_255;
                dest[1] = inTransform->greenOffset*one_on_255;
                dest[2] = inTransform->blueOffset*one_on_255;
                dest[3] = inTransform->alphaOffset*one_on_255;
             }
          }

          if (tintSlot>=0)
          {
             float rf, gf, bf, af;
             if (inColour==0xffffffff)
             {
                rf = gf = bf = af = 1.0;
             }
             else
             {
                rf = ( (inColour>>16) & 0xff ) * one_on_255;
                gf = ( (inColour>>8 ) & 0xff ) * one_on_255;
                bf = ( (inColour    ) & 0xff ) * one_on_255;
                af = ( (inColour>>24) & 0xff ) * one_on_255;
             }

             float *dest = (float *)&uniformBuf[tintSlot];
             if (inPremultiplyAlpha)
             {
                dest[0] = inTransform->redMultiplier * inTransform->alphaMultiplier * rf;
                dest[1] = inTransform->greenMultiplier * inTransform->alphaMultiplier * gf;
                dest[2] = inTransform->blueMultiplier * inTransform->alphaMultiplier * bf;
                dest[3] = inTransform->alphaMultiplier * af;
             }
             else
             {
                dest[0] = inTransform->redMultiplier * rf;
                dest[1] = inTransform->greenMultiplier * gf;
                dest[2] = inTransform->blueMultiplier * bf;
                dest[3] = inTransform->alphaMultiplier * af;
             }
          }
      }
      else
      {
         if (colourOffsetSlot>=0)
         {
            float *dest = (float *)&uniformBuf[colourOffsetSlot];
            dest[0] = 0.0f;
            dest[1] = 0.0f;
            dest[2] = 0.0f;
            dest[3] = 0.0f;
         }

         if (tintSlot>=0)
         {
             float rf, gf, bf, af;
             if (inColour==0xffffffff)
             {
                rf = gf = bf = af = 1.0;
             }
             else
             {
                rf = ( (inColour>>16) & 0xff ) * one_on_255;
                gf = ( (inColour>>8 ) & 0xff ) * one_on_255;
                bf = ( (inColour    ) & 0xff ) * one_on_255;
                af = ( (inColour>>24) & 0xff ) * one_on_255;
             }

            float *dest = (float *)&uniformBuf[tintSlot];
            dest[0] = rf;
            dest[1] = gf;
            dest[2] = bf;
            dest[3] = af;
         }
      }
  }

   void bindUniforms(id<MTLRenderCommandEncoder> renderEncoder)
   {
      [renderEncoder setVertexBytes:&uniformBuf[0]  length:uniformBuf.size()  atIndex:UNIFORM_SLOT];
      if (focusOffset>=0)
         [renderEncoder setFragmentBytes:&uniformBuf[0]  length:uniformBuf.size()  atIndex:FRAG_UNIFORM_SLOT];
   }

};

static size_t totalBuffer = 0;
struct MetalBuffer
{
   id<MTLBuffer> buffer;
   int size;

   MetalBuffer(id<MTLDevice> device, const void *pointer, NSUInteger length)
   {
      size = (int)length;
      totalBuffer += length;
      buffer = [device newBufferWithBytes:pointer 
                             length:(NSUInteger)length 
                             options:MTLResourceCPUCacheModeWriteCombined ];
   }
   
   ~MetalBuffer()
   {
      #ifndef OBJC_ARC
      [buffer release];
      #endif

      buffer = nil;
      totalBuffer -= size;
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

struct VertexData
{
   float pos[2];
   float tex[2];
   uint8 vcol[4];
};

class MetalContext : public HardwareRenderer
{
   MTLRenderPassColorAttachmentDescriptor *colourBuf;
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

   MetalContext(CAMetalLayer *inCAMetalLayer) :
      swapchain(0),
      _device(nil),
      queue(nil),
      commandBuffer(nil),
      renderEncoder(nil),
      surface(nullptr)
   {
     frame = 0;
     swapchain = inCAMetalLayer;
     _device = swapchain.device;
     queue =  [_device newCommandQueue];
     width = height = 0;
     for(int i=0;i<TOTAL_PROGS;i++)
        allPrograms[i] = nullptr;
      colourBuf = nil;
   }

   void OnContextLost()
   {
   }

   bool IsOpenGL() const { return false; }

   Texture *CreateTexture(class Surface *inSurface, unsigned int inFlags)
   {
      return new MetalTexture(_device, inSurface, inFlags);
   }

   // Could be common to multiple implementations...

   void SetWindowSize(int inWidth,int inHeight)
   {
      width = inWidth;
      height = inHeight;
   }

   bool supportsComponentAlpha() const
   {
      return false;
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
      colourBuf = pass.colorAttachments[0];
      colourBuf.loadAction  = MTLLoadActionClear;
      colourBuf.storeAction = MTLStoreActionStore;
      colourBuf.texture = surface.texture;
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
      colourBuf = nil;
      #ifndef OBJC_ARC
      [pool drain];
      pool = nullptr;
      #endif
   }
   void SetViewport(const Rect &inRect)
   {
      setOrtho(inRect.x,inRect.x1(), inRect.y1(),inRect.y);
      // Set the region of the drawable to draw into.
      [renderEncoder setViewport:(MTLViewport){(double)inRect.x, (double)inRect.y, (double)inRect.w, (double)inRect.h, 0.0, 1.0 }];
   }
   void Clear(uint32 inColour,const Rect *inRect=0)
   {
      MTLClearColor colour = MTLClearColorMake(
         ((inColour>>16)&0xff)/255.0,
         ((inColour>>8)&0xff)/255.0,
         ((inColour)&0xff)/255.0,
         1);
      colourBuf.clearColor = colour;
      commandBuffer = [queue commandBuffer];
      renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:pass];
   }
   void Flip() {  }

   int Width() const { return width; }
   int Height() const { return height; }

   void DestroyVbo(unsigned int inVbo, void *inVboPtr)
   {
      MetalBuffer *buffer = (MetalBuffer *)inVboPtr;
      delete buffer;
   }

   void RenderData(const HardwareData &inData, const ColorTransform *ctrans,const Trans4x4 &inTrans)
   {
      unsigned int len = inData.mArray.size();
      const uint8 *data = len>0 ? &inData.mArray[0] : nullptr;
      MetalProgram *lastProg = nullptr;

      MetalBuffer *buffer = (MetalBuffer *)inData.mVertexBufferPtr;
      if (!buffer && len>4096)
      {
         buffer = new MetalBuffer(_device, data, len);
         inData.mVertexBufferPtr = buffer;
         inData.mVboOwner = this;
         inData.mContextId = gTextureContextVersion;
         IncRef();
      }
      if (buffer)
      {
         [renderEncoder setVertexBuffer:buffer->buffer offset:0 atIndex:VERTEX_SLOT];
      }

      for(int e=0;e<inData.mElements.size();e++)
      {
         const DrawElement &element = inData.mElements[e];
         int n = element.mCount;
         if (!n)
            continue;

         unsigned progId = getProgId(element, ctrans);
         bool premAlpha = progId & PROG_PREM_ALPHA;
         bool wholeTexture = element.mPrimType==ptQuadsFull;

         if (element.mPrimType==ptTriangleFan)
            progId += GEOM_FAN * GEOM_BASE;
         else if (element.mPrimType==ptQuads || element.mPrimType==ptQuadsFull)
            progId += GEOM_QUAD * GEOM_BASE;
         if (wholeTexture)
            progId |= WHOLE_TEXTURE;

         if ( progId & PROG_TEXTURE )
         {
            MetalTexture *tex = (MetalTexture *)element.mSurface->GetTexture(this,0);

            if (element.mFlags & DRAW_BMP_SMOOTH)
                progId |= SMOOTH_TEXTURE;
            if (element.mFlags & DRAW_BMP_REPEAT)
                progId |= REPEAT_TEXTURE;
            [renderEncoder setFragmentTexture: tex->tex atIndex:0];
         }

         bool uniformsDirty = false;
         MetalProgram *prog = allPrograms[progId];
         if (!prog)
         {
            prog = allPrograms[progId] = new MetalProgram(_device, swapchain.pixelFormat, progId);
            /*
            if (progId==0x2007)
            {
               int n2 = (n/4)*6;
               printf("-> quands %d -> \n", n, n2);
               VertexData *vd = (VertexData *)data;
               for(int i=0;i<n2;i++)
               {
                   int quad=i/6;
                   int corner=i-quad*6;
                   if (corner>2) corner=6-corner;
                   int v = corner + (quad<<2);
                  printf("%d:%d] %f,%f  %f,%f\n",i,v, vd[v].pos[0], vd[v].pos[1],vd[v].tex[0], vd[v].tex[1]);
               }
            }
            */
         }
         if (prog->stride!=element.mStride)
             printf("Bad stride %d!=%d  pid=%08x\n", prog->stride, element.mStride, progId );


         if (prog!=lastProg)
         {
            [renderEncoder setRenderPipelineState:prog->pipelineState];
            prog->setTransform(inTrans);
            uniformsDirty = true;
         }
         lastProg = prog;

         if (element.mSurface)
            element.mSurface->Bind(*this,0);


         // switch(element.mBlendMode) - part of pipeline

         if (buffer)
         {
            [renderEncoder setVertexBufferOffset:element.mVertexOffset atIndex:VERTEX_SLOT];
         }
         else
         {
            [renderEncoder setVertexBytes:data  + element.mVertexOffset
                              length:n*element.mStride
                              atIndex:VERTEX_SLOT];
         }

         if (progId & (PROG_TINT | PROG_COLOUR_OFFSET) )
         {
            prog->setColourTransform(ctrans, element.mColour, premAlpha );
            uniformsDirty = true;
         }

         if (element.mFlags & DRAW_RADIAL)
         {
            prog->setGradientFocus(element.mRadialPos * one_on_256);
            uniformsDirty = true;
         }


         if (uniformsDirty)
            prog->bindUniforms(renderEncoder);

         if (element.mPrimType==ptTriangleFan)
            n = (n-2)*3;
         else if (element.mPrimType==ptQuads || element.mPrimType==ptQuadsFull)
            n = (n/4)*6;

         [renderEncoder drawPrimitives:sgMetalType[element.mPrimType] vertexStart:0 vertexCount:n];
      }
   }

   void BeginDirectRender(const Rect &inRect) { }
   void EndDirectRender() { }
};


HardwareRenderer *HardwareRenderer::CreateMetal(void *inRenderer)
{
   SDL_Renderer *renderer = (SDL_Renderer *)renderer;

   #ifdef NME_SDL3
   CAMetalLayer *metalLayer = (__bridge CAMetalLayer *)SDL_GetRenderMetalLayer(renderer);
   #elif defined(NME_SDL2)
   CAMetalLayer *metalLayer = (__bridge CAMetalLayer *)SDL_RenderGetMetalLayer(renderer);
   #endif

   HardwareRenderer *ctx = new MetalContext( metalLayer );

   return ctx;
}


} // end namespace nme



