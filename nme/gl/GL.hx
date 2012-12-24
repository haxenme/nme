package nme.gl;


#if (cpp || neko)
typedef GL = native.gl.GL;
using native.gl.GL;
typedef Object = native.gl.Object;
typedef Buffer = native.gl.Buffer;
typedef Framebuffer = native.gl.Framebuffer;
typedef Program = native.gl.Program;
typedef Renderbuffer = native.gl.Renderbuffer;
typedef Shader = native.gl.Shader;
typedef Texture = native.gl.Texture;
typedef ActiveInfo = native.gl.ContextAttributes;
typedef ContextAttributes = native.gl.ContextAttributes;
typedef ShaderPrecisionFormat = native.gl.ShaderPrecisionFormat;
typedef UniformLocation = native.gl.UniformLocation;
#end
