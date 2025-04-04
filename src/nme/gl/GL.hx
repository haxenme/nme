package nme.gl;

#if nme_metal
#error "GL not supported with NME_METAL"
#elseif nme_no_ogl
#error "GL not supported with nme_no_ogl"
#else


import nme.display.BitmapData;
import nme.utils.ArrayBuffer;
import nme.utils.ByteArray;
import nme.utils.UInt8Array;
import nme.utils.IMemoryRange;
import nme.utils.ArrayBufferView;
import nme.geom.Matrix3D;
import nme.Lib;
import nme.Loader;
import nme.PrimeLoader;

#if (neko||cpp)
import nme.utils.Float32Array;
import nme.utils.Int32Array;

abstract NmeFloats(Dynamic)
{
   public var length(get,never):Int;
   public inline function new(d:Dynamic) this = d;

   @:to inline function toDynamic() return this;
   @:from inline static function fromFloat32Array( f:Float32Array )
        return new NmeFloats(f.getByteBuffer());
   @:from inline static function fromArrayFloat( f:Array<Float> )
        return new NmeFloats(f);
   inline public function get_length() return this.length;
}


abstract NmeInts(Dynamic)
{
   public var length(get,never):Int;
   public inline function new(d:Dynamic) this = d;

   @:to inline function toDynamic() return this;
   @:from inline static function fromInt32Array( f:Int32Array )
        return new NmeInts(f.getByteBuffer());
   @:from inline static function fromArrayInt( f:Array<Int> )
        return new NmeInts(f);
   inline public function get_length() return this.length;
}

abstract NmeBytes(Dynamic)
{
   public var length(get,never):Int;
   public inline function new(d:Dynamic) this = d;

   @:to inline function toDynamic() return this;
   @:from inline static function fromByteArray( b:ByteArray )
        return new NmeBytes(b);
   @:from inline static function fromArrayBufferView( b:ArrayBufferView )
        return new NmeBytes(b);
   inline public function get_length() return this.length;
}


#end



@:nativeProperty
@:allow(nme.gl.WebGL2Context)
class GL 
{
   /* ClearBufferMask */
   public static inline var DEPTH_BUFFER_BIT               = 0x00000100;
   public static inline var STENCIL_BUFFER_BIT             = 0x00000400;
   public static inline var COLOR_BUFFER_BIT               = 0x00004000;

   /* BeginMode */
   public static inline var POINTS                         = 0x0000;
   public static inline var LINES                          = 0x0001;
   public static inline var LINE_LOOP                      = 0x0002;
   public static inline var LINE_STRIP                     = 0x0003;
   public static inline var TRIANGLES                      = 0x0004;
   public static inline var TRIANGLE_STRIP                 = 0x0005;
   public static inline var TRIANGLE_FAN                   = 0x0006;

   /* AlphaFunction(not supported in ES20) */
   /*      NEVER */
   /*      LESS */
   /*      EQUAL */
   /*      LEQUAL */
   /*      GREATER */
   /*      NOTEQUAL */
   /*      GEQUAL */
   /*      ALWAYS */
   /* BlendingFactorDest */
   public static inline var ZERO                           = 0;
   public static inline var ONE                            = 1;
   public static inline var SRC_COLOR                      = 0x0300;
   public static inline var ONE_MINUS_SRC_COLOR            = 0x0301;
   public static inline var SRC_ALPHA                      = 0x0302;
   public static inline var ONE_MINUS_SRC_ALPHA            = 0x0303;
   public static inline var DST_ALPHA                      = 0x0304;
   public static inline var ONE_MINUS_DST_ALPHA            = 0x0305;

   /* BlendingFactorSrc */
   /*      ZERO */
   /*      ONE */
   public static inline var DST_COLOR                      = 0x0306;
   public static inline var ONE_MINUS_DST_COLOR            = 0x0307;
   public static inline var SRC_ALPHA_SATURATE             = 0x0308;
   /*      SRC_ALPHA */
   /*      ONE_MINUS_SRC_ALPHA */
   /*      DST_ALPHA */
   /*      ONE_MINUS_DST_ALPHA */
   /* BlendEquationSeparate */
   public static inline var FUNC_ADD                       = 0x8006;
   public static inline var BLEND_EQUATION                 = 0x8009;
   public static inline var BLEND_EQUATION_RGB             = 0x8009;   /* same as BLEND_EQUATION */
   public static inline var BLEND_EQUATION_ALPHA           = 0x883D;

   /* BlendSubtract */
   public static inline var FUNC_SUBTRACT                  = 0x800A;
   public static inline var FUNC_REVERSE_SUBTRACT          = 0x800B;

   /* Separate Blend Functions */
   public static inline var BLEND_DST_RGB                  = 0x80C8;
   public static inline var BLEND_SRC_RGB                  = 0x80C9;
   public static inline var BLEND_DST_ALPHA                = 0x80CA;
   public static inline var BLEND_SRC_ALPHA                = 0x80CB;
   public static inline var CONSTANT_COLOR                 = 0x8001;
   public static inline var ONE_MINUS_CONSTANT_COLOR       = 0x8002;
   public static inline var CONSTANT_ALPHA                 = 0x8003;
   public static inline var ONE_MINUS_CONSTANT_ALPHA       = 0x8004;
   public static inline var BLEND_COLOR                    = 0x8005;

   /* GLBuffer Objects */
   public static inline var ARRAY_BUFFER                   = 0x8892;
   public static inline var ELEMENT_ARRAY_BUFFER           = 0x8893;
   public static inline var ARRAY_BUFFER_BINDING           = 0x8894;
   public static inline var ELEMENT_ARRAY_BUFFER_BINDING   = 0x8895;

   public static inline var STREAM_DRAW                    = 0x88E0;
   public static inline var STATIC_DRAW                    = 0x88E4;
   public static inline var DYNAMIC_DRAW                   = 0x88E8;

   public static inline var BUFFER_SIZE                    = 0x8764;
   public static inline var BUFFER_USAGE                   = 0x8765;

   public static inline var CURRENT_VERTEX_ATTRIB          = 0x8626;

   /* CullFaceMode */
   public static inline var FRONT                          = 0x0404;
   public static inline var BACK                           = 0x0405;
   public static inline var FRONT_AND_BACK                 = 0x0408;

   /* DepthFunction */
   /*      NEVER */
   /*      LESS */
   /*      EQUAL */
   /*      LEQUAL */
   /*      GREATER */
   /*      NOTEQUAL */
   /*      GEQUAL */
   /*      ALWAYS */
   /* EnableCap */
   /* TEXTURE_2D */
   public static inline var CULL_FACE                      = 0x0B44;
   public static inline var BLEND                          = 0x0BE2;
   public static inline var DITHER                         = 0x0BD0;
   public static inline var STENCIL_TEST                   = 0x0B90;
   public static inline var DEPTH_TEST                     = 0x0B71;
   public static inline var SCISSOR_TEST                   = 0x0C11;
   public static inline var POLYGON_OFFSET_FILL            = 0x8037;
   public static inline var SAMPLE_ALPHA_TO_COVERAGE       = 0x809E;
   public static inline var SAMPLE_COVERAGE                = 0x80A0;

   /* ErrorCode */
   public static inline var NO_ERROR                       = 0;
   public static inline var INVALID_ENUM                   = 0x0500;
   public static inline var INVALID_VALUE                  = 0x0501;
   public static inline var INVALID_OPERATION              = 0x0502;
   public static inline var OUT_OF_MEMORY                  = 0x0505;

   /* FrontFaceDirection */
   public static inline var CW                             = 0x0900;
   public static inline var CCW                            = 0x0901;

   /* GetPName */
   public static inline var LINE_WIDTH                     = 0x0B21;
   public static inline var ALIASED_POINT_SIZE_RANGE       = 0x846D;
   public static inline var ALIASED_LINE_WIDTH_RANGE       = 0x846E;
   public static inline var CULL_FACE_MODE                 = 0x0B45;
   public static inline var FRONT_FACE                     = 0x0B46;
   public static inline var DEPTH_RANGE                    = 0x0B70;
   public static inline var DEPTH_WRITEMASK                = 0x0B72;
   public static inline var DEPTH_CLEAR_VALUE              = 0x0B73;
   public static inline var DEPTH_FUNC                     = 0x0B74;
   public static inline var STENCIL_CLEAR_VALUE            = 0x0B91;
   public static inline var STENCIL_FUNC                   = 0x0B92;
   public static inline var STENCIL_FAIL                   = 0x0B94;
   public static inline var STENCIL_PASS_DEPTH_FAIL        = 0x0B95;
   public static inline var STENCIL_PASS_DEPTH_PASS        = 0x0B96;
   public static inline var STENCIL_REF                    = 0x0B97;
   public static inline var STENCIL_VALUE_MASK             = 0x0B93;
   public static inline var STENCIL_WRITEMASK              = 0x0B98;
   public static inline var STENCIL_BACK_FUNC              = 0x8800;
   public static inline var STENCIL_BACK_FAIL              = 0x8801;
   public static inline var STENCIL_BACK_PASS_DEPTH_FAIL   = 0x8802;
   public static inline var STENCIL_BACK_PASS_DEPTH_PASS   = 0x8803;
   public static inline var STENCIL_BACK_REF               = 0x8CA3;
   public static inline var STENCIL_BACK_VALUE_MASK        = 0x8CA4;
   public static inline var STENCIL_BACK_WRITEMASK         = 0x8CA5;
   public static inline var VIEWPORT                       = 0x0BA2;
   public static inline var SCISSOR_BOX                    = 0x0C10;
   /*      SCISSOR_TEST */
   public static inline var COLOR_CLEAR_VALUE              = 0x0C22;
   public static inline var COLOR_WRITEMASK                = 0x0C23;
   public static inline var UNPACK_ALIGNMENT               = 0x0CF5;
   public static inline var PACK_ALIGNMENT                 = 0x0D05;
   public static inline var MAX_TEXTURE_SIZE               = 0x0D33;
   public static inline var MAX_VIEWPORT_DIMS              = 0x0D3A;
   public static inline var SUBPIXEL_BITS                  = 0x0D50;
   public static inline var RED_BITS                       = 0x0D52;
   public static inline var GREEN_BITS                     = 0x0D53;
   public static inline var BLUE_BITS                      = 0x0D54;
   public static inline var ALPHA_BITS                     = 0x0D55;
   public static inline var DEPTH_BITS                     = 0x0D56;
   public static inline var STENCIL_BITS                   = 0x0D57;
   public static inline var POLYGON_OFFSET_UNITS           = 0x2A00;
   public static inline var POLYGON_OFFSET_POINT           = 0x2A01;
   public static inline var POLYGON_OFFSET_LINE            = 0x2A02;
   public static inline var POLYGON_OFFSET_FACTOR          = 0x8038;
   public static inline var TEXTURE_BINDING_2D             = 0x8069;
   public static inline var SAMPLE_BUFFERS                 = 0x80A8;
   public static inline var SAMPLES                        = 0x80A9;
   public static inline var SAMPLE_COVERAGE_VALUE          = 0x80AA;
   public static inline var SAMPLE_COVERAGE_INVERT         = 0x80AB;

   /* GetTextureParameter */
   /*      TEXTURE_MAG_FILTER */
   /*      TEXTURE_MIN_FILTER */
   /*      TEXTURE_WRAP_S */
   /*      TEXTURE_WRAP_T */
   public static inline var COMPRESSED_TEXTURE_FORMATS     = 0x86A3;

   /* HintMode */
   public static inline var DONT_CARE                      = 0x1100;
   public static inline var FASTEST                        = 0x1101;
   public static inline var NICEST                         = 0x1102;

   /* HintTarget */
   public static inline var GENERATE_MIPMAP_HINT            = 0x8192;

   /* DataType */
   public static inline var BYTE                           = 0x1400;
   public static inline var UNSIGNED_BYTE                  = 0x1401;
   public static inline var SHORT                          = 0x1402;
   public static inline var UNSIGNED_SHORT                 = 0x1403;
   public static inline var INT                            = 0x1404;
   public static inline var UNSIGNED_INT                   = 0x1405;
   public static inline var FLOAT                          = 0x1406;

   /* PixelFormat */
   public static inline var DEPTH_COMPONENT                = 0x1902;
   public static inline var ALPHA                          = 0x1906;
   public static inline var RGB                            = 0x1907;
   public static inline var RGBA                           = 0x1908;
   public static inline var LUMINANCE                      = 0x1909;
   public static inline var LUMINANCE_ALPHA                = 0x190A;

   /* PixelType */
   /*      UNSIGNED_BYTE */
   public static inline var UNSIGNED_SHORT_4_4_4_4         = 0x8033;
   public static inline var UNSIGNED_SHORT_5_5_5_1         = 0x8034;
   public static inline var UNSIGNED_SHORT_5_6_5           = 0x8363;

   /* Shaders */
   public static inline var FRAGMENT_SHADER                  = 0x8B30;
   public static inline var VERTEX_SHADER                    = 0x8B31;
   public static inline var MAX_VERTEX_ATTRIBS               = 0x8869;
   public static inline var MAX_VERTEX_UNIFORM_VECTORS       = 0x8DFB;
   public static inline var MAX_VARYING_VECTORS              = 0x8DFC;
   public static inline var MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
   public static inline var MAX_VERTEX_TEXTURE_IMAGE_UNITS   = 0x8B4C;
   public static inline var MAX_TEXTURE_IMAGE_UNITS          = 0x8872;
   public static inline var MAX_FRAGMENT_UNIFORM_VECTORS     = 0x8DFD;
   public static inline var SHADER_TYPE                      = 0x8B4F;
   public static inline var DELETE_STATUS                    = 0x8B80;
   public static inline var LINK_STATUS                      = 0x8B82;
   public static inline var VALIDATE_STATUS                  = 0x8B83;
   public static inline var ATTACHED_SHADERS                 = 0x8B85;
   public static inline var ACTIVE_UNIFORMS                  = 0x8B86;
   public static inline var ACTIVE_ATTRIBUTES                = 0x8B89;
   public static inline var SHADING_LANGUAGE_VERSION         = 0x8B8C;
   public static inline var CURRENT_PROGRAM                  = 0x8B8D;

   /* StencilFunction */
   public static inline var NEVER                          = 0x0200;
   public static inline var LESS                           = 0x0201;
   public static inline var EQUAL                          = 0x0202;
   public static inline var LEQUAL                         = 0x0203;
   public static inline var GREATER                        = 0x0204;
   public static inline var NOTEQUAL                       = 0x0205;
   public static inline var GEQUAL                         = 0x0206;
   public static inline var ALWAYS                         = 0x0207;

   /* StencilOp */
   /*      ZERO */
   public static inline var KEEP                           = 0x1E00;
   public static inline var REPLACE                        = 0x1E01;
   public static inline var INCR                           = 0x1E02;
   public static inline var DECR                           = 0x1E03;
   public static inline var INVERT                         = 0x150A;
   public static inline var INCR_WRAP                      = 0x8507;
   public static inline var DECR_WRAP                      = 0x8508;

   /* StringName */
   public static inline var VENDOR                         = 0x1F00;
   public static inline var RENDERER                       = 0x1F01;
   public static inline var VERSION                        = 0x1F02;

   /* TextureMagFilter */
   public static inline var NEAREST                        = 0x2600;
   public static inline var LINEAR                         = 0x2601;

   /* TextureMinFilter */
   /*      NEAREST */
   /*      LINEAR */
   public static inline var NEAREST_MIPMAP_NEAREST         = 0x2700;
   public static inline var LINEAR_MIPMAP_NEAREST          = 0x2701;
   public static inline var NEAREST_MIPMAP_LINEAR          = 0x2702;
   public static inline var LINEAR_MIPMAP_LINEAR           = 0x2703;

   /* TextureParameterName */
   public static inline var TEXTURE_MAG_FILTER             = 0x2800;
   public static inline var TEXTURE_MIN_FILTER             = 0x2801;
   //public static inline var TEXTURE_WRAP_R                 = 0x8072;
   public static inline var TEXTURE_WRAP_S                 = 0x2802;
   public static inline var TEXTURE_WRAP_T                 = 0x2803;

   /* TextureTarget */
   public static inline var TEXTURE_2D                     = 0x0DE1;
   public static inline var TEXTURE                        = 0x1702;

   public static inline var TEXTURE_CUBE_MAP               = 0x8513;
   public static inline var TEXTURE_BINDING_CUBE_MAP       = 0x8514;
   public static inline var TEXTURE_CUBE_MAP_POSITIVE_X    = 0x8515;
   public static inline var TEXTURE_CUBE_MAP_NEGATIVE_X    = 0x8516;
   public static inline var TEXTURE_CUBE_MAP_POSITIVE_Y    = 0x8517;
   public static inline var TEXTURE_CUBE_MAP_NEGATIVE_Y    = 0x8518;
   public static inline var TEXTURE_CUBE_MAP_POSITIVE_Z    = 0x8519;
   public static inline var TEXTURE_CUBE_MAP_NEGATIVE_Z    = 0x851A;
   public static inline var MAX_CUBE_MAP_TEXTURE_SIZE      = 0x851C;

   /* TextureUnit */
   public static inline var TEXTURE0                       = 0x84C0;
   public static inline var TEXTURE1                       = 0x84C1;
   public static inline var TEXTURE2                       = 0x84C2;
   public static inline var TEXTURE3                       = 0x84C3;
   public static inline var TEXTURE4                       = 0x84C4;
   public static inline var TEXTURE5                       = 0x84C5;
   public static inline var TEXTURE6                       = 0x84C6;
   public static inline var TEXTURE7                       = 0x84C7;
   public static inline var TEXTURE8                       = 0x84C8;
   public static inline var TEXTURE9                       = 0x84C9;
   public static inline var TEXTURE10                      = 0x84CA;
   public static inline var TEXTURE11                      = 0x84CB;
   public static inline var TEXTURE12                      = 0x84CC;
   public static inline var TEXTURE13                      = 0x84CD;
   public static inline var TEXTURE14                      = 0x84CE;
   public static inline var TEXTURE15                      = 0x84CF;
   public static inline var TEXTURE16                      = 0x84D0;
   public static inline var TEXTURE17                      = 0x84D1;
   public static inline var TEXTURE18                      = 0x84D2;
   public static inline var TEXTURE19                      = 0x84D3;
   public static inline var TEXTURE20                      = 0x84D4;
   public static inline var TEXTURE21                      = 0x84D5;
   public static inline var TEXTURE22                      = 0x84D6;
   public static inline var TEXTURE23                      = 0x84D7;
   public static inline var TEXTURE24                      = 0x84D8;
   public static inline var TEXTURE25                      = 0x84D9;
   public static inline var TEXTURE26                      = 0x84DA;
   public static inline var TEXTURE27                      = 0x84DB;
   public static inline var TEXTURE28                      = 0x84DC;
   public static inline var TEXTURE29                      = 0x84DD;
   public static inline var TEXTURE30                      = 0x84DE;
   public static inline var TEXTURE31                      = 0x84DF;
   public static inline var ACTIVE_TEXTURE                 = 0x84E0;

   /* TextureWrapMode */
   public static inline var REPEAT                         = 0x2901;
   public static inline var CLAMP_TO_EDGE                  = 0x812F;
   public static inline var MIRRORED_REPEAT                = 0x8370;

   /* Uniform Types */
   public static inline var FLOAT_VEC2                     = 0x8B50;
   public static inline var FLOAT_VEC3                     = 0x8B51;
   public static inline var FLOAT_VEC4                     = 0x8B52;
   public static inline var INT_VEC2                       = 0x8B53;
   public static inline var INT_VEC3                       = 0x8B54;
   public static inline var INT_VEC4                       = 0x8B55;
   public static inline var BOOL                           = 0x8B56;
   public static inline var BOOL_VEC2                      = 0x8B57;
   public static inline var BOOL_VEC3                      = 0x8B58;
   public static inline var BOOL_VEC4                      = 0x8B59;
   public static inline var FLOAT_MAT2                     = 0x8B5A;
   public static inline var FLOAT_MAT3                     = 0x8B5B;
   public static inline var FLOAT_MAT4                     = 0x8B5C;
   public static inline var SAMPLER_2D                     = 0x8B5E;
   public static inline var SAMPLER_CUBE                   = 0x8B60;

   /* Vertex Arrays */
   public static inline var VERTEX_ATTRIB_ARRAY_ENABLED        = 0x8622;
   public static inline var VERTEX_ATTRIB_ARRAY_SIZE           = 0x8623;
   public static inline var VERTEX_ATTRIB_ARRAY_STRIDE         = 0x8624;
   public static inline var VERTEX_ATTRIB_ARRAY_TYPE           = 0x8625;
   public static inline var VERTEX_ATTRIB_ARRAY_NORMALIZED     = 0x886A;
   public static inline var VERTEX_ATTRIB_ARRAY_POINTER        = 0x8645;
   public static inline var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

   /* Point Size */
   public static inline var VERTEX_PROGRAM_POINT_SIZE       = 0x8642;
   public static inline var POINT_SPRITE                    = 0x8861;

   /* GLShader Source */
   public static inline var COMPILE_STATUS                 = 0x8B81;

   /* GLShader Precision-Specified Types */
   public static inline var LOW_FLOAT                      = 0x8DF0;
   public static inline var MEDIUM_FLOAT                   = 0x8DF1;
   public static inline var HIGH_FLOAT                     = 0x8DF2;
   public static inline var LOW_INT                        = 0x8DF3;
   public static inline var MEDIUM_INT                     = 0x8DF4;
   public static inline var HIGH_INT                       = 0x8DF5;

   /* GLFramebuffer Object. */
   public static inline var FRAMEBUFFER                    = 0x8D40;
   public static inline var RENDERBUFFER                   = 0x8D41;

   public static inline var RGBA4                          = 0x8056;
   public static inline var RGB5_A1                        = 0x8057;
   public static inline var RGB565                         = 0x8D62;
   public static inline var DEPTH_COMPONENT16              = 0x81A5;
   public static inline var STENCIL_INDEX                  = 0x1901;
   public static inline var STENCIL_INDEX8                 = 0x8D48;
   public static inline var DEPTH_STENCIL                  = 0x84F9;

   public static inline var RENDERBUFFER_WIDTH             = 0x8D42;
   public static inline var RENDERBUFFER_HEIGHT            = 0x8D43;
   public static inline var RENDERBUFFER_INTERNAL_FORMAT   = 0x8D44;
   public static inline var RENDERBUFFER_RED_SIZE          = 0x8D50;
   public static inline var RENDERBUFFER_GREEN_SIZE        = 0x8D51;
   public static inline var RENDERBUFFER_BLUE_SIZE         = 0x8D52;
   public static inline var RENDERBUFFER_ALPHA_SIZE        = 0x8D53;
   public static inline var RENDERBUFFER_DEPTH_SIZE        = 0x8D54;
   public static inline var RENDERBUFFER_STENCIL_SIZE      = 0x8D55;

   public static inline var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE           = 0x8CD0;
   public static inline var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME           = 0x8CD1;
   public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL         = 0x8CD2;
   public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

   public static inline var COLOR_ATTACHMENT0              = 0x8CE0;
   public static inline var DEPTH_ATTACHMENT               = 0x8D00;
   public static inline var STENCIL_ATTACHMENT             = 0x8D20;
   public static inline var DEPTH_STENCIL_ATTACHMENT       = 0x821A;

   public static inline var NONE                           = 0;

   public static inline var FRAMEBUFFER_COMPLETE                      = 0x8CD5;
   public static inline var FRAMEBUFFER_INCOMPLETE_ATTACHMENT         = 0x8CD6;
   public static inline var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
   public static inline var FRAMEBUFFER_INCOMPLETE_DIMENSIONS         = 0x8CD9;
   public static inline var FRAMEBUFFER_UNSUPPORTED                   = 0x8CDD;

   public static inline var FRAMEBUFFER_BINDING            = 0x8CA6;
   public static inline var RENDERBUFFER_BINDING           = 0x8CA7;
   public static inline var MAX_RENDERBUFFER_SIZE          = 0x84E8;

   public static inline var INVALID_FRAMEBUFFER_OPERATION  = 0x0506;

   /* WebGL-specific enums */
   public static inline var UNPACK_FLIP_Y_WEBGL            = 0x9240;
   public static inline var UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;
   public static inline var CONTEXT_LOST_WEBGL             = 0x9242;
   public static inline var UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;
   public static inline var BROWSER_DEFAULT_WEBGL          = 0x9244;

   public static inline var READ_BUFFER = 0x0C02;
   public static inline var UNPACK_ROW_LENGTH = 0x0CF2;
   public static inline var UNPACK_SKIP_ROWS = 0x0CF3;
   public static inline var UNPACK_SKIP_PIXELS = 0x0CF4;
   public static inline var PACK_ROW_LENGTH = 0x0D02;
   public static inline var PACK_SKIP_ROWS = 0x0D03;
   public static inline var PACK_SKIP_PIXELS = 0x0D04;
   public static inline var TEXTURE_BINDING_3D = 0x806A;
   public static inline var UNPACK_SKIP_IMAGES = 0x806D;
   public static inline var UNPACK_IMAGE_HEIGHT = 0x806E;
   public static inline var MAX_3D_TEXTURE_SIZE = 0x8073;
   public static inline var MAX_ELEMENTS_VERTICES = 0x80E8;
   public static inline var MAX_ELEMENTS_INDICES = 0x80E9;
   public static inline var MAX_TEXTURE_LOD_BIAS = 0x84FD;
   public static inline var MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;
   public static inline var MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;
   public static inline var MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;
   public static inline var MIN_PROGRAM_TEXEL_OFFSET = 0x8904;
   public static inline var MAX_PROGRAM_TEXEL_OFFSET = 0x8905;
   public static inline var MAX_VARYING_COMPONENTS = 0x8B4B;
   public static inline var FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;
   public static inline var RASTERIZER_DISCARD = 0x8C89;
   public static inline var VERTEX_ARRAY_BINDING = 0x85B5;
   public static inline var MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;
   public static inline var MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;
   public static inline var MAX_SERVER_WAIT_TIMEOUT = 0x9111;
   public static inline var MAX_ELEMENT_INDEX = 0x8D6B;


   // WebGL2 helpers
   public static inline var RED = 0x1903;
   public static inline var RGB8 = 0x8051;
   public static inline var RGBA8 = 0x8058;
   public static inline var RGB10_A2 = 0x8059;
   public static inline var TEXTURE_3D = 0x806F;
   public static inline var TEXTURE_WRAP_R = 0x8072;
   public static inline var TEXTURE_MIN_LOD = 0x813A;
   public static inline var TEXTURE_MAX_LOD = 0x813B;
   public static inline var TEXTURE_BASE_LEVEL = 0x813C;
   public static inline var TEXTURE_MAX_LEVEL = 0x813D;
   public static inline var TEXTURE_COMPARE_MODE = 0x884C;
   public static inline var TEXTURE_COMPARE_FUNC = 0x884D;
   public static inline var SRGB = 0x8C40;
   public static inline var SRGB8 = 0x8C41;
   public static inline var SRGB8_ALPHA8 = 0x8C43;
   public static inline var COMPARE_REF_TO_TEXTURE = 0x884E;
   public static inline var RGBA32F = 0x8814;
   public static inline var RGB32F = 0x8815;
   public static inline var RGBA16F = 0x881A;
   public static inline var RGB16F = 0x881B;
   public static inline var TEXTURE_2D_ARRAY = 0x8C1A;
   public static inline var TEXTURE_BINDING_2D_ARRAY = 0x8C1D;
   public static inline var R11F_G11F_B10F = 0x8C3A;
   public static inline var RGB9_E5 = 0x8C3D;
   public static inline var RGBA32UI = 0x8D70;
   public static inline var RGB32UI = 0x8D71;
   public static inline var RGBA16UI = 0x8D76;
   public static inline var RGB16UI = 0x8D77;
   public static inline var RGBA8UI = 0x8D7C;
   public static inline var RGB8UI = 0x8D7D;
   public static inline var RGBA32I = 0x8D82;
   public static inline var RGB32I = 0x8D83;
   public static inline var RGBA16I = 0x8D88;
   public static inline var RGB16I = 0x8D89;
   public static inline var RGBA8I = 0x8D8E;
   public static inline var RGB8I = 0x8D8F;
   public static inline var RED_INTEGER = 0x8D94;
   public static inline var RGB_INTEGER = 0x8D98;
   public static inline var RGBA_INTEGER = 0x8D99;
   public static inline var R8 = 0x8229;
   public static inline var RG8 = 0x822B;
   public static inline var R16F = 0x822D;
   public static inline var R32F = 0x822E;
   public static inline var RG16F = 0x822F;
   public static inline var RG32F = 0x8230;
   public static inline var R8I = 0x8231;
   public static inline var R8UI = 0x8232;
   public static inline var R16I = 0x8233;
   public static inline var R16UI = 0x8234;
   public static inline var R32I = 0x8235;
   public static inline var R32UI = 0x8236;
   public static inline var RG8I = 0x8237;
   public static inline var RG8UI = 0x8238;
   public static inline var RG16I = 0x8239;
   public static inline var RG16UI = 0x823A;
   public static inline var RG32I = 0x823B;
   public static inline var RG32UI = 0x823C;
   public static inline var R8_SNORM = 0x8F94;
   public static inline var RG8_SNORM = 0x8F95;
   public static inline var RGB8_SNORM = 0x8F96;
   public static inline var RGBA8_SNORM = 0x8F97;
   public static inline var RGB10_A2UI = 0x906F;
   public static inline var TEXTURE_IMMUTABLE_FORMAT = 0x912F;
   public static inline var TEXTURE_IMMUTABLE_LEVELS = 0x82DF;
   
   public static inline var UNSIGNED_INT_2_10_10_10_REV = 0x8368;
   public static inline var UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;
   public static inline var UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;
   public static inline var FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;
   public static inline var UNSIGNED_INT_24_8 = 0x84FA;
   public static inline var HALF_FLOAT = 0x140B;
   public static inline var RG = 0x8227;
   public static inline var RG_INTEGER = 0x8228;
   public static inline var INT_2_10_10_10_REV = 0x8D9F;
   
   public static inline var CURRENT_QUERY = 0x8865;
   public static inline var QUERY_RESULT = 0x8866;
   public static inline var QUERY_RESULT_AVAILABLE = 0x8867;
   public static inline var ANY_SAMPLES_PASSED = 0x8C2F;
   public static inline var ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;
   
   public static inline var MAX_DRAW_BUFFERS = 0x8824;
   public static inline var DRAW_BUFFER0 = 0x8825;
   public static inline var DRAW_BUFFER1 = 0x8826;
   public static inline var DRAW_BUFFER2 = 0x8827;
   public static inline var DRAW_BUFFER3 = 0x8828;
   public static inline var DRAW_BUFFER4 = 0x8829;
   public static inline var DRAW_BUFFER5 = 0x882A;
   public static inline var DRAW_BUFFER6 = 0x882B;
   public static inline var DRAW_BUFFER7 = 0x882C;
   public static inline var DRAW_BUFFER8 = 0x882D;
   public static inline var DRAW_BUFFER9 = 0x882E;
   public static inline var DRAW_BUFFER10 = 0x882F;
   public static inline var DRAW_BUFFER11 = 0x8830;
   public static inline var DRAW_BUFFER12 = 0x8831;
   public static inline var DRAW_BUFFER13 = 0x8832;
   public static inline var DRAW_BUFFER14 = 0x8833;
   public static inline var DRAW_BUFFER15 = 0x8834;
   public static inline var MAX_COLOR_ATTACHMENTS = 0x8CDF;
   public static inline var COLOR_ATTACHMENT1 = 0x8CE1;
   public static inline var COLOR_ATTACHMENT2 = 0x8CE2;
   public static inline var COLOR_ATTACHMENT3 = 0x8CE3;
   public static inline var COLOR_ATTACHMENT4 = 0x8CE4;
   public static inline var COLOR_ATTACHMENT5 = 0x8CE5;
   public static inline var COLOR_ATTACHMENT6 = 0x8CE6;
   public static inline var COLOR_ATTACHMENT7 = 0x8CE7;
   public static inline var COLOR_ATTACHMENT8 = 0x8CE8;
   public static inline var COLOR_ATTACHMENT9 = 0x8CE9;
   public static inline var COLOR_ATTACHMENT10 = 0x8CEA;
   public static inline var COLOR_ATTACHMENT11 = 0x8CEB;
   public static inline var COLOR_ATTACHMENT12 = 0x8CEC;
   public static inline var COLOR_ATTACHMENT13 = 0x8CED;
   public static inline var COLOR_ATTACHMENT14 = 0x8CEE;
   public static inline var COLOR_ATTACHMENT15 = 0x8CEF;
   
   public static inline var SAMPLER_3D = 0x8B5F;
   public static inline var SAMPLER_2D_SHADOW = 0x8B62;
   public static inline var SAMPLER_2D_ARRAY = 0x8DC1;
   public static inline var SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;
   public static inline var SAMPLER_CUBE_SHADOW = 0x8DC5;
   public static inline var INT_SAMPLER_2D = 0x8DCA;
   public static inline var INT_SAMPLER_3D = 0x8DCB;
   public static inline var INT_SAMPLER_CUBE = 0x8DCC;
   public static inline var INT_SAMPLER_2D_ARRAY = 0x8DCF;
   public static inline var UNSIGNED_INT_SAMPLER_2D = 0x8DD2;
   public static inline var UNSIGNED_INT_SAMPLER_3D = 0x8DD3;
   public static inline var UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;
   public static inline var UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;
   public static inline var MAX_SAMPLES = 0x8D57;
   public static inline var SAMPLER_BINDING = 0x8919;
   
   public static inline var PIXEL_PACK_BUFFER = 0x88EB;
   public static inline var PIXEL_UNPACK_BUFFER = 0x88EC;
   public static inline var PIXEL_PACK_BUFFER_BINDING = 0x88ED;
   public static inline var PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;
   public static inline var COPY_READ_BUFFER = 0x8F36;
   public static inline var COPY_WRITE_BUFFER = 0x8F37;
   public static inline var COPY_READ_BUFFER_BINDING = 0x8F36;
   public static inline var COPY_WRITE_BUFFER_BINDING = 0x8F37;
   
   public static inline var FLOAT_MAT2x3 = 0x8B65;
   public static inline var FLOAT_MAT2x4 = 0x8B66;
   public static inline var FLOAT_MAT3x2 = 0x8B67;
   public static inline var FLOAT_MAT3x4 = 0x8B68;
   public static inline var FLOAT_MAT4x2 = 0x8B69;
   public static inline var FLOAT_MAT4x3 = 0x8B6A;
   public static inline var UNSIGNED_INT_VEC2 = 0x8DC6;
   public static inline var UNSIGNED_INT_VEC3 = 0x8DC7;
   public static inline var UNSIGNED_INT_VEC4 = 0x8DC8;
   public static inline var UNSIGNED_NORMALIZED = 0x8C17;
   public static inline var SIGNED_NORMALIZED = 0x8F9C;
   
   public static inline var VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;
   public static inline var VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;
   
   public static inline var TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;
   public static inline var MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;
   public static inline var TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;
   public static inline var TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;
   public static inline var TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;
   public static inline var TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;
   public static inline var MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;
   public static inline var MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;
   public static inline var INTERLEAVED_ATTRIBS = 0x8C8C;
   public static inline var SEPARATE_ATTRIBS = 0x8C8D;
   public static inline var TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;
   public static inline var TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;
   public static inline var TRANSFORM_FEEDBACK = 0x8E22;
   public static inline var TRANSFORM_FEEDBACK_PAUSED = 0x8E23;
   public static inline var TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;
   public static inline var TRANSFORM_FEEDBACK_BINDING = 0x8E25;

   public static inline var FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;
   public static inline var FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;
   public static inline var FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;
   public static inline var FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;
   public static inline var FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;
   public static inline var FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;
   public static inline var FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;
   public static inline var FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;
   public static inline var FRAMEBUFFER_DEFAULT = 0x8218;
   public static inline var DEPTH24_STENCIL8 = 0x88F0;
   public static inline var DRAW_FRAMEBUFFER_BINDING = 0x8CA6;
   public static inline var READ_FRAMEBUFFER = 0x8CA8;
   public static inline var DRAW_FRAMEBUFFER = 0x8CA9;
   public static inline var READ_FRAMEBUFFER_BINDING = 0x8CAA;
   public static inline var RENDERBUFFER_SAMPLES = 0x8CAB;
   public static inline var FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;
   public static inline var FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;

   public static inline var UNIFORM_BUFFER = 0x8A11;
   public static inline var UNIFORM_BUFFER_BINDING = 0x8A28;
   public static inline var UNIFORM_BUFFER_START = 0x8A29;
   public static inline var UNIFORM_BUFFER_SIZE = 0x8A2A;
   public static inline var MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;
   public static inline var MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;
   public static inline var MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;
   public static inline var MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;
   public static inline var MAX_UNIFORM_BLOCK_SIZE = 0x8A30;
   public static inline var MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;
   public static inline var MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;
   public static inline var UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;
   public static inline var ACTIVE_UNIFORM_BLOCKS = 0x8A36;
   public static inline var UNIFORM_TYPE = 0x8A37;
   public static inline var UNIFORM_SIZE = 0x8A38;
   public static inline var UNIFORM_BLOCK_INDEX = 0x8A3A;
   public static inline var UNIFORM_OFFSET = 0x8A3B;
   public static inline var UNIFORM_ARRAY_STRIDE = 0x8A3C;
   public static inline var UNIFORM_MATRIX_STRIDE = 0x8A3D;
   public static inline var UNIFORM_IS_ROW_MAJOR = 0x8A3E;
   public static inline var UNIFORM_BLOCK_BINDING = 0x8A3F;
   public static inline var UNIFORM_BLOCK_DATA_SIZE = 0x8A40;
   public static inline var UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;
   public static inline var UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;
   public static inline var UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;
   public static inline var UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;

   public static inline var OBJECT_TYPE = 0x9112;
   public static inline var SYNC_CONDITION = 0x9113;
   public static inline var SYNC_STATUS = 0x9114;
   public static inline var SYNC_FLAGS = 0x9115;
   public static inline var SYNC_FENCE = 0x9116;
   public static inline var SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
   public static inline var UNSIGNALED = 0x9118;
   public static inline var SIGNALED = 0x9119;
   public static inline var ALREADY_SIGNALED = 0x911A;
   public static inline var TIMEOUT_EXPIRED = 0x911B;
   public static inline var CONDITION_SATISFIED = 0x911C;
   public static inline var WAIT_FAILED = 0x911D;
   public static inline var SYNC_FLUSH_COMMANDS_BIT = 0x00000001;
   
   public static inline var COLOR = 0x1800;
   public static inline var DEPTH = 0x1801;
   public static inline var STENCIL = 0x1802;
   public static inline var MIN = 0x8007;
   public static inline var MAX = 0x8008;
   public static inline var DEPTH_COMPONENT24 = 0x81A6;
   public static inline var STREAM_READ = 0x88E1;
   public static inline var STREAM_COPY = 0x88E2;
   public static inline var STATIC_READ = 0x88E5;
   public static inline var STATIC_COPY = 0x88E6;
   public static inline var DYNAMIC_READ = 0x88E9;
   public static inline var DYNAMIC_COPY = 0x88EA;
   public static inline var DEPTH_COMPONENT32F = 0x8CAC;
   public static inline var DEPTH32F_STENCIL8 = 0x8CAD;
   public static inline var INVALID_INDEX = 0xFFFFFFFF;
   public static inline var TIMEOUT_IGNORED = -1;
   public static inline var MAX_CLIENT_WAIT_TIMEOUT_WEBGL = 0x9247;

   public static inline var CLIP_DISTANCE0 = 0x3000;


   #if (neko||cpp)

   public static var drawingBufferHeight(get, null):Int;
   public static var drawingBufferWidth(get, null):Int;
   public static var version(get, null):Int;

   public static inline function activeTexture(texture:Int):Void { nme_gl_active_texture(texture); }

   public static inline function attachShader(program:GLProgram, shader:GLShader):Void
   {
      program.attach(shader);
      nme_gl_attach_shader(program.id, shader.id);
   }

   public static inline function bindAttribLocation(program:GLProgram, index:Int, name:String):Void
   {
      nme_gl_bind_attrib_location(program.id, index, name);
   }

   public static inline function bindBitmapDataTexture(texture:BitmapData):Void
   {
      nme_gl_bind_bitmap_data_texture(texture.nmeHandle);
   }

   public static inline function bindBuffer(target:Int, buffer:GLBuffer):Void
   {
      nme_gl_bind_buffer(target, buffer);
   }

   public static inline function bindFramebuffer(target:Int, framebuffer:GLFramebuffer):Void
   {
      nme_gl_bind_framebuffer(target, framebuffer);
   }

   public static inline function bindRenderbuffer(target:Int, renderbuffer:GLRenderbuffer):Void
   {
      nme_gl_bind_renderbuffer(target, renderbuffer);
   }

   public static inline function bindTexture(target:Int, texture:GLTexture):Void
   {
      nme_gl_bind_texture(target, texture);
   }

   public static inline function blendColor(red:Float, green:Float, blue:Float, alpha:Float):Void
   {
      nme_gl_blend_color(red, green, blue, alpha);
   }

   public static inline function blendEquation(mode:Int):Void
   {
      nme_gl_blend_equation(mode);
   }

   public static inline function blendEquationSeparate(modeRGB:Int, modeAlpha:Int):Void
   {
      nme_gl_blend_equation_separate(modeRGB, modeAlpha);
   }

   public static inline function blendFunc(sfactor:Int, dfactor:Int):Void
   {
      nme_gl_blend_func(sfactor, dfactor);
   }

   public static inline function blendFuncSeparate(srcRGB:Int, dstRGB:Int, srcAlpha:Int, dstAlpha:Int):Void
   {
      nme_gl_blend_func_separate(srcRGB, dstRGB, srcAlpha, dstAlpha);
   }

   public static inline function bufferData(target:Int, data:IMemoryRange, usage:Int):Void
   {
      nme_gl_buffer_data(target, data.getByteBuffer(), data.getStart(), data.getLength(), usage);
   }

   public static inline function bufferSubData(target:Int, offset:Int, data:IMemoryRange):Void
   {
      nme_gl_buffer_sub_data(target, offset, data.getByteBuffer(), data.getStart(), data.getLength());
   }

   public static inline function checkFramebufferStatus(target:Int):Int
   {
      return nme_gl_check_framebuffer_status(target);
   }

   public static inline function clear(mask:Int):Void
   {
      nme_gl_clear(mask);
   }

   public static inline function clearColor(red:Float, green:Float, blue:Float, alpha:Float):Void
   {
      nme_gl_clear_color(red, green, blue, alpha);
   }

   public static inline function clearDepth(depth:Float):Void
   {
      nme_gl_clear_depth(depth);
   }

   public static inline function clearStencil(s:Int):Void
   {
      nme_gl_clear_stencil(s);
   }

   public static inline function colorMask(red:Bool, green:Bool, blue:Bool, alpha:Bool):Void
   {
      nme_gl_color_mask(red, green, blue, alpha);
   }

   public static inline function compileShader(shader:GLShader):Void
   {
      nme_gl_compile_shader(shader.id);
   }

   public static inline function compressedTexImage2D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, data:IMemoryRange):Void
   {
      nme_gl_compressed_tex_image_2d(target, level, internalformat, width, height, border, data == null ? null : data.getByteBuffer(), data == null ? null : data.getStart());
   }

   public static inline function compressedTexSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, data:IMemoryRange):Void
   {
      nme_gl_compressed_tex_sub_image_2d(target, level, xoffset, yoffset, width, height, format, data == null ? null : data.getByteBuffer(), data == null ? null : data.getStart());
   }

   public static inline function copyTexImage2D(target:Int, level:Int, internalformat:Int, x:Int, y:Int, width:Int, height:Int, border:Int):Void
   {
      nme_gl_copy_tex_image_2d(target, level, internalformat, x, y, width, height, border);
   }

   public static inline function copyTexSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, x:Int, y:Int, width:Int, height:Int):Void
   {
      nme_gl_copy_tex_sub_image_2d(target, level, xoffset, yoffset, x, y, width, height);
   }

   public static inline function createBuffer():GLBuffer
   {
      return new GLBuffer(version, nme_gl_create_buffer());
   }

   public static inline function createFramebuffer():GLFramebuffer
   {
      return new GLFramebuffer(version, nme_gl_create_framebuffer());
   }

   public static inline function createProgram():GLProgram
   {
      return new GLProgram(version, nme_gl_create_program());
   }

   public static inline function createRenderbuffer():GLRenderbuffer
   {
      return new GLRenderbuffer(version, nme_gl_create_render_buffer());
   }

   public static inline function createShader(type:Int):GLShader
   {
      return new GLShader(version,nme_gl_create_shader(type));
   }

   public static inline function createTexture():GLTexture
   {
      return new GLTexture(version, nme_gl_create_texture());
   }

   public static inline function cullFace(mode:Int):Void
   {
     nme_gl_cull_face(mode);
   }

   public static inline function deleteBuffer(buffer:GLBuffer):Void
   {
      nme_gl_delete_buffer(buffer.id);
      buffer.invalidate();
   }

   public static inline function deleteFramebuffer(framebuffer:GLFramebuffer):Void
   {
      nme_gl_delete_framebuffer(framebuffer.id);
      framebuffer.invalidate();
   }

   public static inline function deleteProgram(program:GLProgram):Void
   {
      nme_gl_delete_program(program.id);
      program.invalidate();
   }

   public static inline function deleteRenderbuffer(renderbuffer:GLRenderbuffer):Void
   {
      nme_gl_delete_renderbuffer(renderbuffer.id);
      renderbuffer.invalidate();
   }

   public static inline function deleteShader(shader:GLShader):Void
   {
      nme_gl_delete_shader(shader.id);
      shader.invalidate();
   }

   public static inline function deleteTexture(texture:GLTexture):Void
   {
      nme_gl_delete_texture(texture.id);
      texture.invalidate();
   }

   public static inline function depthFunc(func:Int):Void
   {
      nme_gl_depth_func(func);
   }

   public static inline function depthMask(flag:Bool):Void
   {
      nme_gl_depth_mask(flag);
   }

   public static inline function depthRange(zNear:Float, zFar:Float):Void
   {
      nme_gl_depth_range(zNear, zFar);
   }

   public static inline function detachShader(program:GLProgram, shader:GLShader):Void
   {
      nme_gl_detach_shader(program.id, shader.id);
   }

   public static inline function disable(cap:Int):Void
   {
      nme_gl_disable(cap);
   }

   public static inline function disableVertexAttribArray(index:Int):Void
   {
      nme_gl_disable_vertex_attrib_array(index);
   }

   public static inline function drawArrays(mode:Int, first:Int, count:Int):Void
   {
      nme_gl_draw_arrays(mode, first, count);
   }

   public static inline function drawArraysInstanced(mode:Int, first:Int, count:Int, instances:Int):Void
   {
      nme_gl_draw_arrays_instanced(mode, first, count, instances);
   }

   public static inline function drawElements(mode:Int, count:Int, type:Int, offset:Int):Void
   {
      nme_gl_draw_elements(mode, count, type, offset);
   }

   public static inline function drawElementsInstanced(mode:Int, count:Int, type:Int, offset:Int, instances:Int):Void
   {
      nme_gl_draw_elements_instanced(mode, count, type, offset,instances);
   }


   public static inline function enable(cap:Int):Void
   {
      nme_gl_enable(cap);
   }

   public static inline function enableVertexAttribArray(index:Int):Void
   {
      nme_gl_enable_vertex_attrib_array(index);
   }

   public static inline function finish():Void
   {
      nme_gl_finish();
   }

   public static inline function flush():Void
   {
      nme_gl_flush();
   }

   public static inline function framebufferRenderbuffer(target:Int, attachment:Int, renderbuffertarget:Int, renderbuffer:GLRenderbuffer):Void
   {
      nme_gl_framebuffer_renderbuffer(target, attachment, renderbuffertarget, renderbuffer.id);
   }

   public static inline function framebufferTexture2D(target:Int, attachment:Int, textarget:Int, texture:GLTexture, level:Int):Void
   {
      nme_gl_framebuffer_texture2D(target, attachment, textarget, texture.id, level);
   }

   public static inline function frontFace(mode:Int):Void
   {
      nme_gl_front_face(mode);
   }

   public static inline function generateMipmap(target:Int):Void
   {
      nme_gl_generate_mipmap(target);
   }

   public static inline function getActiveAttrib(program:GLProgram, index:Int):GLActiveInfo
   {
      return nme_gl_get_active_attrib(program.id, index);
   }

   public static inline function getActiveUniform(program:GLProgram, index:Int):GLActiveInfo
   {
      return nme_gl_get_active_uniform(program.id, index);
   }

   public static inline function getAttachedShaders(program:GLProgram):Array<GLShader>
   {
      return program.getShaders();
   }

   public static inline function getAttribLocation(program:GLProgram, name:String):Int
   {
      return nme_gl_get_attrib_location(program.id, name);
   }

   public static inline function getBufferParameter(target:Int, pname:Int):Dynamic
   {
      return nme_gl_get_buffer_paramerter(target, pname);
   }

   public static inline function getContextAttributes():GLContextAttributes
   {
      var base = nme_gl_get_context_attributes();
      base.premultipliedAlpha = false;
      base.preserveDrawingBuffer = false;
      return base;
   }

   public static inline function getError():Int
   {
      return nme_gl_get_error();
   }

   public static inline function getExtension(name:String):Dynamic
   {
      return nme_gl_get_extension(name);
   }

   public static inline function getFramebufferAttachmentParameter(target:Int, attachment:Int, pname:Int):Dynamic
   {
      return nme_gl_get_framebuffer_attachment_parameter(target, attachment, pname);
   }

   public static inline function getParameter(pname:Int):Dynamic
   {
      return nme_gl_get_parameter(pname);
   }

   public static inline function getProgramInfoLog(program:GLProgram):String
   {
      return nme_gl_get_program_info_log(program.id);
   }

   public static inline function getProgramParameter(program:GLProgram, pname:Int):Int
   {
      return nme_gl_get_program_parameter(program.id, pname);
   }

   public static inline function getRenderbufferParameter(target:Int, pname:Int):Dynamic
   {
      return nme_gl_get_render_buffer_parameter(target, pname);
   }

   public static inline function getShaderInfoLog(shader:GLShader):String
   {
      return nme_gl_get_shader_info_log(shader.id);
   }

   public static inline function getShaderParameter(shader:GLShader, pname:Int):Int
   {
      return nme_gl_get_shader_parameter(shader.id, pname);
   }

   public static inline function getShaderPrecisionFormat(shadertype:Int, precisiontype:Int):ShaderPrecisionFormat
   {
      return nme_gl_get_shader_precision_format(shadertype, precisiontype);
   }

   public static inline function getShaderSource(shader:GLShader):String
   {
      return nme_gl_get_shader_source(shader.id);
   }

   public static inline function getSupportedExtensions():Array<String>
   {
      var result = new Array<String>();
      nme_gl_get_supported_extensions(result);
      return result;
   }

   public static inline function getTexParameter(target:Int, pname:Int):Dynamic
   {
      return nme_gl_get_tex_parameter(target, pname);
   }

   public static inline function getUniform(program:GLProgram, location:GLUniformLocation):Dynamic
   {
      return nme_gl_get_uniform(program.id, location);
   }

   public static inline function getUniformLocation(program:GLProgram, name:String):Dynamic
   {
      return nme_gl_get_uniform_location(program.id, name);
   }

   public static inline function getVertexAttrib(index:Int, pname:Int):Dynamic
   {
      return nme_gl_get_vertex_attrib(index, pname);
   }

   public static inline function getVertexAttribOffset(index:Int, pname:Int):Int
   {
      return nme_gl_get_vertex_attrib_offset(index, pname);
   }

   public static inline function hint(target:Int, mode:Int):Void
   {
      nme_gl_hint(target, mode);
   }

   public static inline function isBuffer(buffer:GLBuffer):Bool
   {
      return buffer != null && nme_gl_is_buffer(buffer.id);
   }

   // This is non-static
   // public function isContextLost():Bool { return false; }
   public static inline function isEnabled(cap:Int):Bool
   {
      return nme_gl_is_enabled(cap);
   }

   public static inline function isFramebuffer(framebuffer:GLFramebuffer):Bool
   {
      return framebuffer != null && nme_gl_is_framebuffer(framebuffer.id);
   }

   public static inline function isProgram(program:GLProgram):Bool
   {
      return program != null && nme_gl_is_program(program.id);
   }

   public static inline function isRenderbuffer(renderbuffer:GLRenderbuffer):Bool
   {
      return renderbuffer != null && nme_gl_is_renderbuffer(renderbuffer.id);
   }

   public static inline function isShader(shader:GLShader):Bool
   {
      return shader != null && nme_gl_is_shader(shader.id);
   }

   public static inline function isTexture(texture:GLTexture):Bool
   {
      return texture != null && nme_gl_is_texture(texture.id);
   }

   public static inline function lineWidth(width:Float):Void
   {
      nme_gl_line_width(width);
   }

   public static inline function linkProgram(program:GLProgram):Void
   {
      nme_gl_link_program(program.id);
   }

   public static inline function load(inName:String, inArgCount:Int):Dynamic
   {
      try 
      {
         return Loader.load(inName, inArgCount);

      } catch(e:Dynamic) 
      {
         trace(e);
         return null;
      }
   }

   public static inline function pixelStorei(pname:Int, param:Int):Void
   {
      nme_gl_pixel_storei(pname, param);
   }

   public static inline function polygonOffset(factor:Float, units:Float):Void
   {
      nme_gl_polygon_offset(factor, units);
   }

   public static inline function readPixels(x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, pixels:NmeBytes):Void
   {
      var offset = 0;
      nme_gl_read_pixels(x,y,width,height,format,type,pixels,offset);
   }

   public static inline function renderbufferStorage(target:Int, internalformat:Int, width:Int, height:Int):Void
   {
      nme_gl_renderbuffer_storage(target, internalformat, width, height);
   }

   public static inline function sampleCoverage(value:Float, invert:Bool):Void
   {
      nme_gl_sample_coverage(value, invert);
   }

   public static inline function scissor(x:Int, y:Int, width:Int, height:Int):Void
   {
      nme_gl_scissor(x, y, width, height);
   }

   public static inline function shaderSource(shader:GLShader, source:String):Void
   {
      nme_gl_shader_source(shader.id, source);
   }

   public static inline function stencilFunc(func:Int, ref:Int, mask:Int):Void
   {
      nme_gl_stencil_func(func, ref, mask);
   }

   public static inline function stencilFuncSeparate(face:Int, func:Int, ref:Int, mask:Int):Void
   {
      nme_gl_stencil_func_separate(face, func, ref, mask);
   }

   public static inline function stencilMask(mask:Int):Void
   {
      nme_gl_stencil_mask(mask);
   }

   public static inline function stencilMaskSeparate(face:Int, mask:Int):Void
   {
      nme_gl_stencil_mask_separate(face, mask);
   }

   public static inline function stencilOp(fail:Int, zfail:Int, zpass:Int):Void
   {
      nme_gl_stencil_op(fail, zfail, zpass);
   }

   public static inline function stencilOpSeparate(face:Int, fail:Int, zfail:Int, zpass:Int):Void
   {
      nme_gl_stencil_op_separate(face, fail, zfail, zpass);
   }

   public static inline function texImage2D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, pixels:ArrayBufferView):Void
   {
      nme_gl_tex_image_2d(target, level, internalformat, width, height, border, format, type, pixels == null ? null : pixels.getByteBuffer(), pixels == null ? null : pixels.getStart());
   }

   public static inline function texParameterf(target:Int, pname:Int, param:Float):Void
   {
      nme_gl_tex_parameterf(target, pname, param);
   }

   public static inline function texParameteri(target:Int, pname:Int, param:Int):Void
   {
      nme_gl_tex_parameteri(target, pname, param);
   }

   public static inline function texSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, pixels:ArrayBufferView):Void
   {
      nme_gl_tex_sub_image_2d(target, level, xoffset, yoffset, width, height, format, type, pixels == null ? null : pixels.getByteBuffer(), pixels == null ? null : pixels.getStart());
   }

   public static inline function uniform1f(location:GLUniformLocation, x:Float):Void
   {
      nme_gl_uniform1f(location, x);
   }

   public static inline function uniform1fv(location:GLUniformLocation, x:NmeFloats):Void
   {
      nme_gl_uniform1fv(location, x);
   }

   public static inline function uniform1i(location:GLUniformLocation, x:Int):Void
   {
      nme_gl_uniform1i(location, x);
   }

   public static inline function uniform1iv(location:GLUniformLocation, v:NmeInts):Void
   {
      nme_gl_uniform1iv(location, v);
   }

   public static inline function uniform2f(location:GLUniformLocation, x:Float, y:Float):Void
   {
      nme_gl_uniform2f(location, x, y);
   }

   public static inline function uniform2fv(location:GLUniformLocation, v:NmeFloats):Void
   {
      nme_gl_uniform2fv(location, v);
   }

   public static inline function uniform2i(location:GLUniformLocation, x:Int, y:Int):Void
   {
      nme_gl_uniform2i(location, x, y);
   }

   public static inline function uniform2iv(location:GLUniformLocation, v:NmeInts):Void
   {
      nme_gl_uniform2iv(location, v);
   }

   public static inline function uniform3f(location:GLUniformLocation, x:Float, y:Float, z:Float):Void
   {
      nme_gl_uniform3f(location, x, y, z);
   }

   public static inline function uniform3fv(location:GLUniformLocation, v:NmeFloats):Void
   {
      nme_gl_uniform3fv(location, v);
   }

   public static inline function uniform3i(location:GLUniformLocation, x:Int, y:Int, z:Int):Void
   {
      nme_gl_uniform3i(location, x, y, z);
   }

   public static inline function uniform3iv(location:GLUniformLocation, v:NmeInts):Void
   {
      nme_gl_uniform3iv(location, v);
   }

   public static inline function uniform4f(location:GLUniformLocation, x:Float, y:Float, z:Float, w:Float):Void
   {
      nme_gl_uniform4f(location, x, y, z, w);
   }

   public static inline function uniform4fv(location:GLUniformLocation, v:NmeFloats):Void
   {
      nme_gl_uniform4fv(location, v);
   }

   public static inline function uniform4i(location:GLUniformLocation, x:Int, y:Int, z:Int, w:Int):Void
   {
      nme_gl_uniform4i(location, x, y, z, w);
   }

   public static inline function uniform4iv(location:GLUniformLocation, v:NmeInts):Void
   {
      nme_gl_uniform4iv(location, v);
   }

   public static inline function uniformMatrix2fv(location:GLUniformLocation, transpose:Bool, v:Float32Array):Void
   {
      nme_gl_uniform_matrix(location, transpose, v.getByteBuffer(), 2);
   }

   public static inline function uniformMatrix3fv(location:GLUniformLocation, transpose:Bool, v:Float32Array):Void
   {
      nme_gl_uniform_matrix(location, transpose, v.getByteBuffer(), 3);
   }

   public static inline function uniformMatrix4fv(location:GLUniformLocation, transpose:Bool, v:Float32Array):Void
   {
      nme_gl_uniform_matrix(location, transpose, v.getByteBuffer(), 4);
   }

   public static inline function uniformMatrix3D(location:GLUniformLocation, transpose:Bool, matrix:Matrix3D):Void
   {
      nme_gl_uniform_matrix(location, transpose, Float32Array.fromMatrix(matrix).getByteBuffer() , 4);
   }

   public static inline function useProgram(program:GLProgram):Void
   {
      nme_gl_use_program(program);
   }

   public static inline function validateProgram(program:GLProgram):Void
   {
      nme_gl_validate_program(program.id);
   }

   public static inline function vertexAttrib1f(indx:Int, x:Float):Void
   {
      nme_gl_vertex_attrib1f(indx, x);
   }

   public static inline function vertexAttrib1fv(indx:Int, values:NmeFloats):Void
   {
      nme_gl_vertex_attrib1fv(indx, values);
   }

   public static inline function vertexAttrib2f(indx:Int, x:Float, y:Float):Void
   {
      nme_gl_vertex_attrib2f(indx, x, y);
   }

   public static inline function vertexAttrib2fv(indx:Int, values:NmeFloats):Void
   {
      nme_gl_vertex_attrib2fv(indx, values);
   }

   public static inline function vertexAttrib3f(indx:Int, x:Float, y:Float, z:Float):Void
   {
      nme_gl_vertex_attrib3f(indx, x, y, z);
   }

   public static inline function vertexAttrib3fv(indx:Int, values:NmeFloats):Void
   {
      nme_gl_vertex_attrib3fv(indx, values);
   }

   public static inline function vertexAttrib4f(indx:Int, x:Float, y:Float, z:Float, w:Float):Void
   {
      nme_gl_vertex_attrib4f(indx, x, y, z, w);
   }

   public static inline function vertexAttrib4fv(indx:Int, values:NmeFloats):Void
   {
      nme_gl_vertex_attrib4fv(indx, values);
   }

   public static inline function vertexAttribPointer(indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void
   {
      nme_gl_vertex_attrib_pointer(indx, size, type, normalized, stride, offset);
   }

   public static inline function viewport(x:Int, y:Int, width:Int, height:Int):Void
   {
      nme_gl_viewport(x, y, width, height);
   }






   // New WebGL additions
   public static inline function createQuery():GLQuery
   {
      return new GLQuery(version,nme_gl_create_query());
   }
   public static inline function deleteQuery(query:GLQuery):Void
   {
      nme_gl_delete_query(query.id);
      query.invalidate();
   }
   public static inline function beginQuery(target:Int,query:GLQuery):Void
   {
      nme_gl_begin_query(target,query.id);
   }
   public static inline function endQuery(target:Int):Void
   {
      nme_gl_end_query(target);
   }
   public static function getQueryInt(query:GLQuery, pname:Int):Int
   {
      return nme_gl_query_get_int(query.id, pname);
   }
   public static function getQueryParameter(query:GLQuery, pname:Int):Dynamic
   {
      switch(pname)
      {
         case QUERY_RESULT:
            return getQueryInt(query, pname);
         case QUERY_RESULT_AVAILABLE:
            return getQueryInt(query, pname)!=0;
         default:
            return null;
      }
   }

   public static inline function createVertexArray():GLVertexArrayObject
   {
      return new GLVertexArrayObject(version,nme_gl_create_vertex_array());
   }
   public static inline function deleteVertexArray(array:GLVertexArrayObject):Void
   {
      nme_gl_delete_vertex_array(array.id);
      array.invalidate();
   }
   public static inline function bindVertexArray(array:GLVertexArrayObject):Void
   {
      nme_gl_bind_vertex_array(array);
   }
   public static inline function vertexAttribDivisor(index:Int, divisor:Int) : Void
   {
      nme_gl_vertex_attrib_divisor(index, divisor);
   }
   public static inline function bindBufferBase(target:Int, index:Int, buffer:GLBuffer):Void
   {
      nme_gl_bind_buffer_base(target, index, buffer);
   }


   public static inline function createTransformFeedback():GLTransformFeedback
   {
      return new GLTransformFeedback(version,nme_gl_create_transform_feedback());
   }
   public static inline function deleteTransformFeedback(feedback:GLTransformFeedback):Void
   {
      nme_gl_delete_transform_feedback(feedback);
   }


   public static inline function bindTransformFeedback(target:Int, feedback:GLTransformFeedback):Void
   {
      nme_gl_bind_transform_feedback(target,feedback);
   }

   public static inline function beginTransformFeedback(primitive:Int):Void
   {
      nme_gl_begin_transform_feedback(primitive);
   }
   public static inline function endTransformFeedback():Void
   {
      nme_gl_end_transform_feedback();
   }
   public static function transformFeedbackVaryings(prog:GLProgram, vars:Array<String>, bufferMode:Int):Void
   {
      nme_gl_transform_feedback_varyings(prog, vars, bufferMode);
   }
   public static function getUniformBlockIndex(prog:GLProgram, blockName:String):Int
   {
      return nme_gl_get_uniform_block_index(prog, blockName);
   }
   public static function uniformBlockBinding(prog:GLProgram, blockIndex:Int, blockBinding:Int):Void
   {
      nme_gl_uniform_block_binding(prog, blockIndex, blockBinding);
   }
   public static function blitFramebuffer( srcX0:Int, srcY0:Int, srcX1:Int, srcY1:Int, dstX0:Int, dstY0:Int, dstX1:Int, dstY1:Int, mask:Int, filter:Int)
   {
      nme_gl_blit_framebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter);
   }
   public static function renderbufferStorageMultisample(target:Int, samples:Int, internalFormat:Int, width:Int, height:Int)
   {
      nme_gl_renderbuffer_storage_multisample(target, samples, internalFormat, width, height);
   }
   public static function drawBuffers(buffers:Array<Int>):Void
   {
      nme_gl_draw_buffers(buffers);
   }
   public static function readBuffer(buffer:Int):Void
   {
      nme_gl_read_buffer(buffer);
   }

   public static inline function compressedTexImage3D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int,  imagesize:Int, data:IMemoryRange, inOffset=0):Void
   {
      nme_gl_compressed_tex_image_3d(target, level, internalformat, width, height, depth, border,imagesize, data == null ? null : data.getByteBuffer(), (data == null ? 0 : data.getStart()) + inOffset);
   }


   public static inline function texImage3D(target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int,pixels:ArrayBufferView):Void
   {
      nme_gl_tex_image_3d(target, level, internalformat, width, height, depth, border, format, type, pixels == null ? null : pixels.getByteBuffer(), pixels == null ? 0 : pixels.getStart());
   }


   //Angle
   public static inline function getTranslatedShaderSourceANGLE(shader:GLShader):String
   {
      return nme_gl_get_translated_shader_source(shader.id);
   }


   // Getters & Setters
   private static inline function get_drawingBufferHeight() { return Lib.current.stage.stageHeight; }
   private static inline function get_drawingBufferWidth() { return Lib.current.stage.stageWidth; }
   private static inline function get_version():Int { return nme_gl_version(); }

   // Native Methods
   private static var nme_gl_active_texture = load("nme_gl_active_texture", 1);
   private static var nme_gl_attach_shader = load("nme_gl_attach_shader", 2);
   private static var nme_gl_bind_attrib_location = load("nme_gl_bind_attrib_location", 3);
   private static var nme_gl_bind_bitmap_data_texture = load("nme_gl_bind_bitmap_data_texture", 1);
   private static var nme_gl_bind_buffer = load("nme_gl_bind_buffer", 2);
   private static var nme_gl_bind_framebuffer = load("nme_gl_bind_framebuffer", 2);
   private static var nme_gl_bind_renderbuffer = load("nme_gl_bind_renderbuffer", 2);
   private static var nme_gl_bind_texture = load("nme_gl_bind_texture", 2);
   private static var nme_gl_blend_color = load("nme_gl_blend_color", 4);
   private static var nme_gl_blend_equation = load("nme_gl_blend_equation", 1);
   private static var nme_gl_blend_equation_separate = load("nme_gl_blend_equation_separate", 2);
   private static var nme_gl_blend_func = load("nme_gl_blend_func", 2);
   private static var nme_gl_blend_func_separate = load("nme_gl_blend_func_separate", 4);
   private static var nme_gl_buffer_data = load("nme_gl_buffer_data", 5);
   private static var nme_gl_buffer_sub_data = load("nme_gl_buffer_sub_data", 5);
   private static var nme_gl_check_framebuffer_status = load("nme_gl_check_framebuffer_status", 1);
   private static var nme_gl_clear = load("nme_gl_clear", 1);
   private static var nme_gl_clear_color = load("nme_gl_clear_color", 4);
   private static var nme_gl_clear_depth = load("nme_gl_clear_depth", 1);
   private static var nme_gl_clear_stencil = load("nme_gl_clear_stencil", 1);
   private static var nme_gl_color_mask = load("nme_gl_color_mask", 4);
   private static var nme_gl_compile_shader = load("nme_gl_compile_shader", 1);
   private static var nme_gl_compressed_tex_image_2d = load("nme_gl_compressed_tex_image_2d", -1);
   private static var nme_gl_compressed_tex_sub_image_2d = load("nme_gl_compressed_tex_sub_image_2d", -1);
   private static var nme_gl_copy_tex_image_2d = load("nme_gl_copy_tex_image_2d", -1);
   private static var nme_gl_copy_tex_sub_image_2d = load("nme_gl_copy_tex_sub_image_2d", -1);
   private static var nme_gl_create_buffer = load("nme_gl_create_buffer", 0);
   private static var nme_gl_create_framebuffer = load("nme_gl_create_framebuffer", 0);
   private static var nme_gl_create_program = load("nme_gl_create_program", 0);
   private static var nme_gl_create_render_buffer = load("nme_gl_create_render_buffer", 0);
   private static var nme_gl_create_shader = load("nme_gl_create_shader", 1);
   private static var nme_gl_create_texture = load("nme_gl_create_texture", 0);
   private static var nme_gl_cull_face = load("nme_gl_cull_face", 1);
   private static var nme_gl_delete_buffer = load("nme_gl_delete_buffer", 1);
   private static var nme_gl_delete_framebuffer = load("nme_gl_delete_framebuffer", 1);
   private static var nme_gl_delete_program = load("nme_gl_delete_program", 1);
   private static var nme_gl_delete_renderbuffer = load("nme_gl_delete_renderbuffer", 1);
   private static var nme_gl_delete_shader = load("nme_gl_delete_shader", 1);
   private static var nme_gl_delete_texture = load("nme_gl_delete_texture", 1);
   private static var nme_gl_depth_func = load("nme_gl_depth_func", 1);
   private static var nme_gl_depth_mask = load("nme_gl_depth_mask", 1);
   private static var nme_gl_depth_range = load("nme_gl_depth_range", 2);
   private static var nme_gl_detach_shader = load("nme_gl_detach_shader", 2);
   private static var nme_gl_disable = load("nme_gl_disable", 1);
   private static var nme_gl_disable_vertex_attrib_array = load("nme_gl_disable_vertex_attrib_array", 1);
   private static var nme_gl_draw_arrays = PrimeLoader.load("nme_gl_draw_arrays", "iiiv");
   private static var nme_gl_draw_arrays_instanced = PrimeLoader.load("nme_gl_draw_arrays_instanced", "iiiiv");
   private static var nme_gl_draw_elements = PrimeLoader.load("nme_gl_draw_elements", "iiiiv");
   private static var nme_gl_draw_elements_instanced = PrimeLoader.load("nme_gl_draw_elements_instanced", "iiiiiv");
   private static var nme_gl_enable = load("nme_gl_enable", 1);
   private static var nme_gl_enable_vertex_attrib_array = load("nme_gl_enable_vertex_attrib_array", 1);
   private static var nme_gl_finish = load("nme_gl_finish", 0);
   private static var nme_gl_flush = load("nme_gl_flush", 0);
   private static var nme_gl_framebuffer_renderbuffer = load("nme_gl_framebuffer_renderbuffer", 4);
   private static var nme_gl_framebuffer_texture2D = load("nme_gl_framebuffer_texture2D", 5);
   private static var nme_gl_front_face = load("nme_gl_front_face", 1);
   private static var nme_gl_generate_mipmap = load("nme_gl_generate_mipmap", 1);
   private static var nme_gl_get_active_attrib = load("nme_gl_get_active_attrib", 2);
   private static var nme_gl_get_active_uniform = load("nme_gl_get_active_uniform", 2);
   private static var nme_gl_get_attrib_location = load("nme_gl_get_attrib_location", 2);
   private static var nme_gl_get_buffer_paramerter = load("nme_gl_get_buffer_paramerter", 2);
   private static var nme_gl_get_context_attributes = load("nme_gl_get_context_attributes", 0);
   private static var nme_gl_get_error = load("nme_gl_get_error", 0);
   private static var nme_gl_get_extension = load("nme_gl_get_extension", 1);
   private static var nme_gl_get_framebuffer_attachment_parameter = load("nme_gl_get_framebuffer_attachment_parameter", 3);
   private static var nme_gl_get_parameter = load("nme_gl_get_parameter", 1);
   private static var nme_gl_get_program_info_log = load("nme_gl_get_program_info_log", 1);
   private static var nme_gl_get_program_parameter = load("nme_gl_get_program_parameter", 2);
   private static var nme_gl_get_render_buffer_parameter = load("nme_gl_get_render_buffer_parameter", 2);
   private static var nme_gl_get_shader_info_log = load("nme_gl_get_shader_info_log", 1);
   private static var nme_gl_get_shader_parameter = load("nme_gl_get_shader_parameter", 2);
   private static var nme_gl_get_shader_precision_format = load("nme_gl_get_shader_precision_format", 2);
   private static var nme_gl_get_shader_source = load("nme_gl_get_shader_source", 1);
   private static var nme_gl_get_supported_extensions = load("nme_gl_get_supported_extensions", 1);
   private static var nme_gl_get_tex_parameter = load("nme_gl_get_tex_parameter", 2);
   private static var nme_gl_get_uniform = load("nme_gl_get_uniform", 2);
   private static var nme_gl_get_uniform_location = load("nme_gl_get_uniform_location", 2);
   private static var nme_gl_get_vertex_attrib = load("nme_gl_get_vertex_attrib", 2);
   private static var nme_gl_get_vertex_attrib_offset = load("nme_gl_get_vertex_attrib_offset", 2);
   private static var nme_gl_hint = load("nme_gl_hint", 2);
   private static var nme_gl_is_buffer = load("nme_gl_is_buffer", 1);
   private static var nme_gl_is_enabled = load("nme_gl_is_enabled", 1);
   private static var nme_gl_is_framebuffer = load("nme_gl_is_framebuffer", 1);
   private static var nme_gl_is_program = load("nme_gl_is_program", 1);
   private static var nme_gl_is_renderbuffer = load("nme_gl_is_renderbuffer", 1);
   private static var nme_gl_is_shader = load("nme_gl_is_shader", 1);
   private static var nme_gl_is_texture = load("nme_gl_is_texture", 1);
   private static var nme_gl_line_width = load("nme_gl_line_width", 1);
   private static var nme_gl_link_program = load("nme_gl_link_program", 1);
   private static var nme_gl_pixel_storei = load("nme_gl_pixel_storei", 2);
   private static var nme_gl_polygon_offset = load("nme_gl_polygon_offset", 2);
   private static var nme_gl_renderbuffer_storage = load("nme_gl_renderbuffer_storage", 4);
   private static var nme_gl_sample_coverage = load("nme_gl_sample_coverage", 2);
   private static var nme_gl_scissor = load("nme_gl_scissor", 4);
   private static var nme_gl_shader_source = load("nme_gl_shader_source", 2);
   private static var nme_gl_stencil_func = load("nme_gl_stencil_func", 3);
   private static var nme_gl_stencil_func_separate = load("nme_gl_stencil_func_separate", 4);
   private static var nme_gl_stencil_mask = load("nme_gl_stencil_mask", 1);
   private static var nme_gl_stencil_mask_separate = load("nme_gl_stencil_mask_separate", 2);
   private static var nme_gl_stencil_op = load("nme_gl_stencil_op", 3);
   private static var nme_gl_stencil_op_separate = load("nme_gl_stencil_op_separate", 4);
   private static var nme_gl_tex_image_2d = load("nme_gl_tex_image_2d", -1);
   private static var nme_gl_tex_parameterf = load("nme_gl_tex_parameterf", 3);
   private static var nme_gl_tex_parameteri = load("nme_gl_tex_parameteri", 3);
   private static var nme_gl_tex_sub_image_2d = load("nme_gl_tex_sub_image_2d", -1);
   private static var nme_gl_uniform1f = load("nme_gl_uniform1f", 2);
   private static var nme_gl_uniform1fv = load("nme_gl_uniform1fv", 2);
   private static var nme_gl_uniform1i = load("nme_gl_uniform1i", 2);
   private static var nme_gl_uniform1iv = load("nme_gl_uniform1iv", 2);
   private static var nme_gl_uniform2f = load("nme_gl_uniform2f", 3);
   private static var nme_gl_uniform2fv = load("nme_gl_uniform2fv", 2);
   private static var nme_gl_uniform2i = load("nme_gl_uniform2i", 3);
   private static var nme_gl_uniform2iv = load("nme_gl_uniform2iv", 2);
   private static var nme_gl_uniform3f = load("nme_gl_uniform3f", 4);
   private static var nme_gl_uniform3fv = load("nme_gl_uniform3fv", 2);
   private static var nme_gl_uniform3i = load("nme_gl_uniform3i", 4);
   private static var nme_gl_uniform3iv = load("nme_gl_uniform3iv", 2);
   private static var nme_gl_uniform4f = load("nme_gl_uniform4f", 5);
   private static var nme_gl_uniform4fv = load("nme_gl_uniform4fv", 2);
   private static var nme_gl_uniform4i = load("nme_gl_uniform4i", 5);
   private static var nme_gl_uniform4iv = load("nme_gl_uniform4iv", 2);
   private static var nme_gl_uniform_matrix = load("nme_gl_uniform_matrix", 4);
   private static var nme_gl_use_program = load("nme_gl_use_program", 1);
   private static var nme_gl_validate_program = load("nme_gl_validate_program", 1);
   private static var nme_gl_version = load("nme_gl_version", 0);
   private static var nme_gl_vertex_attrib1f = load("nme_gl_vertex_attrib1f", 2);
   private static var nme_gl_vertex_attrib1fv = load("nme_gl_vertex_attrib1fv", 2);
   private static var nme_gl_vertex_attrib2f = load("nme_gl_vertex_attrib2f", 3);
   private static var nme_gl_vertex_attrib2fv = load("nme_gl_vertex_attrib2fv", 2);
   private static var nme_gl_vertex_attrib3f = load("nme_gl_vertex_attrib3f", 4);
   private static var nme_gl_vertex_attrib3fv = load("nme_gl_vertex_attrib3fv", 2);
   private static var nme_gl_vertex_attrib4f = load("nme_gl_vertex_attrib4f", 5);
   private static var nme_gl_vertex_attrib4fv = load("nme_gl_vertex_attrib4fv", 2);
   private static var nme_gl_vertex_attrib_pointer = load("nme_gl_vertex_attrib_pointer", -1);
   private static var nme_gl_viewport = load("nme_gl_viewport", 4);
   private static var nme_gl_read_pixels = load("nme_gl_read_pixels", -1);

   private static var nme_gl_create_query = load("nme_gl_create_query", 0);
   private static var nme_gl_delete_query = load("nme_gl_delete_query", 1);
   private static var nme_gl_begin_query = PrimeLoader.load("nme_gl_begin_query", "iiv");
   private static var nme_gl_end_query = PrimeLoader.load("nme_gl_end_query", "iv");
   private static var nme_gl_query_get_int = PrimeLoader.load("nme_gl_query_get_int", "iii");

   private static var nme_gl_create_vertex_array = load("nme_gl_create_vertex_array", 0);
   private static var nme_gl_delete_vertex_array = load("nme_gl_delete_vertex_array", 1);
   private static var nme_gl_bind_vertex_array = PrimeLoader.load("nme_gl_bind_vertex_array", "ov");
   private static var nme_gl_bind_buffer_base = PrimeLoader.load("nme_gl_bind_buffer_base", "iiov");
   private static var nme_gl_vertex_attrib_divisor = PrimeLoader.load("nme_gl_vertex_attrib_divisor", "iiv");

   private static var nme_gl_create_transform_feedback = load("nme_gl_create_transform_feedback", 0);
   private static var nme_gl_delete_transform_feedback = load("nme_gl_delete_transform_feedback", 1);
   private static var nme_gl_bind_transform_feedback = PrimeLoader.load("nme_gl_bind_transform_feedback", "iov");
   private static var nme_gl_begin_transform_feedback = PrimeLoader.load("nme_gl_begin_transform_feedback", "iv");
   private static var nme_gl_end_transform_feedback = PrimeLoader.load("nme_gl_end_transform_feedback", "v");
   private static var nme_gl_transform_feedback_varyings = PrimeLoader.load("nme_gl_transform_feedback_varyings", "ooiv");

   private static var nme_gl_get_uniform_block_index = PrimeLoader.load("nme_gl_get_uniform_block_index", "osi");
   private static var nme_gl_uniform_block_binding = PrimeLoader.load("nme_gl_uniform_block_binding", "oiiv");

   private static var nme_gl_blit_framebuffer = PrimeLoader.load("nme_gl_blit_framebuffer", "iiiiiiiiiiv");
   private static var nme_gl_renderbuffer_storage_multisample = PrimeLoader.load("nme_gl_renderbuffer_storage_multisample", "iiiiiv");
   private static var nme_gl_draw_buffers = PrimeLoader.load("nme_gl_draw_buffers", "ov");
   private static var nme_gl_read_buffer = PrimeLoader.load("nme_gl_read_buffer", "iv");
   private static var nme_gl_tex_image_3d = PrimeLoader.load("nme_gl_tex_image_3d", "iiiiiiiiioiv");
   private static var nme_gl_compressed_tex_image_3d = PrimeLoader.load("nme_gl_compressed_tex_image_3d", "iiiiiiiioiv");

   private static var nme_gl_get_translated_shader_source = load("nme_gl_get_translated_shader_source", 1);

   #else // not (neko||cpp)


   public static inline function getSupportedExtensions():Array<String>
   {
      var result = new Array<String>();
      return result;
   }

   // Stub to get flixel to compile
   public static function getParameter(pname:Int):Dynamic 
   {
      return 0;
   }
   #end
}

typedef ShaderPrecisionFormat = 
{
   rangeMin : Int,
   rangeMax : Int,
   precision : Int,

};


#end // !nme_metal
