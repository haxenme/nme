/**
 * Copyright (c) 2010, Jeash contributors.
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash;

typedef UInt = Int;
typedef Vector<T> = Array<T>;

/*
* <----------------- WebWorkers ------------------>
*/

extern interface WorkerGlobalScope implements WorkerUtils, implements EventTarget {
	public var self(default,null):WorkerGlobalScope;
	public var location(default,null):WorkerLocation;
	public var onerror:Event->Void;

	public function close():Void;
}

extern interface AbstractWorker implements EventTarget {
	public var onError:Event->Void;
}

extern class Worker implements AbstractWorker {
	public function new(scriptUrl:DOMString):Void;
	
	public function terminate():Void;
	public function postMessage(message:Dynamic, ?ports:MessagePortArray):Void;
	public var onMessage:Event->Void;

	// -- inherited
	public var onError:Event->Void;
	public function addEventListener(type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;

	public function removeEventListener(type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;

	public function dispatchEvent(evt: Event): Bool;

	public function addEventListenerNS(namespaceURI: DOMString, type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;

	public function removeEventListenerNS(namespaceURI: DOMString, type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;
}

extern interface WorkerUtils implements WindowTimers {
	public function importScripts(url: Array<String>):Void;
	public var navigator(default,null):WorkerNavigator;
}

extern interface WorkerNavigator implements NavigatorID, implements NavigatorOnLine { } 

extern interface WorkerLocation {
	public var href(default,null):DOMString;
	public var protocol(default,null):DOMString;
	public var host(default,null):DOMString;
	public var hostname(default,null):DOMString;
	public var port(default,null):DOMString;
	public var pathname(default,null):DOMString;
	public var search(default,null):DOMString;
	public var hash(default,null):DOMString;
}

extern interface WindowTimers {
	public function setTimeout(handler:Dynamic, ?timeout:Dynamic, args:Array<Dynamic>):Int;
	public function clearTimeout(handle:Int):Void;
	public function setInterval(handler:Dynamic, ?timeout:Dynamic, args:Array<Dynamic>):Int;
	public function clearInterval(handle:Int):Void;
}

extern interface NavigatorID {
	public var appName(default,null):DOMString;
	public var appVersion(default,null):DOMString;
	public var platform(default,null):DOMString;
	public var userAgent(default,null):DOMString;
}

extern interface NavigatorContentUtils {
	public function registerProtocolHandler(scheme:DOMString, url:DOMString, title:DOMString):Void;
	public function registerContentHandler(mimeType:DOMString, url:DOMString, title:DOMString):Void;
}

extern interface NavigatorStorageUtils {
	public function yieldStorageUpdates():Void;
}

extern interface NavigatorOnLine {
	public var onLine(default,null):Bool;
}

/*
* <----------------- DOM-Level-3-XPath ------------------>
*/

extern interface XPathException {
	public var code:Int;
}

extern interface XPathEvaluator {
	public function createExpression(expression:DOMString, resolver:XPathNSResolver):XPathExpression; // raises (XPathException, DOMException)
	public function createNSResolver(nodeResolver:Node):XPathNSResolver;
	public function evaluate(expression:DOMString, contextNode:Node, resolver:XPathNSResolver, type:Int, result:DOMObject):DOMObject; // raises (XPathException, DOMException)
}

extern interface XPathExpression {
	public function evaluate(contextNode:Node, type:Int, result:DOMObject):DOMObject; // raises (XPathException, DOMException)
}

extern interface XPathNSResolver {
	public function lookupNamespaceURI(prefix:DOMString):DOMString;
}

extern class XPathResult {
	public static var ANY_TYPE:Int = 0; 
	public static var NUMBER_TYPE:Int = 1; 
	public static var STRING_TYPE:Int = 2;
	public static var BOOLEAN_TYPE:Int = 3;
	public static var UNORDERED_NODE_ITERATOR_TYPE:Int = 4;
	public static var ORDERED_NODE_ITERATOR_TYPE:Int = 5;
	public static var UNORDERED_NODE_SNAPSHOT_TYPE:Int = 6;
	public static var ORDERED_NODE_SNAPSHOT_TYPE:Int = 7;
	public static var ANY_UNORDERED_NODE_TYPE:Int = 8;
	public static var FIRST_ORDERED_NODE_TYPE:Int = 9;

	public var resultType(default,null):Int;
	public var numberValue(default,null):Float;
	public var stringValue(default,null):DOMString;
	public var booleanValue(default,null):Bool;
	public var singleNodeValue(default,null):Node;
	public var invalidIteratorState(default,null):Bool;
	public var snapshotLength(default,null):Int;

	public function iterateNext():Node; // raises (XPathException, DOMException)
	public function snapshotItem(index:Int):Node; // raises (XPathException, DOMException)
}

extern interface XPathNamespace
{
	public var XPATH_NAMESPACE_NODE:Int;
	public var ownerElement(default,null):Element;
}

/*
* <----------------- DomParser Non-Standardised ------------------>
*/

extern class DOMParser 
{
	function new():Void;
	function parseFromString( input:String, type:String ):Document;
}

/*
* <----------------- TypedArray IDL Port ------------------>
*/

extern class ArrayBuffer {
	var byteLength(default,null):Int;
	function new(length:Int):Void;
	function slice(offset:Int, length:Int):ArrayBuffer;
}

extern interface ArrayBufferView {
	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
}

extern class Int8Array implements ArrayBufferView, implements ArrayAccess<Int> {
	var BYTES_PER_ELEMENT:Int;

	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	var length(default,null):Int;

	function new(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic):Void;
	@:overload( function (index:ArrayAccess<Int>, ?offset:Int):Void {} )
	function set(index:Int8Array, ?offset:Int):Void;
	function subarray(offset:Int, length:Int):Int8Array;
}

extern class Uint8Array implements ArrayBufferView, implements ArrayAccess<Int> {
	var BYTES_PER_ELEMENT:Int;

	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	var length(default,null):Int;

	function new(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic):Void;
	@:overload( function (index:ArrayAccess<Int>, ?offset:Int):Void {} )
	function set(index:Uint8Array, ?offset:Int):Void;
	function subarray(offset:Int, length:Int):Uint8Array;
}

extern class Int16Array implements ArrayBufferView, implements ArrayAccess<Int> {
	var BYTES_PER_ELEMENT:Int;

	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	var length(default,null):Int;

	function new(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic):Void;
	function set(index:ArrayAccess<Int>, offset:Int):Void;
	function subarray(offset:Int, length:Int):Int16Array;
}

extern class Uint16Array implements ArrayBufferView, implements ArrayAccess<Int> {
	var BYTES_PER_ELEMENT:Int;

	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	var length(default,null):Int;

	function new(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic):Void;
	function set(index:ArrayAccess<Int>, offset:Int):Void;
	function subarray(offset:Int, length:Int):Uint16Array;
}

extern class Int32Array implements ArrayBufferView, implements ArrayAccess<Int> {
	var BYTES_PER_ELEMENT:Int;

	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	var length(default,null):Int;

	function new(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic):Void;
	function set(index:ArrayAccess<Int>, offset:Int):Void;
	function subarray(offset:Int, length:Int):Int32Array;
}

extern class Uint32Array implements ArrayBufferView, implements ArrayAccess<Int> {
	var BYTES_PER_ELEMENT:Int;

	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	var length(default,null):Int;

	function new(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic):Void;
	function set(index:ArrayAccess<Int>, offset:Int):Void;
	function subarray(offset:Int, length:Int):Uint32Array;
}

extern class Float32Array implements ArrayBufferView, implements ArrayAccess<Float> {
	var BYTES_PER_ELEMENT:Int;

	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	var length(default,null):Int;

	function new(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic):Void;
	function set(index:ArrayAccess<Float>, offset:Int):Void;
	function subarray(offset:Int, length:Int):Float32Array;
}

extern class Float64Array implements ArrayBufferView, implements ArrayAccess<Float> {
	var BYTES_PER_ELEMENT:Int;

	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	var length(default,null):Int;

	function new(?v1:Dynamic, ?v2:Dynamic, ?v3:Dynamic):Void;
	function set(index:ArrayAccess<Float>, offset:Int):Void;
	function subarray(offset:Int, length:Int):Float64Array;
}

extern class DataView implements ArrayBufferView {
	var buffer(default,null):ArrayBuffer;
	var byteOffset(default,null):ArrayBuffer;
	var byteLength(default,null):ArrayBuffer;
	function new(buffer:ArrayBuffer, ?byteOffset:Int, ?byteLength:Int):Void;

	function getInt8(byteOffset:Int):Int;
	function getUint8(byteOffset:Int):Int;
	function getInt16(byteOffset:Int, littleEndian:Bool):Int;
	function getUint16(byteOffset:Int, littleEndian:Bool):Int;
	function getInt32(byteOffset:Int, littleEndian:Bool):Int;
	function getUint32(byteOffset:Int, littleEndian:Bool):Int;
	function getFloat32(byteOffset:Int, littleEndian:Bool):Float;
	function getFloat64(byteOffset:Int, littleEndian:Bool):Float;
	function setInt8(byteOffset:Int, value:Int):Void;
	function setUint8(byteOffset:Int, value:Int):Void;
	function setInt16(byteOffset:Int, value:Int, littleEndian:Bool):Void;
	function setUint16(byteOffset:Int, value:Int, littleEndian:Bool):Void;
	function setInt32(byteOffset:Int, value:Int, littleEndian:Bool):Void;
	function setUint32(byteOffset:Int, value:Int, littleEndian:Bool):Void;
	function setFloat32(byteOffset:Int, value:Float, littleEndian:Bool):Void;
	function setFloat64(byteOffset:Int, value:Float, littleEndian:Bool):Void;
}

/*
* <----------------- WebGL IDL Port ------------------>
*/

typedef GLenum = Int;
typedef GLboolean = Bool;
typedef GLbitfield = Int;
typedef GLbyte = Int;
typedef GLshort = Int;
typedef GLint = Int;
typedef GLsizei = Int;
typedef GLsizeiptr = Int;
typedef GLubyte = Int;
typedef GLushort = Int;
typedef GLuint = Int;
typedef GLfloat = Float;
typedef GLclampf = Float;

extern interface WebGLContextAttributes {
	var alpha:Bool;
	var depth:Bool;
	var stencil:Bool;
	var antialias:Bool;
	var premultipliedAlpha:Bool;
}

extern interface WebGLObject {
}

extern interface WebGLBuffer implements WebGLObject {
}

extern interface WebGLFramebuffer implements WebGLObject {
}

extern interface WebGLProgram implements WebGLObject {
}

extern interface WebGLRenderbuffer implements WebGLObject {
}

extern interface WebGLShader implements WebGLObject {
}

extern interface WebGLTexture implements WebGLObject {
}

extern interface WebGLUniformLocation {
}

extern interface WebGLActiveInfo {
	var size(default,null):GLint;
	var type(default,null):GLenum;
	var name(default,null):DOMString;
}

extern interface WebGLRenderingContext 
{

    /* ClearBufferMask */
    public var DEPTH_BUFFER_BIT              : GLenum;
    public var STENCIL_BUFFER_BIT            : GLenum;
    public var COLOR_BUFFER_BIT              : GLenum;
    
    /* BeginMode */
    public var POINTS                        : GLenum;
    public var LINES                         : GLenum;
    public var LINE_LOOP                     : GLenum;
    public var LINE_STRIP                    : GLenum;
    public var TRIANGLES                     : GLenum;
    public var TRIANGLE_STRIP                : GLenum;
    public var TRIANGLE_FAN                  : GLenum;
    
    /* AlphaFunction (not supported in ES20) */
    /*      NEVER */
    /*      LESS */
    /*      EQUAL */
    /*      LEQUAL */
    /*      GREATER */
    /*      NOTEQUAL */
    /*      GEQUAL */
    /*      ALWAYS */
    
    /* BlendingFactorDest */
    public var ZERO                          : GLenum;
    public var ONE                           : GLenum;
    public var SRC_COLOR                     : GLenum;
    public var ONE_MINUS_SRC_COLOR           : GLenum;
    public var SRC_ALPHA                     : GLenum;
    public var ONE_MINUS_SRC_ALPHA           : GLenum;
    public var DST_ALPHA                     : GLenum;
    public var ONE_MINUS_DST_ALPHA           : GLenum;
    
    /* BlendingFactorSrc */
    /*      ZERO */
    /*      ONE */
    public var DST_COLOR                     : GLenum;
    public var ONE_MINUS_DST_COLOR           : GLenum;
    public var SRC_ALPHA_SATURATE            : GLenum;
    /*      SRC_ALPHA */
    /*      ONE_MINUS_SRC_ALPHA */
    /*      DST_ALPHA */
    /*      ONE_MINUS_DST_ALPHA */
    
    /* BlendEquationSeparate */
    public var FUNC_ADD                      : GLenum;
    public var BLEND_EQUATION                : GLenum;
    public var BLEND_EQUATION_RGB            : GLenum;   /* same as BLEND_EQUATION */
    public var BLEND_EQUATION_ALPHA          : GLenum;
    
    /* BlendSubtract */
    public var FUNC_SUBTRACT                 : GLenum;
    public var FUNC_REVERSE_SUBTRACT         : GLenum;
    
    /* Separate Blend Functions */
    public var BLEND_DST_RGB                 : GLenum;
    public var BLEND_SRC_RGB                 : GLenum;
    public var BLEND_DST_ALPHA               : GLenum;
    public var BLEND_SRC_ALPHA               : GLenum;
    public var CONSTANT_COLOR                : GLenum;
    public var ONE_MINUS_CONSTANT_COLOR      : GLenum;
    public var CONSTANT_ALPHA                : GLenum;
    public var ONE_MINUS_CONSTANT_ALPHA      : GLenum;
    public var BLEND_COLOR                   : GLenum;
    
    /* Buffer Objects */
    public var ARRAY_BUFFER                  : GLenum;
    public var ELEMENT_ARRAY_BUFFER          : GLenum;
    public var ARRAY_BUFFER_BINDING          : GLenum;
    public var ELEMENT_ARRAY_BUFFER_BINDING  : GLenum;
    
    public var STREAM_DRAW                   : GLenum;
    public var STATIC_DRAW                   : GLenum;
    public var DYNAMIC_DRAW                  : GLenum;
    
    public var BUFFER_SIZE                   : GLenum;
    public var BUFFER_USAGE                  : GLenum;
    
    public var CURRENT_VERTEX_ATTRIB         : GLenum;
    
    /* CullFaceMode */
    public var FRONT                         : GLenum;
    public var BACK                          : GLenum;
    public var FRONT_AND_BACK                : GLenum;
    
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
    public var TEXTURE_2D                    : GLenum;
    public var CULL_FACE                     : GLenum;
    public var BLEND                         : GLenum;
    public var DITHER                        : GLenum;
    public var STENCIL_TEST                  : GLenum;
    public var DEPTH_TEST                    : GLenum;
    public var SCISSOR_TEST                  : GLenum;
    public var POLYGON_OFFSET_FILL           : GLenum;
    public var SAMPLE_ALPHA_TO_COVERAGE      : GLenum;
    public var SAMPLE_COVERAGE               : GLenum;
    
    /* ErrorCode */
    public var NO_ERROR                      : GLenum;
    public var INVALID_ENUM                  : GLenum;
    public var INVALID_VALUE                 : GLenum;
    public var INVALID_OPERATION             : GLenum;
    public var OUT_OF_MEMORY                 : GLenum;
    
    /* FrontFaceDirection */
    public var CW                            : GLenum;
    public var CCW                           : GLenum;
    
    /* GetPName */
    public var LINE_WIDTH                    : GLenum;
    public var ALIASED_POINT_SIZE_RANGE      : GLenum;
    public var ALIASED_LINE_WIDTH_RANGE      : GLenum;
    public var CULL_FACE_MODE                : GLenum;
    public var FRONT_FACE                    : GLenum;
    public var DEPTH_RANGE                   : GLenum;
    public var DEPTH_WRITEMASK               : GLenum;
    public var DEPTH_CLEAR_VALUE             : GLenum;
    public var DEPTH_FUNC                    : GLenum;
    public var STENCIL_CLEAR_VALUE           : GLenum;
    public var STENCIL_FUNC                  : GLenum;
    public var STENCIL_FAIL                  : GLenum;
    public var STENCIL_PASS_DEPTH_FAIL       : GLenum;
    public var STENCIL_PASS_DEPTH_PASS       : GLenum;
    public var STENCIL_REF                   : GLenum;
    public var STENCIL_VALUE_MASK            : GLenum;
    public var STENCIL_WRITEMASK             : GLenum;
    public var STENCIL_BACK_FUNC             : GLenum;
    public var STENCIL_BACK_FAIL             : GLenum;
    public var STENCIL_BACK_PASS_DEPTH_FAIL  : GLenum;
    public var STENCIL_BACK_PASS_DEPTH_PASS  : GLenum;
    public var STENCIL_BACK_REF              : GLenum;
    public var STENCIL_BACK_VALUE_MASK       : GLenum;
    public var STENCIL_BACK_WRITEMASK        : GLenum;
    public var VIEWPORT                      : GLenum;
    public var SCISSOR_BOX                   : GLenum;
    /*      SCISSOR_TEST */
    public var COLOR_CLEAR_VALUE             : GLenum;
    public var COLOR_WRITEMASK               : GLenum;
    public var UNPACK_ALIGNMENT              : GLenum;
    public var PACK_ALIGNMENT                : GLenum;
    public var MAX_TEXTURE_SIZE              : GLenum;
    public var MAX_VIEWPORT_DIMS             : GLenum;
    public var SUBPIXEL_BITS                 : GLenum;
    public var RED_BITS                      : GLenum;
    public var GREEN_BITS                    : GLenum;
    public var BLUE_BITS                     : GLenum;
    public var ALPHA_BITS                    : GLenum;
    public var DEPTH_BITS                    : GLenum;
    public var STENCIL_BITS                  : GLenum;
    public var POLYGON_OFFSET_UNITS          : GLenum;
    /*      POLYGON_OFFSET_FILL */
    public var POLYGON_OFFSET_FACTOR         : GLenum;
    public var TEXTURE_BINDING_2D            : GLenum;
    public var SAMPLE_BUFFERS                : GLenum;
    public var SAMPLES                       : GLenum;
    public var SAMPLE_COVERAGE_VALUE         : GLenum;
    public var SAMPLE_COVERAGE_INVERT        : GLenum;
    
    /* GetTextureParameter */
    /*      TEXTURE_MAG_FILTER */
    /*      TEXTURE_MIN_FILTER */
    /*      TEXTURE_WRAP_S */
    /*      TEXTURE_WRAP_T */
    
    public var NUM_COMPRESSED_TEXTURE_FORMATS: GLenum;
    public var COMPRESSED_TEXTURE_FORMATS    : GLenum;
    
    /* HintMode */
    public var DONT_CARE                     : GLenum;
    public var FASTEST                       : GLenum;
    public var NICEST                        : GLenum;
    
    /* HintTarget */
    public var GENERATE_MIPMAP_HINT           : GLenum;
    
    /* DataType */
    public var BYTE                          : GLenum;
    public var UNSIGNED_BYTE                 : GLenum;
    public var SHORT                         : GLenum;
    public var UNSIGNED_SHORT                : GLenum;
    public var INT                           : GLenum;
    public var UNSIGNED_INT                  : GLenum;
    public var FLOAT                         : GLenum;
    
    /* PixelFormat */
    public var DEPTH_COMPONENT               : GLenum;
    public var ALPHA                         : GLenum;
    public var RGB                           : GLenum;
    public var RGBA                          : GLenum;
    public var LUMINANCE                     : GLenum;
    public var LUMINANCE_ALPHA               : GLenum;
    
    /* PixelType */
    /*      UNSIGNED_BYTE */
    public var UNSIGNED_SHORT_4_4_4_4        : GLenum;
    public var UNSIGNED_SHORT_5_5_5_1        : GLenum;
    public var UNSIGNED_SHORT_5_6_5          : GLenum;
    
    /* Shaders */
    public var FRAGMENT_SHADER                 : GLenum;
    public var VERTEX_SHADER                   : GLenum;
    public var MAX_VERTEX_ATTRIBS              : GLenum;
    public var MAX_VERTEX_UNIFORM_VECTORS      : GLenum;
    public var MAX_VARYING_VECTORS             : GLenum;
    public var MAX_COMBINED_TEXTURE_IMAGE_UNITS: GLenum;
    public var MAX_VERTEX_TEXTURE_IMAGE_UNITS  : GLenum;
    public var MAX_TEXTURE_IMAGE_UNITS         : GLenum;
    public var MAX_FRAGMENT_UNIFORM_VECTORS    : GLenum;
    public var SHADER_TYPE                     : GLenum;
    public var DELETE_STATUS                   : GLenum;
    public var LINK_STATUS                     : GLenum;
    public var VALIDATE_STATUS                 : GLenum;
    public var ATTACHED_SHADERS                : GLenum;
    public var ACTIVE_UNIFORMS                 : GLenum;
    public var ACTIVE_UNIFORM_MAX_LENGTH       : GLenum;
    public var ACTIVE_ATTRIBUTES               : GLenum;
    public var ACTIVE_ATTRIBUTE_MAX_LENGTH     : GLenum;
    public var SHADING_LANGUAGE_VERSION        : GLenum;
    public var CURRENT_PROGRAM                 : GLenum;
    
    /* StencilFunction */
    public var NEVER                         : GLenum;
    public var LESS                          : GLenum;
    public var EQUAL                         : GLenum;
    public var LEQUAL                        : GLenum;
    public var GREATER                       : GLenum;
    public var NOTEQUAL                      : GLenum;
    public var GEQUAL                        : GLenum;
    public var ALWAYS                        : GLenum;
    
    /* StencilOp */
    /*      ZERO */
    public var KEEP                          : GLenum;
    public var REPLACE                       : GLenum;
    public var INCR                          : GLenum;
    public var DECR                          : GLenum;
    public var INVERT                        : GLenum;
    public var INCR_WRAP                     : GLenum;
    public var DECR_WRAP                     : GLenum;
    
    /* StringName */
    public var VENDOR                        : GLenum;
    public var RENDERER                      : GLenum;
    public var VERSION                       : GLenum;
    public var EXTENSIONS                    : GLenum;
    
    /* TextureMagFilter */
    public var NEAREST                       : GLenum;
    public var LINEAR                        : GLenum;
    
    /* TextureMinFilter */
    /*      NEAREST */
    /*      LINEAR */
    public var NEAREST_MIPMAP_NEAREST        : GLenum;
    public var LINEAR_MIPMAP_NEAREST         : GLenum;
    public var NEAREST_MIPMAP_LINEAR         : GLenum;
    public var LINEAR_MIPMAP_LINEAR          : GLenum;
    
    /* TextureParameterName */
    public var TEXTURE_MAG_FILTER            : GLenum;
    public var TEXTURE_MIN_FILTER            : GLenum;
    public var TEXTURE_WRAP_S                : GLenum;
    public var TEXTURE_WRAP_T                : GLenum;
    
    /* TextureTarget */
    /*      TEXTURE_2D */
    public var TEXTURE                       : GLenum;
    
    public var TEXTURE_CUBE_MAP              : GLenum;
    public var TEXTURE_BINDING_CUBE_MAP      : GLenum;
    public var TEXTURE_CUBE_MAP_POSITIVE_X   : GLenum;
    public var TEXTURE_CUBE_MAP_NEGATIVE_X   : GLenum;
    public var TEXTURE_CUBE_MAP_POSITIVE_Y   : GLenum;
    public var TEXTURE_CUBE_MAP_NEGATIVE_Y   : GLenum;
    public var TEXTURE_CUBE_MAP_POSITIVE_Z   : GLenum;
    public var TEXTURE_CUBE_MAP_NEGATIVE_Z   : GLenum;
    public var MAX_CUBE_MAP_TEXTURE_SIZE     : GLenum;
    
    /* TextureUnit */
    public var TEXTURE0                      : GLenum;
    public var TEXTURE1                      : GLenum;
    public var TEXTURE2                      : GLenum;
    public var TEXTURE3                      : GLenum;
    public var TEXTURE4                      : GLenum;
    public var TEXTURE5                      : GLenum;
    public var TEXTURE6                      : GLenum;
    public var TEXTURE7                      : GLenum;
    public var TEXTURE8                      : GLenum;
    public var TEXTURE9                      : GLenum;
    public var TEXTURE10                     : GLenum;
    public var TEXTURE11                     : GLenum;
    public var TEXTURE12                     : GLenum;
    public var TEXTURE13                     : GLenum;
    public var TEXTURE14                     : GLenum;
    public var TEXTURE15                     : GLenum;
    public var TEXTURE16                     : GLenum;
    public var TEXTURE17                     : GLenum;
    public var TEXTURE18                     : GLenum;
    public var TEXTURE19                     : GLenum;
    public var TEXTURE20                     : GLenum;
    public var TEXTURE21                     : GLenum;
    public var TEXTURE22                     : GLenum;
    public var TEXTURE23                     : GLenum;
    public var TEXTURE24                     : GLenum;
    public var TEXTURE25                     : GLenum;
    public var TEXTURE26                     : GLenum;
    public var TEXTURE27                     : GLenum;
    public var TEXTURE28                     : GLenum;
    public var TEXTURE29                     : GLenum;
    public var TEXTURE30                     : GLenum;
    public var TEXTURE31                     : GLenum;
    public var ACTIVE_TEXTURE                : GLenum;
    
    /* TextureWrapMode */
    public var REPEAT                        : GLenum;
    public var CLAMP_TO_EDGE                 : GLenum;
    public var MIRRORED_REPEAT               : GLenum;
    
    /* Uniform Types */
    public var FLOAT_VEC2                    : GLenum;
    public var FLOAT_VEC3                    : GLenum;
    public var FLOAT_VEC4                    : GLenum;
    public var INT_VEC2                      : GLenum;
    public var INT_VEC3                      : GLenum;
    public var INT_VEC4                      : GLenum;
    public var BOOL                          : GLenum;
    public var BOOL_VEC2                     : GLenum;
    public var BOOL_VEC3                     : GLenum;
    public var BOOL_VEC4                     : GLenum;
    public var FLOAT_MAT2                    : GLenum;
    public var FLOAT_MAT3                    : GLenum;
    public var FLOAT_MAT4                    : GLenum;
    public var SAMPLER_2D                    : GLenum;
    public var SAMPLER_CUBE                  : GLenum;
    
    /* Vertex Arrays */
    public var VERTEX_ATTRIB_ARRAY_ENABLED       : GLenum;
    public var VERTEX_ATTRIB_ARRAY_SIZE          : GLenum;
    public var VERTEX_ATTRIB_ARRAY_STRIDE        : GLenum;
    public var VERTEX_ATTRIB_ARRAY_TYPE          : GLenum;
    public var VERTEX_ATTRIB_ARRAY_NORMALIZED    : GLenum;
    public var VERTEX_ATTRIB_ARRAY_POINTER       : GLenum;
    public var VERTEX_ATTRIB_ARRAY_BUFFER_BINDING: GLenum;
    
    /* Read Format */
    public var IMPLEMENTATION_COLOR_READ_TYPE  : GLenum;
    public var IMPLEMENTATION_COLOR_READ_FORMAT: GLenum;
    
    /* Shader Source */
    public var COMPILE_STATUS                : GLenum;
    public var INFO_LOG_LENGTH               : GLenum;
    public var SHADER_SOURCE_LENGTH          : GLenum;
    public var SHADER_COMPILER               : GLenum;
    
    /* Shader Precision-Specified Types */
    public var LOW_FLOAT                     : GLenum;
    public var MEDIUM_FLOAT                  : GLenum;
    public var HIGH_FLOAT                    : GLenum;
    public var LOW_INT                       : GLenum;
    public var MEDIUM_INT                    : GLenum;
    public var HIGH_INT                      : GLenum;
    
    /* Framebuffer Object. */
    public var FRAMEBUFFER                   : GLenum;
    public var RENDERBUFFER                  : GLenum;
    
    public var RGBA4                         : GLenum;
    public var RGB5_A1                       : GLenum;
    public var RGB565                        : GLenum;
    public var DEPTH_COMPONENT16             : GLenum;
    public var STENCIL_INDEX                 : GLenum;
    public var STENCIL_INDEX8                : GLenum;
    
    public var RENDERBUFFER_WIDTH            : GLenum;
    public var RENDERBUFFER_HEIGHT           : GLenum;
    public var RENDERBUFFER_INTERNAL_FORMAT  : GLenum;
    public var RENDERBUFFER_RED_SIZE         : GLenum;
    public var RENDERBUFFER_GREEN_SIZE       : GLenum;
    public var RENDERBUFFER_BLUE_SIZE        : GLenum;
    public var RENDERBUFFER_ALPHA_SIZE       : GLenum;
    public var RENDERBUFFER_DEPTH_SIZE       : GLenum;
    public var RENDERBUFFER_STENCIL_SIZE     : GLenum;
    
    public var FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE          : GLenum;
    public var FRAMEBUFFER_ATTACHMENT_OBJECT_NAME          : GLenum;
    public var FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL        : GLenum;
    public var FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE: GLenum;
    
    public var COLOR_ATTACHMENT0             : GLenum;
    public var DEPTH_ATTACHMENT              : GLenum;
    public var STENCIL_ATTACHMENT            : GLenum;
    
    public var NONE                          : GLenum;
    
    public var FRAMEBUFFER_COMPLETE                     : GLenum;
    public var FRAMEBUFFER_INCOMPLETE_ATTACHMENT        : GLenum;
    public var FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: GLenum;
    public var FRAMEBUFFER_INCOMPLETE_DIMENSIONS        : GLenum;
    public var FRAMEBUFFER_UNSUPPORTED                  : GLenum;
    
    public var FRAMEBUFFER_BINDING           : GLenum;
    public var RENDERBUFFER_BINDING          : GLenum;
    public var MAX_RENDERBUFFER_SIZE         : GLenum;
    
    public var INVALID_FRAMEBUFFER_OPERATION : GLenum;
    
    var canvas(default,null):HTMLCanvasElement;

    function getContextAttributes():WebGLContextAttributes;

    function activeTexture(texture:GLenum):Void;
    function attachShader(program:WebGLProgram, shader:WebGLShader):Void;
    function bindAttribLocation(program:WebGLProgram, index:GLuint, name:DOMString):Void;

    function bindBuffer(target:GLenum, buffer:WebGLBuffer):Void;
    function bindFramebuffer(target:GLenum, framebuffer:WebGLFramebuffer):Void;

    function bindRenderbuffer(target:GLenum, renderbuffer:WebGLRenderbuffer):Void;

    function bindTexture(target:GLenum, texture:WebGLTexture):Void;
    function blendColor(red:GLclampf, green:GLclampf, blue:GLclampf, alpha:GLclampf):Void;

    function blendEquation(mode:GLenum):Void;
    function blendEquationSeparate(modeRGB:GLenum, modeAlpha:GLenum):Void;
    function blendFunc(sfactor:GLenum, dfactor:GLenum):Void;
    function blendFuncSeparate(srcRGB:GLenum, dstRGB:GLenum, 
                           srcAlpha:GLenum, dstAlpha:GLenum):Void;

    function bufferData(target:GLenum, size:Dynamic, usage:GLenum):Void;
    //function bufferData(target:GLenum, size:GLsizei, usage:GLenum):Void;
    //function bufferData(target:GLenum, data:WebGLArray, usage:GLenum):Void;
    //function bufferData(target:GLenum, data:WebGLArrayBuffer, usage:GLenum):Void;

    function bufferSubData(target:GLenum, offset:GLsizeiptr, data:Dynamic):Void;
    //function bufferSubData(target:GLenum, offset:GLsizeiptr, data:WebGLArray):Void;
    //function bufferSubData(target:GLenum, offset:GLsizeiptr, data:WebGLArrayBuffer):Void;


    function checkFramebufferStatus(target:GLenum):GLenum ;
    function clear(mask:GLbitfield):Void;
    function clearColor(red:GLclampf, green:GLclampf, blue:GLclampf, alpha:GLclampf):Void;

    function clearDepth(depth:GLclampf):Void;
    function clearStencil(s:GLint):Void;
    function colorMask(red:GLboolean, green:GLboolean, blue:GLboolean, alpha:GLboolean):Void;

    function compileShader(shader:WebGLShader):Void;

    function copyTexImage2D(target:GLenum, level:GLint, internalformat:GLenum, 
                        x:GLint, y:GLint, width:GLsizei, height:GLsizei, 
                        border:GLint):Void;
    function copyTexSubImage2D(target:GLenum, level:GLint, xoffset:GLint, yoffset:GLint, 
                           x:GLint, y:GLint, width:GLsizei, height:GLsizei):Void;


    function createBuffer():WebGLBuffer;
    function createFramebuffer():WebGLFramebuffer;
    function createProgram():WebGLProgram;
    function createRenderbuffer():WebGLRenderbuffer;
    function createShader(type:GLenum):WebGLShader;
    function createTexture():WebGLTexture;

    function cullFace(mode:GLenum):Void;

    function deleteBuffer(buffer:WebGLBuffer):Void;
    function deleteFramebuffer(framebuffer:WebGLFramebuffer):Void;
    function deleteProgram(program:WebGLProgram):Void;
    function deleteRenderbuffer(renderbuffer:WebGLRenderbuffer):Void;
    function deleteShader(shader:WebGLShader):Void;
    function deleteTexture(texture:WebGLTexture):Void;

    function depthFunc(func:GLenum):Void;
    function depthMask(flag:GLboolean):Void;
    function depthRange(zNear:GLclampf, zFar:GLclampf):Void;
    function detachShader(program:WebGLProgram, shader:WebGLShader):Void;
    function disable(cap:GLenum):Void;
    function disableVertexAttribArray(index:GLuint):Void;
    function drawArrays(mode:GLenum, first:GLint, count:GLsizei):Void;
    function drawElements(mode:GLenum, count:GLsizei, type:GLenum, offset:GLsizeiptr):Void;


    function enable(cap:GLenum):Void;
    function enableVertexAttribArray(index:GLuint):Void;
    function finish():Void;
    function flush():Void;
    function framebufferRenderbuffer(target:GLenum, attachment:GLenum, 
                                 renderbuffertarget:GLenum, 
                                 renderbuffer:WebGLRenderbuffer):Void;
    function framebufferTexture2D(target:GLenum, attachment:GLenum, textarget:GLenum, 
                              texture:WebGLTexture, level:GLint):Void;
    function frontFace(mode:GLenum):Void;

    function generateMipmap(target:GLenum):Void;

    function getActiveAttrib(program:WebGLProgram, index:GLuint):WebGLActiveInfo;
    function getActiveUniform(program:WebGLProgram, index:GLuint):WebGLActiveInfo;
    function getAttachedShaders(program:WebGLProgram):Array<WebGLShader>;

    function getAttribLocation(program:WebGLProgram, name:DOMString):GLint;

    function getParameter(pname:GLenum):Dynamic;
    function getBufferParameter(target:GLenum, pname:GLenum):Dynamic;

    function getError():GLenum;

    function getFramebufferAttachmentParameter(target:GLenum, attachment:GLenum, 
                                          pname:GLenum):Dynamic;
    function getProgramParameter(program:WebGLProgram, pname:GLenum):Dynamic;
    function getProgramInfoLog(program:WebGLProgram):DOMString;
    function getRenderbufferParameter(target:GLenum, pname:GLenum):Dynamic;
    function getShaderParameter(shader:WebGLShader, pname:GLenum):Dynamic;
    function getShaderInfoLog(shader:WebGLShader):DOMString;

    function getShaderSource(shader:WebGLShader):DOMString;
    function getString(name:GLenum):DOMString;

    function getTexParameter(target:GLenum, pname:GLenum):Dynamic;

    function getUniform(program:WebGLProgram, location:WebGLUniformLocation):Dynamic;

    function getUniformLocation(program:WebGLProgram, name:DOMString):WebGLUniformLocation ;

    function getVertexAttrib(index:GLuint, pname:GLenum):Dynamic;

    function getVertexAttribOffset(index:GLuint, pname:GLenum):GLsizeiptr;

    function hint(target:GLenum, mode:GLenum):Void;
    function isBuffer(buffer:WebGLObject) :GLboolean;
    function isEnabled(cap:GLenum) :GLboolean;
    function isFramebuffer(framebuffer:WebGLObject) :GLboolean;
    function isProgram(program:WebGLObject) :GLboolean;
    function isRenderbuffer(renderbuffer:WebGLObject) :GLboolean;
    function isShader(shader:WebGLObject) :GLboolean;
    function isTexture(texture:WebGLObject) :GLboolean;
    function lineWidth(width:GLfloat):Void;
    function linkProgram(program:WebGLProgram):Void;
    function pixelStorei(pname:GLenum, param:GLint):Void;
    function polygonOffset(factor:GLfloat, units:GLfloat):Void;

    function readPixels(x:GLint, y:GLint, width:GLsizei, height:GLsizei, 
                           format:GLenum, type:GLenum):Void;

    function renderbufferStorage(target:GLenum, internalformat:GLenum, 
                             width:GLsizei, height:GLsizei):Void;
    function sampleCoverage(value:GLclampf, invert:GLboolean):Void;
    function scissor(x:GLint, y:GLint, width:GLsizei, height:GLsizei):Void;


    function shaderSource(shader:WebGLShader, source:DOMString):Void;

    function stencilFunc(func:GLenum, ref:GLint, mask:GLuint):Void;
    function stencilFuncSeparate(face:GLenum, func:GLenum, ref:GLint, mask:GLuint):Void;

    function stencilMask(mask:GLuint):Void;
    function stencilMaskSeparate(face:GLenum, mask:GLuint):Void;
    function stencilOp(fail:GLenum, zfail:GLenum, zpass:GLenum):Void;
    function stencilOpSeparate(face:GLenum, fail:GLenum, zfail:GLenum, zpass:GLenum):Void;


    function texImage2D(target:GLenum, level:GLint, v1:Dynamic, 
		    ?v2:Dynamic, ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic,
		    ?v6:Dynamic, ?v7:Dynamic):Void;
/*
    function texImage2D(target:GLenum, level:GLint, internalformat:GLenum, 
                    width:GLsizei, height:GLsizei, border:GLint, format:GLenum, 
                    type:GLenum, pixels:WebGLArray):Void;

    function texImage2D(target:GLenum, level:GLint, pixels:ImageData,
                    ?flipY:GLboolean, ?asPremultipliedAlpha:GLboolean):Void; 

    function texImage2D(target:GLenum, level:GLint, image:HTMLImageElement,
                    ?flipY:GLboolean, ?asPremultipliedAlpha:GLboolean):Void; 

    function texImage2D(target:GLenum, level:GLint, image:HTMLCanvasElement,
                    ?flipY:GLboolean, ?asPremultipliedAlpha:GLboolean):Void; 

    function texImage2D(target:GLenum, level:GLint, image:HTMLVideoElement,
                    ?flipY:GLboolean, ?asPremultipliedAlpha:GLboolean):Void; 
*/


    function texParameterf(target:GLenum, pname:GLenum, param:GLfloat):Void;

    function texParameteri(target:GLenum, pname:GLenum, param:GLint):Void;

    function texSubImage2D(target:GLenum, level:GLint, xoffset:GLint, yoffset:GLint,
		    v1:Dynamic, ?v2:Dynamic, 
		    ?v3:Dynamic, ?v4:Dynamic, ?v5:Dynamic):Void;
/*
    function texSubImage2D(target:GLenum, level:GLint, xoffset:GLint, yoffset:GLint, 
                       width:GLsizei, height:GLsizei, 
                       format:GLenum, type:GLenum, pixels:WebGLArray):Void;

    function texSubImage2D(target:GLenum, level:GLint, xoffset:GLint, yoffset:GLint, 
                       pixels:ImageData,
                       ?flipY:GLboolean, ?asPremultipliedAlpha:GLboolean):Void;

    function texSubImage2D(target:GLenum, level:GLint, xoffset:GLint, yoffset:GLint, 
                       image:HTMLImageElement,
                       ?flipY:GLboolean, ?asPremultipliedAlpha:GLboolean):Void;

    function texSubImage2D(target:GLenum, level:GLint, xoffset:GLint, yoffset:GLint, 
                       image:HTMLCanvasElement,
                       ?flipY:GLboolean, ?asPremultipliedAlpha:GLboolean):Void;

    function texSubImage2D(target:GLenum, level:GLint, xoffset:GLint, yoffset:GLint, 
                       image:HTMLVideoElement,
                       ?flipY:GLboolean, ?asPremultipliedAlpha:GLboolean):Void;
*/


    function uniform1f(location:WebGLUniformLocation, x:GLfloat):Void;
    function uniform1fv(location:WebGLUniformLocation, v:Dynamic):Void;
    //function uniform1fv(location:WebGLUniformLocation, v:WebGLFloatArray):Void;
    //function uniform1fv(location:WebGLUniformLocation, v:Array<Float>):Void;
    function uniform1i(location:WebGLUniformLocation, x:GLint):Void;
    function uniform1iv(location:WebGLUniformLocation, v:Dynamic):Void;
    //function uniform1iv(location:WebGLUniformLocation, v:WebGLIntArray):Void;
    //function uniform1iv(location:WebGLUniformLocation, v:Array<Int>):Void;
    function uniform2f(location:WebGLUniformLocation, x:GLfloat, y:GLfloat):Void;
    function uniform2fv(location:WebGLUniformLocation, v:Dynamic):Void;
    //function uniform2fv(location:WebGLUniformLocation, v:WebGLFloatArray):Void;
    //function uniform2fv(location:WebGLUniformLocation, v:Array<Float>):Void;
    function uniform2i(location:WebGLUniformLocation, x:GLint, y:GLint):Void;
    function uniform2iv(location:WebGLUniformLocation, v:Dynamic):Void;
    //function uniform2iv(location:WebGLUniformLocation, v:WebGLIntArray):Void;
    //function uniform2iv(location:WebGLUniformLocation, v:Array<Int>):Void;
    function uniform3f(location:WebGLUniformLocation, x:GLfloat, y:GLfloat, z:GLfloat):Void;

    function uniform3fv(location:WebGLUniformLocation, v:Dynamic):Void;
    //function uniform3fv(location:WebGLUniformLocation, v:WebGLFloatArray):Void;
    //function uniform3fv(location:WebGLUniformLocation, v:Array<Float>):Void;
    function uniform3i(location:WebGLUniformLocation, x:GLint, y:GLint, z:GLint):Void;
    function uniform3iv(location:WebGLUniformLocation, v:Dynamic):Void;
    //function uniform3iv(location:WebGLUniformLocation, v:WebGLIntArray):Void;
    //function uniform3iv(location:WebGLUniformLocation, v:Array<Int>):Void;
    function uniform4f(location:WebGLUniformLocation, x:GLfloat, y:GLfloat, z:GLfloat, w:GLfloat):Void;

    function uniform4fv(location:WebGLUniformLocation, v:Dynamic):Void;
    //function uniform4fv(location:WebGLUniformLocation, v:WebGLFloatArray):Void;
    //function uniform4fv(location:WebGLUniformLocation, v:Array<Float>):Void;
    function uniform4i(location:WebGLUniformLocation, x:GLint, y:GLint, z:GLint, w:GLint):Void;

    function uniform4iv(location:WebGLUniformLocation, v:ArrayAccess<Int>):Void;
    //function uniform4iv(location:WebGLUniformLocation, v:Array<Int>):Void;

    function uniformMatrix2fv(location:WebGLUniformLocation, transpose:GLboolean, 
                          value:Dynamic):Void;
    //function uniformMatrix2fv(location:WebGLUniformLocation, transpose:GLboolean, 
    //                      value:WebGLFloatArray):Void;
    //function uniformMatrix2fv(location:WebGLUniformLocation, transpose:GLboolean, 
    //                      value:Array<Float>):Void;
    function uniformMatrix3fv(location:WebGLUniformLocation, transpose:GLboolean, 
                          value:Dynamic):Void;
    //function uniformMatrix3fv(location:WebGLUniformLocation, transpose:GLboolean, 
    //                      value:WebGLFloatArray):Void;
    //function uniformMatrix3fv(location:WebGLUniformLocation, transpose:GLboolean, 
    //                      value:Array<Float>):Void;
    function uniformMatrix4fv(location:WebGLUniformLocation, transpose:GLboolean, 
                          value:Dynamic):Void;
    //function uniformMatrix4fv(location:WebGLUniformLocation, transpose:GLboolean, 
    //                      value:WebGLFloatArray):Void;
    //function uniformMatrix4fv(location:WebGLUniformLocation, transpose:GLboolean, 
    //                      value:Array<Float>):Void;

    function useProgram(program:WebGLProgram):Void;
    function validateProgram(program:WebGLProgram):Void;

    function vertexAttrib1f(indx:GLuint, x:GLfloat):Void;
    function vertexAttrib1fv(indx:GLuint, values:Dynamic):Void;
    //function vertexAttrib1fv(indx:GLuint, values:WebGLFloatArray):Void;
    //function vertexAttrib1fv(indx:GLuint, values:Array<Float>):Void;
    function vertexAttrib2f(indx:GLuint, x:GLfloat, y:GLfloat):Void;
    function vertexAttrib2fv(indx:GLuint, values:Dynamic):Void;
    //function vertexAttrib2fv(indx:GLuint, values:WebGLFloatArray):Void;
    //function vertexAttrib2fv(indx:GLuint, values:Array<Float>):Void;
    function vertexAttrib3f(indx:GLuint, x:GLfloat, y:GLfloat, z:GLfloat):Void;

    function vertexAttrib3fv(indx:GLuint, values:Dynamic):Void;
    //function vertexAttrib3fv(indx:GLuint, values:WebGLFloatArray):Void;
    //function vertexAttrib3fv(indx:GLuint, values:Array<Float>):Void;
    function vertexAttrib4f(indx:GLuint, x:GLfloat, y:GLfloat, z:GLfloat, w:GLfloat):Void;

    function vertexAttrib4fv(indx:GLuint, values:Dynamic):Void;
    //function vertexAttrib4fv(indx:GLuint, values:WebGLFloatArray):Void;
    //function vertexAttrib4fv(indx:GLuint, values:Array<Float>):Void;
    function vertexAttribPointer(indx:GLuint, size:GLint, type:GLenum, 
                             normalized:GLboolean, stride:GLsizei,  offset:GLsizeiptr):Void; 

    function viewport(x:GLint, y:GLint, width:GLsizei, height:GLsizei):Void;

}

extern class WebGLResourceLostEvent implements Dynamic {
    var resource:WebGLObject;
    var context:WebGLRenderingContext;
    
    function initWebGLResourceLostEvent(type:DOMString,
                                    canBubble:Bool,
                                    cancelable:Bool,
                                    resource:WebGLObject,
                                    context:WebGLRenderingContext):Void;
}


/* Ref: http://github.com/jdegoes/stax/raw/master/src/main/haxe/Dom.hx 713f4098fd4171c98dd5e613dbb673eb708c41a0 */

import StdTypes;

typedef DOMString = String

typedef DOMTimeStamp = Int

typedef DOMObject = Dynamic;

//typedef Object = Dynamic // Object

typedef DOMUserData = Dynamic //any

extern class DomCollection<T> implements ArrayAccess<T>, implements Dynamic<T> {
	var length (default, null) : Int;
}

// [\t]*readonly attribute long (\w+)
//
/*
* <----------------- Core IDL Port ------------------>
*
*/

extern interface DOMStringMap {
    public function getter(name: DOMString): Void;
    
    public function setter(name: DOMString, value: DOMString): Void;
    
    public function creator(name: DOMString, value: DOMString): Void;
    
    public function deleter(name: DOMString): Void;
}

extern interface DOMTokenList {
    public var length       (default, null): Int;
    
    public function item(index: Int): DOMString;
    
    public function contains(token: DOMString): Bool;
    
    public function add(token: DOMString): Void;
    
    public function remove(token: DOMString): Void;
    
    public function toggle(token: DOMString): Bool;
    
    public function stringifier(): DOMString;
}

extern interface DOMSettableTokenList implements DOMTokenList {
    public var value:       DOMString;
}

extern interface DOMException {
    public var code: Int;
}

extern interface DOMStringList {
    public function item(index: Int): DOMString;
    
    public function contains(str: DOMString): Bool;
    
    public var length       (default,null): Int;
    
}

extern interface NameList {
    public function getName(index: Int): DOMString;
    
    public function getNamespaceURI(index: Int): DOMString;
    
    public function contains(str: DOMString): Bool;
    
    public function containsNS(namespaceURI: DOMString, name: DOMString): Bool;
    
    public var length       (default,null): Int;
}
// Unable to Test
extern interface DOMImplementationSource {
    public function getDOMImplementation(features: DOMString): DOMImplementation;
    
    public function getDOMImplementationList(features: DOMString): DomCollection<DOMImplementation>;
}
//Tested
extern interface DOMImplementation {
    public function hasFeature(feature: DOMString, version: DOMString): Bool;

    public function createDocumentType(qualifiedName: DOMString, publicId: DOMString, systemId: DOMString): DocumentType;

    public function createDocument(namespaceURI: DOMString, qualifiedName: DOMString, doctype: DocumentType): Document;

    public function getFeature(feature: DOMString, version: DOMString): DOMObject;
}

//Tested
extern interface EventTarget {
    public function addEventListener(type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;

    public function removeEventListener(type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;

    public function dispatchEvent(evt: Event): Bool;
    
    public function addEventListenerNS(namespaceURI: DOMString, type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;
    
    public function removeEventListenerNS(namespaceURI: DOMString, type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;
}

//Tested
extern interface Node implements EventTarget {
    public var nodeName         (default,null): DOMString;
    public var nodeValue:       DOMString;  // raises(DOMException) on setting & raises(DOMException) on retrieval
    public var nodeType         (default,null): Int;
    public var parentNode       (default,null): Node;
    public var childNodes       (default,null): DomCollection<Node>;
    public var firstChild       (default,null): Node;
    public var lastChild        (default,null): Node;
    public var previousSibling  (default,null): Node;
    public var nextSibling      (default,null): Node;
    public var attributes       (default,null): NamedNodeMap;
    public var ownerDocument    (default,null): Document;
    
    public function hasChildNodes(): Bool;
    
    public function insertBefore(newChild: Node, refChild: Node): Node;
    
    public function replaceChild(newChild: Node, oldChild: Node): Node;
    
    public function removeChild(oldChild: Node): Node;
    
    public function appendChild(newChild: Node): Node;
    
    public function cloneNode(deep: Bool): Node;
    
    public function isSupported(feature: DOMString, version: DOMString): Bool;
    
    public function hasAttributes(): Bool;
    
    public var namespaceURI     (default,null): DOMString;
    public var prefix           (default,null): DOMString;                      
    public var localName        (default,null): DOMString;
    public var baseURI          (default,null): DOMString;
    public var textContent:     DOMString;
    
    
    public function compareDocumentPosition(other: Node): Int;
    
    public function isSameNode(other: Node): Bool;
    
    public function lookupPrefix(namespaceURI: DOMString): DOMString;
    
    public function isDefaultNamespace(namespaceURI: DOMString): Bool;
    
    public function lookupNamespaceUrI(prefix: DOMString): DOMString;
    
    public function isEqualNode(arg: Node): Bool;
    
    public function getFeature(feature: DOMString, version: DOMString): DOMObject;
    
    public function setUserData(key: DOMString, data: DOMUserData, handler: UserDataHandler): DOMUserData;
    
    public function getUserData(key: DOMString): DOMUserData;
}
//Tested
extern interface NamedNodeMap {
    public function getNamedItem(name: DOMString): Node;
    
    public function setNamedItem(arg: Node): Node;
    
    public function removeNamedItem(name: DOMString): Void;
    
    public function item(index: Int): Node;
    
    public function getNamedItemNS(namespaceURI: DOMString, localName: DOMString): Node;
    
    public function setNamedItemNS(arg: Node): Node;
    
    public function removeNamedItemNS(namespaceURI: DOMString, localName: DOMString): Node;
    
    public var length (default,null): Int;
}
//Tested throuh Text
extern interface CharacterData implements Node {
    public var data:    DOMString;
    public var length   (default,null): Int;
    
    public function substringData(offset: Int, count: Int): DOMString;
    
    public function appendData(arg: DOMString): Void;
    
    public function insertData(offset: Int, arg: DOMString): Void;
    
    public function deleteData(offset: Int, count: Int): Void;
    
    public function replaceData(offset: Int, count: Int, arg: DOMString): Void;
}
//Tested
extern interface Attr implements Node {
    public var name             (default,null): DOMString;
    public var specified        (default,null): Bool;
    public var value            (default,null): DOMString;
    public var ownerElement     (default,null): Element;
    public var schemaTypeInfo   (default,null): TypeInfo;
    public var isID             (default,null): Bool;
}
//Tested
extern interface Element implements Node {
    public var schemaTypeInfo   (default,null): TypeInfo;
    public var tagName          (default, null): DOMString;
    public var scrollTop:       Int;  
    public var scrollLeft:      Int; 
    public var scrollWidth      (default, null): Int;
    public var scrollHeight     (default, null): Int;
    public var clientTop        (default, null): Int;
    public var clientLeft       (default, null): Int;
    public var clientWidth      (default, null): Int;
    public var clientHeight     (default, null): Int;
    public var offsetParent     (default, null): HTMLElement;
    
    public function getAttribute(name: DOMString): DOMString;
    
    public function setAttribute(name: DOMString, value: DOMString): Void;
    
    public function removeAttribute(name: DOMString): Void;
    
    public function getAttributeNode(name: DOMString): Attr;
    
    public function setAttributeNode(newAttr: Attr): Attr;
    
    public function removeAttributeNode(oldAttr: Attr): Attr;
    
    public function getElementsByTagName(name: DOMString): DomCollection<Node>;
    
    public function getAttributeNS(namespaceURI: DOMString, localName: DOMString): DOMString;
    
    public function setAttributeNS(namespaceURI: DOMString, qualifiedName: DOMString, value: DOMString): Void;
    
    public function removeAttributeNS(namespaceURI: DOMString, localName: DOMString): Void;
    
    public function getAttributeNodeNS(namespaceURI: DOMString, localName: DOMString): Attr;
    
    public function setAttributeNodeNS(newAttr: Attr): Attr;
    
    public function getElementsByTagNameNS(namespaceURI: DOMString, localName: DOMString): DomCollection<Node>;
    
    public function hasAttribute(name: DOMString): Bool;
    
    public function hasAttributeNS(namespaceURI: DOMString, localname: DOMString): Bool;
    
    public function setIdAttribute(name: DOMString, isId: Bool): Void;
    
    public function setIdAttributeNS(namespaceURI: DOMString, localname: DOMString, isId: Bool): Void;
    
    public function setIdAttributeNode(idAttr: Attr, isId: Bool): Void;
    
    public function getClientRects(): DomCollection<ClientRect>;
    
    public function getBoundingClientRect(): ClientRect;
}
//Tested
extern interface Text implements CharacterData {
    public function splitText(offset: Int): Text;
    
    public function replaceWholeText(content: DOMString): Text;
    
    public var isElementContentWhitespace   (default,null): Bool;
    public var wholeText                    (default,null): DOMString;
}

extern interface Comment implements CharacterData {
    
}

//Unable to Test
extern interface TypeInfo {
    public var typeName         (default,null): DOMString;
    public var typeNamespace    (default,null): DOMString;
    
    public function isDerivedFrom(typeNamespaceArg: DOMString, typeNameArg: DOMString, derivationMethod: Int): Bool;
}

//Unable to Test
extern interface UserDataHandler {
    public function handle(operationType: Int, key: DOMString, data: DOMUserData, src: Node, dst: Node): Void;
}

//Unable to Test
extern interface DOMError {
    public var severity         (default,null): Int;
    public var message          (default,null): DOMString;
    public var type             (default,null): DOMString;
    public var relatedException (default,null): DOMObject;
    public var relatedData      (default,null): DOMObject;
    public var location         (default,null): DOMLocator;
}
//Unable to Test
extern interface DOMErrorHandler {
    public function handleError(error: DOMError): Bool;
}
//Unable to Test
extern interface DOMLocator {
    public var lineNumber   (default,null): Int;
    public var columnNumber (default,null): Int;
    public var byteOffset   (default,null): Int;
    public var utf16Offset  (default,null): Int;
    public var relatedNode  (default,null): Node;
    public var uri          (default,null): DOMString;
}
//Unable to Test
extern interface DOMConfiguration {
    public function setParameter(name: DOMString, value: DOMUserData): Void;
    
    public function getParameter(name: DOMString): DOMUserData;
    
    public function canSetParameter(name: DOMString, value: DOMUserData): Bool;
    
    public var parameterNames(default, null): DOMStringList;
}

extern interface CDATASection implements Text {
    
}
//Tested
extern interface DocumentType implements Node {
    public var name             (default,null): DOMString;
    public var entities         (default,null): NamedNodeMap;
    public var notations        (default,null): NamedNodeMap;
    public var publicId         (default,null): DOMString;
    public var systemId         (default,null): DOMString;
    public var internalSubset   (default,null): DOMString;
}
//Unagle to Test
extern interface Notation implements Node {
    public var publicId         (default,null): DOMString;
    public var systemId         (default,null): DOMString;
}
//Unable to Test
extern interface Entity implements Node {
    public var publicId         (default,null): DOMString;
    public var systemId         (default,null): DOMString;
    public var notationName     (default,null): DOMString;
    public var inputEncoding    (default,null): DOMString;
    public var xmlEncoding      (default,null): DOMString;
    public var xmlVersion       (default,null): DOMString;
}

extern interface EntityReference implements Node {
    
}
//XML Only
extern interface ProcessingInstruction implements Node {
    public var target           (default, null):      DOMString;
    public var data:        DOMString;
}

extern interface DocumentFragment implements Node {
    
}

//Tested
extern interface Document implements Node {
    public var doctype                  (default, null): DocumentType;
    public var implementation           (default, null): DOMImplementation;
    public var documentElement          (default, null): Element;
    public var inputEncoding            (default, null): DOMString;
    public var xmlEncoding              (default, null): DOMString;
    public var domConfig                (default, null): DOMConfiguration;
    
    public var xmlStandalone:           Bool;
    public var xmlVersion:              DOMString;
    public var strictErrorChecking:     Bool;
    public var documentURI:             DOMString;
    
    public var styleSheets:             DomCollection<StyleSheet>;
    public var selectedStyleSheetSet:   DOMStringList;
    public var lastStyleSheetSet        (default, null): DOMString;
    public var preferredStyleSheetSet   (default, null): DOMString;
    public var styleSheetSets           (default, null): DOMStringList;
    
    public function enableStyleSheetsForSet(name: DOMString):Void;    
    
    public var defaultView  (default, null): Window;    
    
    public function createElement(tagName: DOMString): Element;
    
    public function createDocumentFragment(): DocumentFragment;
    
    public function createTextNode(data: DOMString): Text;
    
    public function createComment(data: DOMString): Comment;
    
    public function createCDATASection(data: DOMString): CDATASection;
    
    public function createProcessingInstruction(target: DOMString, data: DOMString): ProcessingInstruction;
    
    public function createAttribute(name: DOMString): Attr;
    
    public function createEntityReference(name: DOMString): EntityReference;
    
    public function getElementsByTagName(tagname: DOMString): DomCollection<Node>;
    
    public function importNode(importedNode: Node, deep: Bool): Node;
    
    public function createElementNS(namespaceURI: DOMString, qualifiedName: DOMString): Element;
    
    public function createAttributeNS(nameSpaceURI: DOMString, qualifiedName: DOMString): Attr;
    
    public function getElementsByTagNameNS(namespaceURI: DOMString, localName: DOMString): DomCollection<Node>;
    
    public function getElementById(elementId: DOMString): HTMLElement;
    
    public function adoptNode(source: Node): Node;
    
    public function normalizeDocument(): Void;
    
    public function renameNode(n: Node, namespaceURI: DOMString, qualifiedName: DOMString): Node;
    
    public function getOverrideStyle(elt: Element, pseudoElt: DOMString): CSSStyleDeclaration;
}

extern interface Storage {
    public var length       (default, null): Int;
    
    public function key(index: Int): DOMString;
    
    public function getIterm(key: DOMString): Dynamic;
    
    public function setIterm(key: DOMString, data: Dynamic): Void;
    
    public function removeItem(key: DOMString): Void;
    
    public function clear(): Void;
}

/*
* <----------------- HTML2 IDL Port ------------------>
*
*/
//Tested
extern interface HTMLCollection {
    public var length (default,null): Int;
    
    public function item(index: Int): Node;
    
    public function namedItem(name: DOMString): Node;
}

extern interface MediaError {
    public var code                     (default, null): Int;
}

extern interface TimedTrack {
    public var kind                 (default, null): DOMString;
    public var label                (default, null): DOMString;
    public var language             (default, null): DOMString;
    public var readyState           (default, null): Int;
    public var onload               (default, null): EventListener<Event>;
    public var onerror              (default, null): EventListener<Event>;
    public var mode                 : Int;
    public var cues                 (default, null): TimedTrackCueList;
    public var activeCues           (default, null): TimedTrackCueList;
    public var onentercue           (default, null): EventListener<Event>;
    public var onexitcue            (default, null): EventListener<Event>;
}

extern interface MutableTimedTrack implements TimedTrack {
    public function addCue(cue: TimedTrackCue): Void;
    
    public function removeCue(cue: TimedTrackCue): Void;
}

extern interface TimedTrackCueList {
    public var length               (default, null): Int;
    
    public function getter(index: Int): TimedTrackCue;
    
    public function getCueById(id: DOMString): TimedTrackCue;
}

extern interface TimedTrackCue {
    public var track                (default, null): TimedTrack;
    public var id                   (default, null): DOMString;
    public var startTime            (default, null): Float;
    public var endTime              (default, null): Float;
    public var pauseOnExit          (default, null): Bool;
    public var direction            (default, null): DOMString;
    public var snapToLines          (default, null): Bool;
    public var linePosition         (default, null): Int;
    public var textPosition         (default, null): Int;
    public var size                 (default, null): Int;
    public var alignment            (default, null): DOMString;
    public var voice                (default, null): DOMString;
    
    public function getCueAsSource(): DOMString;
    
    public function getCueAsHTML(): DocumentFragment;
}

extern interface HTMLMediaElement implements HTMLElement {
    public var tracks                   (default, null): TimedTrack;
    public var error                    (default, null): MediaError;
    public var src                      : DOMString;
    public var currentSrc               (default, null): DOMString;
    public var controls                 : Bool;
    public var volume                   : Float;
    public var muted                    : Bool;
    public var networkState             (default, null): Int;
    public var preload                  : DOMString;
    public var buffered                 (default, null): TimeRanges;
    public var readyState               (default, null): Int;
    public var seeking                  (default, null): Bool;
    public var currentTime: Float;
    public var startTime                (default, null): Float;
    public var duration                 (default, null): Float;
    public var paused                   (default, null): Bool;
    public var defaultPlaybackRate      : Float;
    public var playbackRate             : Float;
    public var played (default, null)   : TimeRanges;
    public var seekable                 (default, null): TimeRanges;
    public var ended                    (default, null): Bool;
    public var autoplay                 : Bool;
    public var loop                     : Bool;
    
    public function play(): Void;
    
    public function pause(): Void;
    
    public function load(): Void;
    
    public function canPlayType(type: DOMString): DOMString;
    
    public function addTrack(label: DOMString, kind: DOMString, language: DOMString): MutableTimedTrack;
}

extern interface HTMLFormControlsCollection implements HTMLCollection {
}

extern interface RadioNodeList implements DomCollection<Node> {
    public var value: DOMString;
}

extern interface HTMLOptionsCollection {
    public var length (default,null): Int;
    
    public function item(index: Int): Node;
    
    public function namedItem(name: DOMString): Node;
}
//Tested
interface Selection {
    public var anchorNode (default, null): Node;
    public var anchorOffset (default, null): Int;
    public var focusNode (default, null): Node;
    public var focusOffset (default, null): Int;
    public var isCollapsed (default, null): Bool;
    public var rangeCount (default, null): Int;
    
    public function collapse(parentNode: Node, offset: Int): Void;
    
    public function collapseToStart(): Void;
    
    public function collapseToEnd(): Void;
    
    public function selectAllChildren(parentNode: Node): Void;
    
    public function deleteFromDocument(): Void;
    
    public function getRangeAt(index: Int): Range;
    
    public function addRange(range: Range): Void;
    
    public function removeRange(range: Range): Void;
    
    public function removeAllRanges(): Void;
    
    public function stringifier(): DOMString;
}

extern interface HTMLDocument implements Document, implements XPathEvaluator {
    public var title:       DOMString;
    public var referrer     (default, null): DOMString;
    public var domain       (default, null): DOMString;
    public var URL          (default, null): DOMString;
    public var body:        HTMLElement;
    public var images       (default, null): HTMLCollection;
    public var applets      (default, null): HTMLCollection;
    public var links        (default, null): HTMLCollection;
    public var forms        (default, null): HTMLCollection;
    public var anchors      (default, null): HTMLCollection;
    public var cookie:      DOMString;
    
    public function getElementsByName(elementName: DOMString): DomCollection<Node>;
    
    public var location (default, null): Location;
    public var lastModified (default, null): DOMString;
    public var compatMode (default, null): DOMString;
    public var charset: DOMString;
    public var characterSet (default, null): DOMString;
    public var defaultCharset (default, null): DOMString;
    public var readyState (default, null): DOMString;

    // DOM tree accessors
    public var dir: DOMString;
    public var head (default, null): HTMLHeadElement;
    public var embeds (default, null): HTMLCollection;
    public var plugins (default, null): HTMLCollection;
    public var scripts (default, null): HTMLCollection;
    
    public function getter(name: DOMString): Dynamic;
    
    
    public function getElementsByClassName(classNames: DOMString): DomCollection<Node>;
    
    // dynamic markup insertion
    public var innerHTML      : DOMString;

    public function open(?type: DOMString, ?replace: DOMString): HTMLDocument;

    public function close(): Void;

    public function write(text: DOMString): Void;

    public function writeln(text: DOMString): Void;

    // user interaction  
    public var activeElement    (default, null): Element;
    public var designMode       :DOMString;
    public var commands         :HTMLCollection;
    
    public function getSelection(): Selection;
    
    public function hasFocus(): Bool;
    
    public function execCommand(commands: DOMString, ?showUI: Bool, ?value: DOMString): Bool;
    
    public function queryCommandEnabled(commandId: DOMString): Bool;
    
    public function queryCommandIndeterm(commandId: DOMString): Bool;
    
    public function queryCommandState(commandId: DOMString): Bool;
    
    public function queryCommandSupported(commandId: DOMString): Bool;
    
    // event handler IDL attributes
    public var onabort: EventListener<Event>;
    public var onblur: EventListener<Event>;
    public var oncanplay: EventListener<Event>;
    public var oncanplaythrough: EventListener<Event>;
    public var onchange: EventListener<Event>;
    public var onclick: EventListener<MouseEvent>;
    public var oncontextmenu: EventListener<Event>;
    public var ondblclick: EventListener<MouseEvent>;
    public var ondrag: EventListener<MouseEvent>;
    public var ondragend: EventListener<MouseEvent>;
    public var ondragenter: EventListener<MouseEvent>;
    public var ondragleave: EventListener<MouseEvent>;
    public var ondragover: EventListener<MouseEvent>;
    public var ondragstart: EventListener<MouseEvent>;
    public var ondrop: EventListener<MouseEvent>;
    public var ondurationchange: EventListener<Event>;
    public var onemptied: EventListener<Event>;
    public var onended: EventListener<Event>;
    public var onerror: EventListener<Event>;
    public var onfocus: EventListener<Event>;
    public var onformchange: EventListener<Event>;
    public var onforminput: EventListener<Event>;
    public var oninput: EventListener<Event>;
    public var oninvalid: EventListener<Event>;
    public var onkeydown: EventListener<KeyboardEvent>;
    public var onkeypress: EventListener<KeyboardEvent>;
    public var onkeyup: EventListener<KeyboardEvent>;
    public var onload: EventListener<Event>;
    public var onloadeddata: EventListener<Event>;
    public var onloadedmetadata: EventListener<Event>;
    public var onloadstart: EventListener<Event>;
    public var onmousedown: EventListener<MouseEvent>;
    public var onmousemove: EventListener<MouseEvent>;
    public var onmouseout: EventListener<MouseEvent>;
    public var onmouseover: EventListener<MouseEvent>;
    public var onmouseup: EventListener<MouseEvent>;
    public var onmousewheel: EventListener<MouseEvent>;
    public var onpause: EventListener<Event>;
    public var onplay: EventListener<Event>;
    public var onplaying: EventListener<Event>;
    public var onprogress: EventListener<Event>;
    public var onratechange: EventListener<Event>;
    public var onreadystatechange: EventListener<Event>;
    public var onscroll: EventListener<MouseEvent>;
    public var onseeked: EventListener<Event>;
    public var onseeking: EventListener<Event>;
    public var onselect: EventListener<Event>;
    public var onshow: EventListener<Event>;
    public var onstalled: EventListener<Event>;
    public var onsubmit: EventListener<Event>;
    public var onsuspend: EventListener<Event>;
    public var ontimeupdate: EventListener<Event>;
    public var onvolumechange: EventListener<Event>;
    public var onwaiting: EventListener<Event>;
    
}

extern interface HTMLUnknownElement implements HTMLElement {
    
}

//Tested
extern interface HTMLElement implements Element {
    public var id:              DOMString;
    public var title:           DOMString;
    public var lang:            DOMString;
    public var dir:             DOMString;
    public var className:       DOMString;
    public var innerHTML:       DOMString;
    public var style:           CSSInlineStyleDeclaration;
    public var hidden:          Bool;
    
    public var accessKey            (default, null): DOMString;
    public var accessKeyLabel       (default, null): DOMString;
    public var draggable            (default, null): Bool;
    public var contentEditable      (default, null): DOMString;
    public var isContentEditable    (default, null): Bool;
    public var contextMenu          (default, null): HTMLMenuElement;
    public var spellcheck           (default, null): DOMString;
    
    //command API
    public var commandType      (default, null): DOMString;
    public var label            (default, null): DOMString;
    public var icon             (default, null): DOMString;
    public var disabled         (default, null): Bool;
    public var checked          (default, null): Bool;
    
    // dynamic markup insertion
    public var outerHTML: DOMString;
    
    public function insertAdjacentHTML(position: DOMString, text: DOMString): Void;
        
    
	public var offsetLeft       (default,null): Int;
    public var offsetTop        (default,null): Int;
    public var offsetWidth      (default,null): Int;
    public var offsetHeight     (default,null): Int;
    
    public function scrollIntoView(?top: Bool): Void;
    
    public function focus(): Void;
    
    public function click(): Void;
    
    public function blur():  Void;
    
    public var onabort: EventListener<Event>;
    public var onblur: EventListener<Event>;
    public var oncanplay: EventListener<Event>;
    public var oncanplaythrough: EventListener<Event>;
    public var onchange: EventListener<Event>;
    public var onclick: EventListener<Event>;
    public var oncontextmenu: EventListener<Event>;
    public var ondblclick: EventListener<MouseEvent>;
    public var ondrag: EventListener<MouseEvent>;
    public var ondragend: EventListener<MouseEvent>;
    public var ondragenter: EventListener<MouseEvent>;
    public var ondragleave: EventListener<MouseEvent>;
    public var ondragover: EventListener<MouseEvent>;
    public var ondragstart: EventListener<MouseEvent>;
    public var ondrop: EventListener<MouseEvent>;
    public var ondurationchange: EventListener<Event>;
    public var onemptied: EventListener<Event>;
    public var onended: EventListener<Event>;
    public var onerror: EventListener<Event>;
    public var onfocus: EventListener<Event>;
    public var onformchange: EventListener<Event>;
    public var onforminput: EventListener<Event>;
    public var oninput: EventListener<Event>;
    public var oninvalid: EventListener<Event>;
    public var onkeydown: EventListener<KeyboardEvent>;
    public var onkeypress: EventListener<KeyboardEvent>;
    public var onkeyup: EventListener<KeyboardEvent>;
    public var onload: EventListener<Event>;
    public var onloadeddata: EventListener<Event>;
    public var onloadedmetadata: EventListener<Event>;
    public var onloadstart: EventListener<Event>;
    public var onmousedown: EventListener<MouseEvent>;
    public var onmousemove: EventListener<MouseEvent>;
    public var onmouseout: EventListener<MouseEvent>;
    public var onmouseover: EventListener<MouseEvent>;
    public var onmouseup: EventListener<MouseEvent>;
    public var onmousewheel: EventListener<MouseEvent>;
    public var onpause: EventListener<Event>;
    public var onplay: EventListener<Event>;
    public var onplaying: EventListener<Event>;
    public var onprogress: EventListener<Event>;
    public var onratechange: EventListener<Event>;
    public var onreadystatechange: EventListener<Event>;
    public var onscroll: EventListener<MouseEvent>;
    public var onseeked: EventListener<Event>;
    public var onseeking: EventListener<Event>;
    public var onselect: EventListener<Event>;
    public var onshow: EventListener<Event>;
    public var onstalled: EventListener<Event>;
    public var onsubmit: EventListener<Event>;
    public var onsuspend: EventListener<Event>;
    public var ontimeupdate: EventListener<Event>;
    public var onvolumechange: EventListener<Event>;
    public var onwaiting: EventListener<Event>;
}
//Tested
extern interface HTMLHtmlElement implements HTMLElement {
    public var version:     DOMString;
}
//Tested
extern interface HTMLHeadElement implements HTMLElement {
    public var profile:     DOMString;
}
//Tested
extern interface HTMLLinkElement implements HTMLElement {
    public var disabled (default, null):        Bool;
    public var charset:         DOMString;
    public var href:            DOMString;
    public var hreflang:        DOMString;
    public var media:           DOMString;
    public var rel:             DOMString;
    public var rev:             DOMString;
    public var target:          DOMString;
    public var type:            DOMString;
}
//Tested
extern interface HTMLTitleElement implements HTMLElement {
    public var text:            DOMString;
}
//Tested
extern interface HTMLMetaElement implements HTMLElement {
    public var content:         DOMString;
    public var httpEquiv:       DOMString;
    public var lang:            DOMString;
    public var id:              DOMString;
    public var dir:             DOMString;
    public var name:            DOMString;
    public var scheme:          DOMString;
}
//Tested
extern interface HTMLBaseElement implements HTMLElement {
    public var href:            DOMString;
    public var target:          DOMString;
}
//Unable to Test
extern interface HTMLIsIndexElement implements HTMLElement {
    public var form             (default, null): HTMLFormElement;
    public var prompt:          DOMString;
}
//Tested
extern interface HTMLStyleElement implements HTMLElement {
    public var disabled:        Bool;
    public var media:           DOMString;
    public var type:            DOMString;
    public var scoped:          Bool;
}
//Tested
extern interface HTMLBodyElement implements HTMLElement {
    public var aLink:           DOMString;
    public var background:      DOMString;
    public var bgColor:         DOMString;
    public var link:            DOMString;
    public var text:            DOMString;
    public var vLink:           DOMString;
}
//Tested
extern interface HTMLFormElement implements HTMLElement {
    public var elements         (default, null): HTMLCollection;
    public var length           (default, null): Int;
    public var name:            DOMString;
    public var acceptCharset:   DOMString;
    public var action:          DOMString;
    public var enctype:         DOMString;
    public var method:          DOMString;
    public var target:          DOMString;
    
    public function submit(): Void;
    
    public function reset(): Void;
}
//Unable to Test
extern interface HTMLSelectElement implements HTMLElement {
    public var type             (default, null): DOMString;
    public var selectedIndex:   Int;
    public var value:           DOMString;
    public var length           (default, null): Int;
    public var form             (default, null): HTMLFormElement;
    public var options          (default, null): HTMLOptionsCollection;
    public var disabled (default, null):        Bool;
    public var multiple:        Bool;
    public var name:            DOMString;
    public var size:            Int;
    public var tabIndex:        Int;

    public function add(element: HTMLElement, before: HTMLElement): Void;

    public function remove(index: Int): Void;

    public function blur(): Void;

    public function focus(): Void;
}
//Tested
extern interface HTMLCanvasElement implements HTMLElement {
    public var width:                      Int;
    public var height:                     Int;
    
    public function toDataURL(type:DOMString, args: Dynamic): DOMString;
    
    public function getContext(contextId: DOMString): Dynamic;
}
//Tested
extern interface CanvasRenderingContext2D {

    public var canvas: HTMLCanvasElement;
    
    public function save():Void; // push state on state stack
    public function restore():Void; // pop state stack and restore state
    public function scale(x: Float, y: Float):Void;
    public function rotate(angle: Float):Void;
    public function translate(x: Float, y: Float):Void;
    public function transform(m11: Float, m12: Float, m21: Float, m22: Float, dx: Float, dy: Float):Void;
    public function setTransform(m11: Float, m12: Float, m21: Float, m22: Float, dx: Float, dy: Float):Void;
    public var globalAlpha:                 Float; // (default 1.0)
    public var globalCompositeOperation:    DOMString; // (default source-over)

    public var strokeStyle:                 Dynamic; // (default black)
    public var fillStyle:                   Dynamic; // (default black)
    public function createLinearGradient(x0: Float, y0: Float, x1: Float, y1: Float):CanvasGradient;
    public function createRadialGradient(x0: Float, y0: Float, r0: Float, x1: Float, y1: Float, r1: Float):CanvasGradient;
    public function createPattern(image: HTMLImageElement, repetition: DOMString):CanvasPattern;

    public var lineWidth:                   Float; // (default 1)
    public var lineCap:                     DOMString; // "butt", "round", "square" (default "butt")
    public var lineJoin:                    DOMString; // "round", "bevel", "miter" (default "miter")
    public var miterLimit:                  Float; // (default 10)


    public var shadowOffsetX:               Float; // (default 0)
    public var shadowOffsetY:               Float; // (default 0)
    public var shadowBlur:                  Float; // (default 0)
    public var shadowColor:                 DOMString; // (default transparent black)


    public function clearRect(x: Float, y: Float, w: Float, h: Float):Void;
    public function fillRect(x: Float, y: Float, w: Float, h: Float):Void;
    public function strokeRect(x: Float, y: Float, w: Float, h: Float):Void;


    public function beginPath():Void;
    public function closePath():Void;
    public function moveTo(x: Float, y: Float):Void;
    public function lineTo(x: Float, y: Float):Void;
    public function quadraticCurveTo(cpx: Float, cpy: Float, x: Float, y: Float):Void;
    public function bezierCurveTo(cp1x: Float, cp1y: Float, cp2x: Float, cp2y: Float, x: Float, y: Float):Void;
    public function arcTo(x1: Float, y1: Float, x2: Float, y2: Float, radius: Float):Void;
    public function rect(x: Float, y: Float, w: Float, h: Float):Void;
    public function arc(x: Float, y: Float, radius: Float, startAngle: Float, endAngle: Float, anticlockwise: Bool):Void;
    public function fill():Void;
    public function stroke():Void;
    public function clip():Void;
    public function isPointInPath(x: Float, y: Float):Bool;


    public function drawFocusRing(element: Element, xCaret: Float, yCaret: Float, canDrawCustom: Bool):Bool;


    public var font:                    DOMString; // (default 10px sans-serif)
    public var textAlign:               DOMString; // "start", "end", "left", "right", "center" (default: "start")
    public var textBaseline:            DOMString; // "top", "hanging", "middle", "alphabetic", "ideographic", "bottom" (default: "alphabetic")
    public function fillText(text: DOMString, x: Float, y: Float, maxWidth: Float):Void;
    public function strokeText(text: DOMString, x: Float, y: Float, maxWidth: Float):Void;
    public function measureText(text: DOMString):TextMetrics;

    //@:overload( function (image: Dynamic, dx: Float, dy: Float):Void {} )
	public function drawImage(image: Dynamic, sx: Float, sy: Float, ?sw: Float, ?sh: Float, ?dx: Float, ?dy: Float, ?dw: Float, ?dh: Float):Void;

    public function createImageData(sw: Float, sh: Float):ImageData;
    public function getImageData(sx: Float, sy: Float, sw: Float, sh: Float):ImageData;
    public function putImageData(imagedata: ImageData, dx: Float, dy: Float, ?dirtyX: Float, ?dirtyY: Float, ?dirtyWidth: Float, ?dirtyHeight: Float):Void;
}
//Tested
extern interface CanvasGradient {
    public function addColorStop(offset: Float, color: DOMString): Void;
}

extern interface CanvasPattern {

}
//Tested
extern interface TextMetrics {
    public var width            (default, null): Int;
}
//Tested
extern interface ImageData {
    public var width              (default, null): Int;
    public var height             (default, null): Int;
    public var data               (default, null): CanvasPixelArray;
}

extern interface CanvasPixelArray implements ArrayAccess<Int> {
  public var length(default, null): Int;
}

extern interface Octet {}

//Unable to Test
extern interface HTMLOptGroupElement implements HTMLElement {
    public var disabled (default, null):        Bool;
    public var label (default, null):           DOMString;
}
//Tested
extern interface HTMLOptionElement implements HTMLElement {
    public var form             (default, null): HTMLFormElement;
    public var defaultSelected: Bool;
    public var text             (default, null): DOMString;
    public var index            (default, null): Int;
    public var disabled (default, null):        Bool;
    public var label (default, null):           DOMString;
    public var selected:        Bool;
    public var value:           DOMString;
}
//Tested
extern interface HTMLInputElement implements HTMLElement {
    public var defaultValue:    DOMString;
    public var defaultChecked:  Bool;
    public var form             (default, null): HTMLFormElement;
    public var accept:          DOMString;
    public var accessKey (default, null):       DOMString;
    public var align:           DOMString;
    public var alt:             DOMString;
    public var checked (default, null):         Bool;
    public var disabled (default, null):        Bool;
    public var maxLength:       Int;
    public var name:            DOMString;
    public var readOnly:        Bool;
    public var size:            Int;
    public var src:             DOMString;
    public var tabIndex:        Int;
    public var type:            DOMString;
    public var useMap:          DOMString;
    public var value:           DOMString;
    
    public function blur(): Void;
    
    public function focus(): Void;
    
    public function select(): Void;
    
    public function click(): Void;
}
//Tested
extern interface HTMLTextAreaElement implements HTMLElement {
    public var defaultValue:    DOMString;
    public var form             (default, null): HTMLFormElement;
    public var accessKey (default, null):       DOMString;
    public var cols:            Int;
    public var disabled (default, null):        Bool;
    public var name:            DOMString;
    public var readOnly:        Bool;
    public var rows:            Int;
    public var tabIndex:        Int;
    public var type             (default, null): DOMString;
    public var value:           DOMString;
    
    public function blur(): Void;
    
    public function focus(): Void;
    
    public function select(): Void;
}
//Tested
extern interface HTMLButtonElement implements HTMLElement {
    public var form             (default, null): HTMLFormElement;
    public var accessKey (default, null):       DOMString;
    public var disabled (default, null):        Bool;
    public var name:            DOMString;
    public var tabIndex:        Int;
    public var type             (default, null): DOMString;
    public var value:           DOMString;
}
//Tested
extern interface HTMLLabelElement implements HTMLElement {
    public var form             (default, null): HTMLFormElement;
    public var accessKey (default, null):       DOMString;
    public var htmlFor:         DOMString;
}
//Tested
extern interface HTMLFieldSetElement implements HTMLElement {
    public var form             (default, null): HTMLFormElement;
}
//Tested
extern interface HTMLLegendElement implements HTMLElement {
    public var form             (default, null): HTMLFormElement;
    public var accessKey (default, null):       DOMString;
    public var align:           DOMString;
}
//Tested
extern interface HTMLUListElement implements HTMLElement {
    public var compact:         Bool;
    public var type:            DOMString;
}
//Tested
extern interface HTMLOListElement implements HTMLElement {
    public var compact:         Bool;
    public var start:           Int;
    public var type:            DOMString;
}
//Tested
extern interface HTMLDListElement implements HTMLElement {
    public var compact:         Bool;
}
//Tested
extern interface HTMLDirectoryElement implements HTMLElement {
    public var compact:         Bool;
}
//Tested
extern interface HTMLMenuElement implements HTMLElement {
    public var compact:         Bool;
}
//Tested
extern interface HTMLLIElement implements HTMLElement {
    public var type:            DOMString;
    public var value:           Int;
}
//Tested
extern interface HTMLDivElement implements HTMLElement {
    public var align:           DOMString;
}
//Tested
extern interface HTMLParagraphElement implements HTMLElement {
    public var align:           DOMString;
}
//Tested
extern interface HTMLHeadingElement implements HTMLElement {
    public var align:           DOMString;
}
//Tested
extern interface HTMLQuoteElement implements HTMLElement {
    public var cite:            DOMString;
}
//Tested
extern interface HTMLPreElement implements HTMLElement {
    public var width:           Int;
}
//Tested
extern interface HTMLBRElement implements HTMLElement {
    public var clear:           DOMString;
}
//Tested -- only supported by Internet Explorer
extern interface HTMLBaseFontElement implements HTMLElement {
    public var color:           DOMString;
    public var face:            DOMString;
    public var size:            Int;
}
//Tested
extern interface HTMLFontElement implements HTMLElement {
    public var color:           DOMString;
    public var face:            DOMString;
    public var size:            DOMString;
}
//Tested
extern interface HTMLHRElement implements HTMLElement {
    public var align:           DOMString;
    public var noShade:         Bool;
    public var size:            DOMString;
    public var width:           DOMString;
}
//Tested
extern interface HTMLModElement implements HTMLElement {
    public var cite:            DOMString;
    public var dateTime:        DOMString;
}
//Tested
extern interface HTMLAnchorElement implements HTMLElement {
    public var accessKey (default, null):       DOMString;
    public var charset:         DOMString;
    public var coords:          DOMString;
    public var href:            DOMString;
    public var hreflang:        DOMString;
    public var name:            DOMString;
    public var rel:             DOMString;
    public var rev:             DOMString;
    public var shape:           DOMString;
    public var tabIndex:        Int;
    public var target:          DOMString;
    public var type:            DOMString;
    
    public function blur(): Void;
    
    public function focus(): Void;
}
//Tested
extern interface HTMLImageElement implements HTMLElement {
    public var name:            DOMString;
    public var align:           DOMString;
    public var alt:             DOMString;
    public var border:          DOMString;
    public var height:          Int;
    public var hspace:          Int;
    public var isMap:           Bool;
    public var longDesc:        DOMString;
    public var src:             DOMString;
    public var useMap:          DOMString;
    public var vspace:          Int;
    public var width:           Int;
    public var complete:	Bool; // not w3c
}
//Tested
extern interface HTMLObjectElement implements HTMLElement {
    public var form             (default, null): HTMLFormElement;
    public var code:            DOMString;
    public var align:           DOMString;
    public var archive:         DOMString;
    public var border:          DOMString;
    public var codeBase:        DOMString;
    public var codeType:        DOMString;
    public var data:            DOMString;
    public var declare:         Bool;
    public var height:          DOMString;
    public var hspace:          Int;
    public var name:            DOMString;
    public var standby:         DOMString;
    public var tabIndex:        Int;
    public var type:            DOMString;
    public var useMap:          DOMString;
    public var vspace:          Int;
    public var width:           DOMString;
    public var contentDocument  (default, null): Document;
}
//Tested
extern interface HTMLParamElement implements HTMLElement {
    public var name:            DOMString;
    public var type:            DOMString;
    public var value:           DOMString;
    public var valueType:       DOMString;
}
//Tested
extern interface HTMLAppletElement implements HTMLElement {
    public var align:           DOMString;
    public var alt:             DOMString;
    public var archive:         DOMString;
    public var code:            DOMString;
    public var codeBase:        DOMString;
    public var height:          DOMString;
    public var hspace:          Int;
    public var name:            DOMString;
    public var object:          DOMString;
    public var vspace:          Int;
    public var width:           DOMString;
}
//Tested
extern interface HTMLMapElement implements HTMLElement {
    public var areas            (default, null): HTMLCollection;
    public var name:            DOMString;
}
//Tested
extern interface HTMLAreaElement implements HTMLElement {
    public var accessKey (default, null):       DOMString;
    public var alt:             DOMString;
    public var coords:          DOMString;
    public var href:            DOMString;
    public var noHref:          Bool;
    public var shape:           DOMString;
    public var tabIndex:        Int;
    public var target:          DOMString;
}
//Tested
extern interface HTMLScriptElement implements HTMLElement {
    public var text:            DOMString;
    public var htmlFor:         DOMString;
    public var event:           DOMString;
    public var charset:         DOMString;
    public var defer:           Bool;
    public var src:             DOMString;
    public var type:            DOMString;
}
//Tested
extern interface HTMLTableElement implements HTMLElement {
    public var caption:         HTMLTableCaptionElement;
    public var tHead:           HTMLTableSectionElement;
    public var tFoot:           HTMLTableSectionElement;
    public var rows             (default, null): HTMLCollection;
    public var tBodies          (default, null): HTMLCollection;
    public var align:           DOMString;
    public var bgColor:         DOMString;
    public var border:          DOMString;
    public var cellPadding:     DOMString;
    public var cellSpacing:     DOMString;
    public var frame:           DOMString;
    public var rules:           DOMString;
    public var summary:         DOMString;
    public var width:           DOMString;
    
    public function createTHead(): HTMLElement;
    
    public function deleteTHead(): Void;
    
    public function creatTFoot(): HTMLElement;
    
    public function deleteTFoot(): Void;
    
    public function createCaption(): HTMLElement;
    
    public function deleteCaption(): Void;
    
    public function insertRow(index: Int): HTMLElement;
    
    public function deleteRow(index: Int): Void;
}
//Tested
extern interface HTMLTableCaptionElement implements HTMLElement {
    public var align:           DOMString;
}
//Tested
extern interface HTMLTableColElement implements HTMLElement {
    public var align:           DOMString;
    public var ch:              DOMString;
    public var chOff:           DOMString;
    public var span:            Int;
    public var vAlign:          DOMString;
    public var width:           DOMString;
}
//Tested
extern interface HTMLTableSectionElement implements HTMLElement {
    public var align:           DOMString;
    public var ch:              DOMString;
    public var chOff:           DOMString;
    public var vAlign:          DOMString;
    public var rows             (default, null): HTMLCollection;
    
    public function insertRow(index: Int): HTMLElement;
    
    public function deleteRow(index: Int): Void;
}
//Tested
extern interface HTMLTableRowElement implements HTMLElement {
    public var rowIndex         (default, null): Int;
    public var sectionRowIndex  (default, null): Int;
    public var cells            (default, null): HTMLCollection;
    public var align:           DOMString;
    public var bgColor:         DOMString;
    public var ch:              DOMString;
    public var chOff:           DOMString;
    public var vAlign:          DOMString;
    
    public function insertCell(index: Int): HTMLElement;
    
    public function deleteCell(index: Int): Void;
}
//Tested
extern interface HTMLTableCellElement implements HTMLElement {
    public var cellIndex        (default, null): Int;
    public var abbr:            DOMString;
    public var align:           DOMString;
    public var axis:            DOMString;
    public var bgColor:         DOMString;
    public var ch:              DOMString;
    public var chOff:           DOMString;
    public var colSpan:         Int;
    public var headers:         DOMString;
    public var height:          DOMString;
    public var noWrap:          Bool;
    public var rowSpan:         Int;
    public var scope:           DOMString;
    public var vAlign:          DOMString;
    public var width:           DOMString;
}
//Unable to Test
extern interface HTMLFrameSetElement implements HTMLElement {
    public var cols:            DOMString;
    public var rows:            DOMString;
}
//Unable to Test
extern interface HTMLFrameElement implements HTMLElement {
    public var frameBorder:     DOMString;
    public var longDesc:        DOMString;
    public var marginHeight:    DOMString;
    public var marginWidth:     DOMString;
    public var name:            DOMString;
    public var noResize:        Bool;
    public var scrolling:       DOMString;
    public var src:             DOMString;
    public var contentDocument  (default, null): HTMLDocument;
    public var contentWindow    (default, null): Window;
}
//Tested
extern interface HTMLIFrameElement implements HTMLElement {
    public var align:           DOMString;
    public var frameBorder:     DOMString;
    public var height:          DOMString;
    public var longDesc:        DOMString;
    public var marginHeight:    DOMString;
    public var marginWidth:     DOMString;
    public var name:            DOMString;
    public var scrolling:       DOMString;
    public var src:             DOMString;
    public var width:           DOMString;
    public var contentDocument  (default, null): HTMLDocument;
    public var contentWindow    (default, null): Window;
}
//Unable to Test
extern interface ClientRect {
    public var top              (default, null): Float;
    public var right            (default, null): Float;
    public var bottom           (default, null): Float;
    public var left             (default, null): Float;
    public var width            (default, null): Float;
    public var height           (default, null): Float;
}

/*
* <----------------- Views level 2 Port ------------------>
*
*/
//Unable to Test
extern interface AbstractView {
    public var document     (default, null): Document;
    
    public var media        (default, null): Media;
}

//Unable To Test
extern interface Media {
    public var type         (default, null): DOMString;
    
    public function matchMedium(mediaquery: DOMString): Bool;
}

/*
* <----------------- Events level 2 Port ------------------>
*  *** Unable to Automate testing for all Events ***
*/

extern interface MessageEvent implements Event {
  public var data           (default, null): Dynamic;
  public var origin         (default, null): DOMString;
  public var lastEventId    (default, null): DOMString;
  public var source         (default, null): WindowProxy;
  public var ports          (default, null): MessagePortArray;
  
  public function initMessageEvent(typeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool, dataArg: Dynamic, originArg: DOMString, lastEventIdArg: DOMString, sourceArg: WindowProxy, portsArg: MessagePortArray): Void;
  
  public function initMessageEventNS(namespaceURI: DOMString, typeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool, dataArg: Dynamic, originArg: DOMString, lastEventIdArg: DOMString, sourceArg: WindowProxy, portsArg: MessagePortArray): Void;
}

extern interface StorageEvent implements Event {
    public var key          (default, null): DOMString;
    public var oldValue     (default, null): Dynamic;
    public var newValue     (default, null): Dynamic;
    public var url          (default, null): DOMString;
    public var storageArea  (default, null): Storage;
    
    public function initStorageEvent(typeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool, keyArg: DOMString, oldValueArg: Dynamic, newValueArg: Dynamic, urlArg: DOMString, storageAreaArg: Storage): Void;
}

extern interface EventException {
    public var code:    Int;
}

extern interface EventSource implements EventTarget  {
  public var URL        (default, null): DOMString;
  public var readyState (default, null): Int;
  
  public var onopen:    EventListener<Event>;
  public var onmessage: EventListener<Event>;
  public var onerror:   EventListener<Event>;
  
  public function close(): Void;
}

extern interface WheelEvent implements MouseEvent {
    public var deltaX       (default, null): Int;
    public var deltaY       (default, null): Int;
    public var deltaZ       (default, null): Int;
    public var deltaMode    (default, null): Int;
            
    public function initWheelEvent(
        typeArg             : DOMString, 
        canBubbleArg        : Bool, 
        cancelableArg       : Bool, 
        viewArg             : AbstractView, 
        detailArg           : Int, 
        screenXArg          : Int, 
        screenYArg          : Int, 
        clientXArg          : Int, 
        clientYArg          : Int, 
        buttonArg           : Int, 
        relatedTargetArg    : EventTarget, 
        modifiersListArg    : DOMString, 
        deltaXArg           : Int, 
        deltaYArg           : Int, 
        deltaZArg           : Int, 
        deltaMode           : Int
    ): Void;
        
    public function initWheelEventNS(
        namespaceURIArg     : DOMString, 
        typeArg             : DOMString, 
        canBubbleArg        : Bool, 
        cancelableArg       : Bool, 
        viewArg             : AbstractView, 
        detailArg           : Int, 
        screenXArg          : Int, 
        screenYArg          : Int, 
        clientXArg          : Int, 
        clientYArg          : Int, 
        buttonArg           : Int, 
        relatedTargetArg    : EventTarget, 
        modifiersListArg    : DOMString, 
        deltaXArg           : Int, 
        deltaYArg           : Int, 
        deltaZArg           : Int, 
        deltaMode           : Int
    ): Void;
}

extern interface TextEvent implements UIEvent {
    public var data         (default, null): DOMString;
    public var inputMode    (default, null): Int;
    
    public function initTextEvent(typeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool, viewArg: AbstractView, dataArg: DOMString, inputMode: Int): Void;
    
    public function initTextEventNS(namespaceURIArg: DOMString, typeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool, viewArg: AbstractView, dataArg: DOMString, inputMode: Int): Void;
}

extern interface KeyboardEvent implements UIEvent {
    public var keyIdentifier        (default, null): DOMString;                
    public var keyLocation          (default, null): Int;
    public var ctrlKey              (default, null): Bool;
    public var shiftKey             (default, null): Bool;
    public var altKey               (default, null): Bool;
    public var metaKey              (default, null): Bool;
    public var repeat               (default, null): Bool;
    public var keyCode              (default, null): Int; // Note: W3C non-conformant
    public var charCode             (default, null): Int; // Note: W3C non-conformant
    public var which                (default, null): Int; // Note: W3C non-conformant
    
    public function getModifierState(keyIdentifierArg: DOMString): Bool;
    
    
    public function initKeyboardEvent(
        typeArg:                DOMString, 
        canBubbleArg:           Bool, 
        cancelableArg:          Bool, 
        viewArg:                AbstractView, 
        keyIdentifierArg:       DOMString, 
        keyLocationArg:         Int, 
        modifiersListArg:       DOMString,
        repeat:                 Bool
    ): Void;
    
    public function initKeyboardEventNS(
        namespaceURIArg:        DOMString, 
        typeArg:                DOMString, 
        canBubbleArg:           Bool, 
        cancelableArg:          Bool, 
        viewArg:                AbstractView, 
        keyIdentifierArg:       DOMString, 
        keyLocationArg:         Int, 
        modifiersListArg:       DOMString,
        repeat:                 Bool
    ): Void;
}

extern interface CompositionEvent implements UIEvent {
    public var data             (default, null): DOMString;
    
    public function initCompositionEvent(
        typeArg:                DOMString, 
        canBubbleArg:           Bool, 
        cancelableArg:          Bool, 
        viewArg:                AbstractView, 
        dataArg:                DOMString
    ): Void;
    
    public function initCompositionEventNS(
        namespaceURIArg:        DOMString, 
        typeArg:                DOMString, 
        canBubbleArg:           Bool, 
        cancelableArg:          Bool, 
        viewArg:                AbstractView, 
        dataArg:                DOMString
    ): Void;
}

extern interface MouseWheelEvent implements MouseEvent {
    public var wheelDelta       (default, null): Int;
    
    public function initMouseWheelEvent(
        typeArg         : DOMString, 
        canBubbleArg    : Bool, 
        cancelableArg   : Bool, 
        viewArg         : AbstractView,
        detailArg       : Int, 
        screenXArg      : Int, 
        screenYArg      : Int, 
        clientXArg      : Int, 
        clientYArg      : Int, 
        buttonArg       : Int, 
        relatedTargetArg: EventTarget, 
        modifiersListArg: DOMString, 
        wheelDeltaArg   : Int 
    ): Void;
                                     
    public function initMouseWheelEventNS(
        namespaceURIArg : DOMString, 
        typeArg         : DOMString, 
        canBubbleArg    : Bool, 
        cancelableArg   : Bool, 
        viewArg         : AbstractView,
        detailArg       : Int, 
        screenXArg      : Int, 
        screenYArg      : Int, 
        clientXArg      : Int, 
        clientYArg      : Int, 
        buttonArg       : Int, 
        relatedTargetArg: EventTarget, 
        modifiersListArg: DOMString, 
        wheelDeltaArg   : Int 
    ): Void;
}



typedef EventListener<T: Event> = T -> Void;


typedef MouseEventListener = MouseEvent -> Void;

typedef DragEventListener = MouseEvent -> Void;

typedef UIEventListener = UIEvent -> Void;

interface MessagePortArray {
  
}

interface MessagePort {
  public function postMessage(message: Dynamic, ?ports: MessagePortArray): Void;
  
  public function start(): Void;
  
  public function close(): Void;

  public var onmessage: Dynamic -> Dynamic;
}


extern interface Event {
    public var type             (default, null): DOMString;
    public var target           (default, null): EventTarget;
    public var currentTarget    (default, null): EventTarget;
    public var eventPhase       (default, null): Int;
    public var bubbles          (default, null): Bool;
    public var cancelable       (default, null): Bool;
    public var timeStamp        (default, null): DOMTimeStamp;
    public var defaultPrevented (default, null): Bool;
    public var trusted          (default, null): Bool;
    
    public function stopPropagation(): Void;
    
    public function preventDefault(): Void;
    
    public function initEvent(eventTypeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool): Void;
    
    public function stopImmediatePropagation(): Void;
}

extern interface CustomEvent implements Event {
    public var detail           (default, null): DOMObject;
    
    public function initCustomEvent(typeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool, detailArg: DOMObject): Void;
    
    public function initCustomEventNS(namespaceURIArg: DOMString, typeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool, detailArg: DOMObject): Void;
}

extern interface FocusEvent implements UIEvent {
    public var relatedTarget        (default, null): EventTarget;
    
    public function initFocusEvent(
        typeArg:        DOMString, 
        canBubbleArg:   Bool, 
        cancelableArg:  Bool, 
        viewArg:        AbstractView, 
        detailArg:      Int,
        relatedTargetArg: EventTarget
    ): Void;
}

extern interface DocumentEvent {
    public function createEvent(eventType: DOMString): Event;
    
    public function canDispatch(namespaceURI: DOMString, type: DOMString): Bool;
}

extern interface UIEvent implements Event {
    public var detail       (default, null): Int;
    public var view         (default, null): AbstractView;
    
    public function initUIEvent(
        typeArg:        DOMString, 
        canBubbleArg:   Bool, 
        cancelableArg:  Bool, 
        viewArg:        AbstractView, 
        detailArg:      Int
    ): Void;
    
    public function initUIEventNS(
        namespaceURI:   DOMString,
        typeArg:        DOMString, 
        canBubbleArg:   Bool, 
        cancelableArg:  Bool, 
        viewArg:        AbstractView, 
        detailArg:      Int
    ): Void;
}

extern interface MouseEvent implements UIEvent {
    public var screenX          (default, null): Int;
    public var screenY          (default, null): Int;
    public var pageX            (default, null): Int;
    public var pageY            (default, null): Int;
    public var x                (default, null): Int;
    public var y                (default, null): Int;
    public var offsetX          (default, null): Int;
    public var offsetY          (default, null): Int;
    public var clientX          (default, null): Int;
    public var clientY          (default, null): Int;
    
    public var ctrlKey          (default, null): Bool;
    public var shiftKey         (default, null): Bool;
    public var altKey           (default, null): Bool;
    public var metaKey          (default, null): Bool;
    public var button           (default, null): Int;
    public var which            (default, null): Int; // Note: W3C non-conformant
    public var relatedTarget    (default, null): EventTarget;
    
    public function getModifierState(keyIdentifierArg: DOMString): Bool;
    
    public function initMouseEventNS(
        namespaceURIArg: DOMString,
        canBubbleArg: Bool,
        cancelableArg: Bool,
        viewArg: AbstractView,
        detailArg: Int,
        screenXArg: Int,
        screenYArg: Int,
        clientXArg: Int,
        clientYArg: Int,
        buttonArg: Int,
        relatedTargetArg: EventTarget,
        modifiersListArg: DOMString
    ): Void;
    
    public function initMouseEvent(
        typeArg:          DOMString, 
        canBubbleArg:     Bool, 
        cancelableArg:    Bool, 
        viewArg:          AbstractView, 
        detailArg:        Int, 
        screenXArg:       Int, 
        screenYArg:       Int, 
        clientXArg:       Int, 
        clientYArg:       Int, 
        ctrlKeyArg:       Bool, 
        altKeyArg:        Bool, 
        shiftKeyArg:      Bool, 
        metaKeyArg:       Bool, 
        buttonArg:        Int, 
        relatedTargetArg: EventTarget
    ): Void;
}

extern interface Touch {
	public var identifier		(default, null): Int;
	public var target		(default, null): EventTarget;
	public var screenX		(default, null): Int;
	public var screenY		(default, null): Int;
	public var clientX		(default, null): Int;
	public var clientY		(default, null): Int;
	public var pageX		(default, null): Int;
	public var pageY		(default, null): Int;
}

extern interface TouchList implements ArrayAccess<Touch> {
	public var length 		(default, null): Int;
	public var item 		(default, null): Touch;
	public var identifiedTouch:		Touch;
}

extern interface TouchEvent implements UIEvent {
	public var touches		(default, null):TouchList;
	public var targetTouches	(default, null):TouchList;
	public var changedTouches	(default, null):TouchList;
	public var altKey		(default, null):Bool;
	public var metaKey		(default, null):Bool;
	public var ctrlKey		(default, null):Bool;
	public var shiftKey		(default, null):Bool;
}

typedef Acceleration = {
	x:Float,
	y:Float,
	z:Float 
}
typedef RotationRate = {
	alpha:Float,
	beta:Float,
	gamma:Float
}
extern interface AccelerationEvent {
	public var acceleration 					(default, null):Acceleration;
	public var accelerationIncludingGravity 	(default, null):Acceleration;
	public var rotationRate 					(default, null):RotationRate;
}

extern interface PopStateEvent implements Event {
    public var state        (default, null): Dynamic;
    
    public function initPopStateEvent(
        typeArg:            DOMString, 
        canBubbleArg:       Bool, 
        cancelableArg:      Bool, 
        stateArg:           Dynamic
    ): Void;
}

extern interface BeforeUnloadEvent implements Event {
    public var returnValue: DOMString;
}

extern interface PageTransitionEvent implements Event {
    public var persisted    (default, null): Dynamic;
    
    public function initPageTransitionEvent(
        typeArg:            DOMString, 
        canBubbleArg:       Bool, 
        cancelableArg:      Bool, 
        persistedArg:       Dynamic
    ): Void;
}

extern interface HashChangeEvent implements Event {
    public var oldURL       (default, null): DOMString;
    public var newURL       (default, null): DOMString;
    
    public function initHashChangeEvent(
        typeArg:        DOMString, 
        canBubbleArg:   Bool, 
        cancelableArg:  Bool, 
        oldURLArg:      DOMString,
        newURLArg:      DOMString
    ): Void;
}

extern interface DragEvent implements MouseEvent {
  public var dataTransfer       (default, null): DataTransfer;
  
    public function initDragEvent(
        typeArg: DOMString, 
        canBubbleArg: Bool, 
        cancelableArg: Bool, 
        dummyArg: Dynamic, 
        detailArg: Int, 
        screenXArg: Int, 
        screenYArg: Int, 
        clientXArg: Int, 
        clientYArg: Int, 
        ctrlKeyArg: Bool, 
        altKeyArg: Bool, 
        shiftKeyArg: Bool, 
        metaKeyArg: Bool, 
        buttonArg: Int, 
        relatedTargetArg: EventTarget, 
        dataTransferArg: DataTransfer
    ): Void;
}

extern interface DataTransfer {
    public var dropEffect:      DOMString;
    public var effectAllowed:   DOMString;
    public var types            (default, null): DOMStringList;
    public var files            (default, null): DomCollection<File>;
    
    public function clearData(?format: DOMString): Void;
    
    public function setData(format: DOMString, data: DOMString): Void;
    
    public function getData(format: DOMString): DOMString;
    
    public function setDragImage(image: Element, x: Int, y: Int): Void;
    
    public function addElement(element: Element): Void;
}

extern interface Blob {
      public var size           (default, null): Int;
      
      public function slice(start: Int, length: Int): Blob;
}

extern interface File implements Blob {

      public var name      (default, null): DOMString;
      public var type      (default, null): DOMString;
      public var urn       (default, null): DOMString;
}

extern interface MutationEvent implements Event {
    public var relatedNode      (default, null): Node;
    public var prevValue        (default, null): DOMString;
    public var newValue         (default, null): DOMString;
    public var attrName         (default, null): DOMString;
    public var attrChange       (default, null): Int;
    
    public function initMutationEvent(
        typeArg:                DOMString, 
        canBubbleArg:           Bool, 
        cancelableArg:          Bool, 
        relatedNodeArg:         Node, 
        prevValueArg:           DOMString, 
        newValueArg:            DOMString, 
        attrNameArg:            DOMString, 
        attrChangeArg:          Int
    ): Void;
    
    public function initMutationEventNS(
        namespaceURIArg:        DOMString,
        typeArg:                DOMString, 
        canBubbleArg:           Bool, 
        cancelableArg:          Bool, 
        relatedNodeArg:         Node, 
        prevValueArg:           DOMString, 
        newValueArg:            DOMString, 
        attrNameArg:            DOMString, 
        attrChangeArg:          Int
    ): Void;
}

extern interface MutationNameEvent implements MutationEvent {
    public var prevNamespaceURI (default, null): DOMString;
    public var prevNodeName     (default, null): DOMString;
    
    public function initMutationNameEvent(
        typeArg:                DOMString, 
        canBubbleArg:           Bool, 
        cancelableArg:          Bool, 
        relatedNodeArg:         Node, 
        prevNamespaceURIArg:    DOMString, 
        prevNodeNameArg:        DOMString
    ): Void;
    
    public function initMutationNameEventNS(
        namespaceURIArg:        DOMString, 
        typeArg:                DOMString, 
        canBubbleArg:           Bool, 
        cancelableArg:          Bool, 
        relatedNodeArg:         Node, 
        prevNamespaceURIArg:    DOMString, 
        prevNodeNameArg:        DOMString
    ): Void;
}


/*
* <----------------- Traversal level 2 Port ------------------>
*
*/
extern interface NodeIterator {
    public var root                     (default, null): Node;
    public var whatToShow               (default, null): Int;
    public var filter                   (default, null): NodeFilter;
    public var expandEntityReferences   (default, null): Bool;

    public function nextNode(): Node;

    public function previousNode(): Node;

    public function detach(): Void;
}

extern interface NodeFilter {
    public function acceptNode(n: Node): Int;
}

extern interface TreeWalker {
    public var root                     (default, null): Node;
    public var whatToShow               (default, null): Int;
    public var filter                   (default, null): NodeFilter;
    public var expandEntityReferences   (default, null): Bool;
    public var currentNode              (default, null): Node;

    public function parentNode():       Node;
    
    public function firstChild():       Node;
    
    public function lastChild():        Node;
    
    public function previousSibling():  Node;
    
    public function nextSibling():      Node;
    
    public function previousNode():     Node;
    
    public function nextNode():         Node;
}

extern interface DocumentTraversal {
    public function createNodeIterator(root: Node, whatToShow: Int, filter: NodeFilter, entityReferenceExpansion: Bool): NodeIterator;
    
    public function createTreeWalker(root: Node, whatToShow: Int, filter: NodeFilter, entityReferenceExpansion: Bool): TreeWalker;
}

/*
* <----------------- Range level 2 Port ------------------>
*
*/

extern interface TimeRanges {
  public var length         (default, null): Int;
  
  public function Float(index: Int): Float;
  
  public function end(index: Int): Float;
}

extern interface RangeException {
    public var code:        Int;
    
    public function getClientRects(): DomCollection<ClientRect>;
    
    public function getBoundingClientRect(): ClientRect;
}

extern interface Range {
    public var startContainer           (default, null): Node;
    public var startOffset              (default, null): Int;
    public var endContainer             (default, null): Node;
    public var endOffset                (default, null): Int;
    public var collapsed                (default, null): Bool;
    public var commonAncestorContainer  (default, null): Node;
    
    public function setStart(refNode: Node, offset: Int): Void;
    
    public function setEnd(refNode: Node, offset: Int): Void;
    
    public function setStartBefore(refNode: Node): Void;
    
    public function setStartAfter(refNode: Node): Void;
    
    public function setEndBefore(refNode: Node): Void;
    
    public function setEndAfter(refNode: Node): Void;
    
    public function collapse(toStart: Bool): Void;
    
    public function selectNode(refNode: Node): Void;
    
    public function selectNodeContents(refNode: Node): Void;
    
    public function compareBoundaryPoints(how: Int, sourceRange: Range): Int;
    
    public function deleteContents(): Void;
    
    public function extractContents(): DocumentFragment;
    
    public function cloneContents(): DocumentFragment;
    
    public function insertNode(newNode: Node): Void;
    
    public function surroundContents(newParent: Node): Void;
    
    public function cloneRange(): Range;
    
    public function toString(): DOMString;
    
    public function detach(): Void;
}

extern interface DocumentRange {
    public function createRange(): Range;
}

/*
* <----------------- StyleSheets level 2 idl Port ------------------>
*
*/

extern interface StyleSheet {
    public var type             (default, null): DOMString;
    public var disabled         (default, null): Bool;
    public var ownerNode        (default, null): Node;
    public var parentStyleSheet (default, null): StyleSheet;
    public var href             (default, null): DOMString;
    public var title            (default, null): DOMString;
    public var media            (default, null): MediaList;
}

extern interface MediaList {
    public var mediaText:   DOMString;
    public var length       (default,null): Int;
    
    public function item(index: Int): DOMString;
    
    public function deleteMedium(oldMedium: DOMString): Void;
    
    public function appendMedium(newMedium: DOMString): Void;
}

extern interface LinkStyle {
    public var sheet            (default, null): StyleSheet;
}

/*
* <----------------- Css level 2 idl Port ------------------>
*
*/

//Tested
extern interface CSSRule {
    public var type             (default, null): Int;
    public var cssText:         DOMString;
    public var parentStyleSheet (default, null): CSSStyleSheet;
    public var parentRule       (default, null): CSSRule;
}
//Unable to Test
extern interface CSSStyleRule implements CSSRule {
    public var selectorText:    DOMString;
    public var style            (default, null): CSSStyleDeclaration;
}
//Unable to Test
extern interface CSSMediaRule implements CSSRule {
    public var stylesheets      (default, null): MediaList;
    public var cssRules         (default, null): DomCollection<CSSRule>;
    
    public function insertRule(rule: DOMString, index: Int): Int;
    
    public function deleteRule(index: Int): Void;
}
//Unable to Test
extern interface CSSFontFaceRule implements CSSRule {
    public var style            (default, null): CSSStyleDeclaration;
}
//Unable to Test
extern interface CSSPageRule implements CSSRule {
    public var selectorText:    DOMString;
    public var style            (default, null): CSSStyleDeclaration;
}
//Unable to Test
extern interface CSSImportRule implements CSSRule {
    public var href             (default, null): DOMString;
    public var media            (default, null): MediaList;
    public var styleSheet       (default, null): CSSStyleSheet;
}
//Unable to Test
extern interface CSSCharsetRule implements CSSRule {
    public var encoding:  DOMString;
}
//Unable to Test
extern interface CSSUnknownRule implements CSSRule {
}
//UnableToTest
extern interface CSS2Properties {
    public var azimuth:              DOMString;
    public var background:           DOMString;
    public var backgroundAttachment: DOMString;
    public var backgroundColor:      DOMString;
    public var backgroundImage:      DOMString;
    public var backgroundPosition:   DOMString;
    public var backgroundRepeat:     DOMString;
    public var border:               DOMString;
    public var borderCollapse:       DOMString;
    public var borderColor:          DOMString;
    public var borderSpacing:        DOMString;
    public var borderStyle:          DOMString;
    public var borderTop:            DOMString;
    public var borderRight:          DOMString;
    public var borderBottom:         DOMString;
    public var borderLeft:           DOMString;
    public var borderTopColor:       DOMString;
    public var borderRightColor:     DOMString;
    public var borderBottomColor:    DOMString;
    public var borderLeftColor:      DOMString;
    public var borderTopStyle:       DOMString;
    public var borderRightStyle:     DOMString;
    public var borderBottomStyle:    DOMString;
    public var borderLeftStyle:      DOMString;
    public var borderTopWidth:       DOMString;
    public var borderRightWidth:     DOMString;
    public var borderBottomWidth:    DOMString;
    public var borderLeftWidth:      DOMString;
    public var borderWidth:          DOMString;
    public var bottom:               DOMString;
    public var captionSide:          DOMString;
    public var clear:                DOMString;
    public var clip:                 DOMString;
    public var color:                DOMString;
    public var content:              DOMString;
    public var counterIncrement:     DOMString;
    public var counterReset:         DOMString;
    public var cue:                  DOMString;
    public var cueAfter:             DOMString;
    public var cueBefore:            DOMString;
    public var cursor:               DOMString;
    public var direction:            DOMString;
    public var display:              DOMString;
    public var elevation:            DOMString;
    public var emptyCells:           DOMString;
    public var cssFloat:             DOMString;
    public var font:                 DOMString;
    public var fontFamily:           DOMString;
    public var fontSize:             DOMString;
    public var fontSizeAdjust:       DOMString;
    public var fontStretch:          DOMString;
    public var fontStyle:            DOMString;
    public var fontVariant:          DOMString;
    public var fontWeight:           DOMString;
    public var height:               DOMString;
    public var left:                 DOMString;
    public var letterSpacing:        DOMString;
    public var lineHeight:           DOMString;
    public var listStyle:            DOMString;
    public var listStyleImage:       DOMString;
    public var listStylePosition:    DOMString;
    public var listStyleType:        DOMString;
    public var margin:               DOMString;
    public var marginTop:            DOMString;
    public var marginRight:          DOMString;
    public var marginBottom:         DOMString;
    public var marginLeft:           DOMString;
    public var markerOffset:         DOMString;
    public var marks:                DOMString;
    public var maxHeight:            DOMString;
    public var maxWidth:             DOMString;
    public var minHeight:            DOMString;
    public var minWidth:             DOMString;
    public var orphans:              DOMString;
    public var outline:              DOMString;
    public var outlineColor:         DOMString;
    public var outlineStyle:         DOMString;
    public var outlineWidth:         DOMString;
    public var overflow:             DOMString;
    public var padding:              DOMString;
    public var paddingTop:           DOMString;
    public var paddingRight:         DOMString;
    public var paddingBottom:        DOMString;
    public var paddingLeft:          DOMString;
    public var page:                 DOMString;
    public var pageBreakAfter:       DOMString;
    public var pageBreakBefore:      DOMString;
    public var pageBreakInside:      DOMString;
    public var pause:                DOMString;
    public var pauseAfter:           DOMString;
    public var pauseBefore:          DOMString;
    public var pitch:                DOMString;
    public var pitchRange:           DOMString;
    public var playDuring:           DOMString;
    public var position:             DOMString;
    public var quotes:               DOMString;
    public var richness:             DOMString;
    public var right:                DOMString;
    public var size:                 DOMString;
    public var speak:                DOMString;
    public var speakHeader:          DOMString;
    public var speakNumeral:         DOMString;
    public var speakPunctuation:     DOMString;
    public var speechRate:           DOMString;
    public var stress:               DOMString;
    public var tableLayout:          DOMString;
    public var textAlign:            DOMString;
    public var textDecoration:       DOMString;
    public var textIndent:           DOMString;
    public var textShadow:           DOMString;
    public var textTransform:        DOMString;
    public var top:                  DOMString;
    public var unicodeBidi:          DOMString;
    public var verticalAlign:        DOMString;
    public var visibility:           DOMString;
    public var voiceFamily:          DOMString;
    public var volume:               DOMString;
    public var whiteSpace:           DOMString;
    public var widows:               DOMString;
    public var width:                DOMString;
    public var wordSpacing:          DOMString;
    public var zIndex:               DOMString;
}
//Tested
extern interface CSSStyleDeclaration {
    public var length       (default,null): Int;
    public var parentRule   (default, null): CSSRule;
    
    public var cssText:     DOMString;
    
    public function removeProperty(propertyName: DOMString): Void;
    
    public function getPropertyValue(propertyName: DOMString): DOMString;
    
    public function getPropertyCSSValue(propertyName: DOMString): CSSValue;
    
    public function getPropertyPriority(propertyName: DOMString): DOMString;
    
    public function getPropertyShorthand(propertyName: DOMString): DOMString; //Not supported by Firefox

    public function setProperty(propertyName: DOMString, value: DOMString, priority: DOMString): Void;
    
    public function isPropertyImplicit(propertyName: DOMString): Bool;  //Not supported by Firefox
    
    public function item(index: Int): DOMString;
}
//Unable to Test
extern interface CSSInlineStyleDeclaration implements CSS2Properties {
    public var length       (default, null): Int;
    public var parentRule   (default, null): CSSRule;
    
    public var cssText:     DOMString;
    
    public function getPropertyValue(propertyName: DOMString): DOMString;
    
    public function getPropertyCSSValue(propertyName: DOMString): CSSValue;
    
    public function getPropertyPriority(propertyName: DOMString): DOMString;

    public function setProperty(propertyName: DOMString, value: DOMString, priority: DOMString): Void;
    
    public function item(index: Int): DOMString;
}

//Unable to Test
extern interface CSSValue {
    public var cssText:             DOMString;
    public var cssValueType         (default, null): Int;
}

//Unable to Test
extern interface CSSPrimitiveValue implements CSSValue {
    public var primitiveType    (default, null): Int;
    
    public function setFloatValue(unitType: Int, FloatValue: Float): Void;
    
    public function getFloatValue(unitType: Int): Float;
    
    public function setStringValue(stringType: Int, stringValue: DOMString): Void;
    
    public function getStringValue(): DOMString;
    
    public function getCounterValue(): Counter;
    
    public function getRectValue(): Rect;
    
    public function getRGBValue(): RGBColor;
}
//Unable to Test
extern interface RGBColor {
    public var red          (default, null): CSSPrimitiveValue;
    public var green        (default, null): CSSPrimitiveValue;
    public var blue         (default, null): CSSPrimitiveValue;
}
//Unable to Test
extern interface Rect {
    public var top          (default, null): CSSPrimitiveValue;
    public var right        (default, null): CSSPrimitiveValue;
    public var bottom       (default, null): CSSPrimitiveValue;
    public var left         (default, null): CSSPrimitiveValue;
}
//Unable to Test
extern interface Counter {
    public var identifier   (default, null): DOMString;
    public var listStyle    (default, null): DOMString;
    public var separator    (default, null): DOMString;
}
//Tested
extern interface CSSStyleSheet implements StyleSheet {
    public var ownerRule    (default, null): CSSRule;
    public var cssRules     (default, null): DomCollection<CSSRule>;
    
    public function insertRule(rule: DOMString, index: Int): Int;
    
    public function deleteRule(index: Int): Void;
}
//Unable to Test
extern interface ViewCSS implements AbstractView {
    public function getComputedStyle(elt: Element, pseudoElt: DOMString): CSSStyleDeclaration;
}
//Unable to Test
extern interface DOMImplementationCSS implements DOMImplementation {
    public function createCSSStyleSheet(title: DOMString, media: DOMString): CSSStyleSheet;
}
//Tested
extern interface Navigator {
    public var appCodeName      (default, null): DOMString;
    public var cookieEnabled    (default, null): DOMString;
    public var geolocation      (default, null): DOMString;
    public var language         (default, null): DOMString;
    public var appName          (default, null): DOMString;
    public var appVersion       (default, null): DOMString;
    public var platform         (default, null): DOMString;
    public var userAgent        (default, null): DOMString;
    public var plugins          (default, null): DomCollection<Plugin>;
    public var onLine           (default, null): Bool;
    public var productSub       : DOMString;
    public var product          : DOMString;
    public var mimeTypes        : MimeTypeArray;
    public var vendorSub        : DOMString;
    public var vendor           : DOMString;

    public function javaEnabled(): Bool;
    
    public function taintEnabled(): Bool;
    
    public function getStorageUpdates(): Void;
    
    public function registerProtocolHandler(scheme: DOMString, url: DOMString, title: DOMString): Void;
    
    public function registerContentHandler(mimeType: DOMString, url: DOMString, title: DOMString): Void;
    
    public function yieldForStorageUpdates(): Void;
}
//Tested
extern interface Plugin {
    public var length           (default, null): Int;
    public var name             (default, null):DOMString;
    public var filename         (default, null):DOMString;
    public var description      (default, null):DOMString;
    
    public function item(index:Int): Plugin;
    
    public function namedItem(name:DOMString): Plugin;
}

extern interface MimeTypeArray {
    public var length           (default, null): Int;
}
//Tested
extern interface History {
    public var length           (default, null): Int;
    
    public function back(): Void;
    
    public function forward(): Void;
    
    public function go(?delta: Int): Void;
    
    public function pushState(data: Dynamic, title: DOMString, ?url: DOMString): Void;
    
    public function replaceState(data: Dynamic, title: DOMString, ?url: DOMString): Void;
}
//Tested
extern interface Location {
    public var hash             (default, default): String;
    public var host             (default, default): String;
    public var hostname         (default, default): String;
    public var href             (default, default): String;
    public var pathname         (default, default): String;
    public var port             (default, default): String;
    public var protocol         (default, default): String;
    public var search           (default, default): String;
    
    public function assign(url: String): Void;
    
    public function reload(): Void;
    
    public function replace(url: String): Void;
    
    public function resolveURL(url: DOMString): DOMString;
}

//Tested
extern interface Screen {
    public var availHeight  (default, null): String;	
    public var availWidth   (default, null): String;
    public var availTop     (default, null): String;
    public var availLeft    (default, null): String;		
    public var colorDepth   (default, null): String;	
    public var height       (default, null): String;	
    public var pixelDepth   (default, null): String;	
    public var width        (default, null): String;
    public var left         (default, null): String;
    public var top          (default, null): String;		
}

extern interface ScreenView implements AbstractView {
    public var innerWidth       (default, null): Int;
    public var innerHeight      (default, null): Int;
    public var pageXOffset      (default, null): Int;
    public var pageYOffset      (default, null): Int;
    public var screenX          (default, null): Int;
    public var screenY          (default, null): Int;
    public var outerWidth       (default, null): Int;
    public var outerHeight      (default, null): Int;
    public var screen           (default, null): Screen;

    public function scroll(x: Int, y: Int): Void;
    
    public function scrollTo(x: Int, y: Int): Void;
    
    public function scrollBy(x: Int, y: Int): Void;
}

extern interface Crypto {
    
}

//Tested
extern interface Window implements ArrayAccess<WindowProxy>, implements EventTarget {
    public var closed           (default, null): Bool;
    public var defaultStatus:   DOMString;
    public var frames           (default, null): DomCollection<Frame>;
    public var innerHeight:     Int;
    public var innerWidth:      Int;
    public var length           (default, null): Int;
    public var navigator        (default, null): Navigator;
    public var opener           (default, null): Window;
    public var outerHeight:     Int;
    public var outerWidth:      Int;
    public var pageXOffset      (default, null): Int;
    public var pageYOffset      (default, null): Int;
    public var parent           (default, null): Window;
    public var screen           (default, null): Screen;
    public var screenLeft       (default, null): Int;
    public var screenTop        (default, null): Int;
    public var screenX          (default, null): Int;
    public var screenY          (default, null): Int;
    public var status:          DOMString;
    public var scrollY:         Int;
    public var top              (default, null): Window;
    public var window           (default, null): WindowProxy;
    public var self             (default, null): WindowProxy;
    public var document         (default, null): HTMLDocument;
    public var name:            DOMString;
    public var location         (default, null): Location;
    public var history          (default, null): History;
    public var undoManager      (default, null): UndoManager;
    public var locationbar      (default, null): BarProp;
    public var menubar          (default, null): BarProp;
    public var personalbar      (default, null): BarProp;
    public var scrollbars       (default, null): BarProp;
    public var statusbar        (default, null): BarProp;
    public var toolbar          (default, null): BarProp;
    public var frameElement     (default, null): Element;
    public var applicationCache (default, null): ApplicationCache;
    public var localStorage     (default, null): Storage;
    public var dialogArguments  (default, null): Dynamic;
    public var returnValue      : DOMString;
    public var sessionStorage   (default, null): Storage;
    public var crypto           (default, null): Crypto;
    public var orientation 		(default, null): Int;
    
    public var onabort: EventListener<Event>;
    public var onafterprint: EventListener<Event>;
    public var onbeforeprint: EventListener<Event>;
    public var onbeforeunload: EventListener<Event>;
    public var onblur: EventListener<Event>;
    public var oncanplay: EventListener<Event>;
    public var oncanplaythrough: EventListener<Event>;
    public var onchange: EventListener<Event>;
    public var onclick: EventListener<MouseEvent>;
    public var oncontextmenu: EventListener<Event>;
    public var ondblclick: EventListener<MouseEvent>; 
    public var ondrag: EventListener<MouseEvent>; 
    public var ondragend: EventListener<MouseEvent>; 
    public var ondragenter: EventListener<MouseEvent>; 
    public var ondragleave: EventListener<MouseEvent>; 
    public var ondragover: EventListener<MouseEvent>; 
    public var ondragstart: EventListener<MouseEvent>; 
    public var ondrop: EventListener<MouseEvent>; 
    public var ondurationchange: EventListener<Event>;
    public var onemptied: EventListener<Event>;
    public var onended: EventListener<Event>;
    public var onerror: EventListener<Event>;
    public var onfocus: EventListener<Event>;
    public var onformchange: EventListener<Event>;
    public var onforminput: EventListener<Event>;
    public var onhashchange: EventListener<Event>;
    public var oninput: EventListener<Event>;
    public var oninvalid: EventListener<Event>;
    public var onkeydown: EventListener<KeyboardEvent>; 
    public var onkeypress: EventListener<KeyboardEvent>; 
    public var onkeyup: EventListener<KeyboardEvent>; 
    public var onload: EventListener<Event>;
    public var onloadeddata: EventListener<Event>;
    public var onloadedmetadata: EventListener<Event>;
    public var onloadstart: EventListener<Event>;
    public var onmessage: EventListener<Event>;
    public var onmousedown: EventListener<MouseEvent>; 
    public var onmousemove: EventListener<MouseEvent>; 
    public var onmouseout: EventListener<MouseEvent>; 
    public var onmouseover: EventListener<MouseEvent>; 
    public var onmouseup: EventListener<MouseEvent>; 
    public var onmousewheel: EventListener<MouseEvent>; 
    public var onoffline: EventListener<Event>;
    public var ononline: EventListener<Event>;
    public var onpause: EventListener<Event>;
    public var onplay: EventListener<Event>;
    public var onplaying: EventListener<Event>;
    public var onpagehide: EventListener<Event>;
    public var onpageshow: EventListener<Event>;
    public var onpopstate: EventListener<Event>;
    public var onprogress: EventListener<Event>;
    public var onratechange: EventListener<Event>;
    public var onreadystatechange: EventListener<Event>;
    public var onredo: EventListener<Event>;
    public var onresize: EventListener<Event>;
    public var onscroll: EventListener<MouseEvent>;
    public var onseeked: EventListener<Event>;
    public var onseeking: EventListener<Event>;
    public var onselect: EventListener<Event>;
    public var onshow: EventListener<Event>;
    public var onstalled: EventListener<Event>;
    public var onstorage: EventListener<Event>;
    public var onsubmit: EventListener<Event>;
    public var onsuspend: EventListener<Event>;
    public var ontimeupdate: EventListener<Event>;
    public var onundo: EventListener<Event>;
    public var onunload: EventListener<Event>;
    public var onvolumechange: EventListener<Event>;
    public var onwaiting: EventListener<Event>;
    
    public function moveBy(x: Int, y: Int): Void;
    
    public function moveTo(x: Int, y: Int): Void;
    
    public function find(string: DOMString, caseSensitive: Bool, backwards: Bool, wrapAround: Bool, wholeWord: Bool, searchInFrames: Bool, showDialog: Bool): Bool;
    
    public function resizeTo(x: Int, y: Int): Void;
    
    public function resizeBy(x: Int, y: Int): Void;
    
    public function atob(encodedString: DOMString): DOMString;
    
    public function btoa(unencodedString: DOMString): DOMString;
    
    public var getComputedStyle (default, null): Element -> DOMString -> CSSStyleDeclaration;
    
    public var postMessage (default, null): DOMString -> DOMString -> Void;
    
    public function getSelection(): Selection;
    
    public function stop(): Void;
    
    public function close(): Void;
    
    public function focus(): Void;
    
    public function blur(): Void;
    
    public function open(?url: DOMString, ?target: DOMString, ?features: DOMString, ?replace: DOMString): WindowProxy;
    
    public function alert(message: DOMString): Void;
    
    public function confirm(message: DOMString): Bool;
    
    public function prompt(message: DOMString, ?def: DOMString): DOMString;
    
    public function print(): Void;
    
    public function showModalDialog(url: DOMString, ?argument: Dynamic): Dynamic;
    
    public function scroll(x: Int, y: Int): Void;
  
    public function scrollTo(x: Int, y: Int): Void;
    
    public function scrollBy(x: Int, y: Int): Void;
    
    public function setTimeout(handler: Event -> Void, ?timeout: Dynamic, args: Dynamic): Int;
    
    public function clearTimeout(handle: Int): Void;
    
    public function setInterval(handler: Event -> Void, ?timeout: Dynamic, args: Dynamic): Int;
    
    public function clearInterval(handle: Int): Void;
}

extern interface WindowProxy implements Window {
    
}

extern interface Frame implements Window {
    
}
//Tested
extern interface BarProp {
    public var visible:     Bool;
}

//Tested, but many fields and methods unavailable
extern interface ApplicationCache {
    public var status           (default, null): Int;
    public var length           (default, null): Int;
    public var onchecking:      EventListener<Event>;
    public var onerror:         EventListener<Event>;
    public var onnoupdate:      EventListener<Event>;
    public var ondownloading:   EventListener<Event>;
    public var onprogress:      EventListener<Event>;
    public var onupdateready:   EventListener<Event>;
    public var oncached:        EventListener<Event>;
    
    public function swapCache(): Void;
    
    public function item(index: Int): DOMString;

    public function add(uri: DOMString): Void;

    public function remove(uri: DOMString): Void;

    public function update(): Void;
    
    public function dispatchEvent(evt: Event): Bool;
    
    public function addEventListener(type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;

    public function removeEventListener(type: DOMString, listener: EventListener<Dynamic>, useCapture: Bool): Void;
}
//Not widely supported yet (HTML5 Spec)
extern interface UndoManager {
    public var length      (default, null): Int;
    public var position    (default, null): Int;
    
    public function add(data: DOMObject, title: DOMString): Int;
    
    public function remove(index: Int): Void;
    
    public function clearUndo(): Void;
    
    public function clearRedo(): Void;
    
    public function item(index: Int): DOMObject;
}
//Not widely supported yet (HTML5 Spec)
extern interface UndoManagerEvent implements Event {
  public var date           (default, null): Dynamic;
  
  public function initUndoManagerEvent(typeArg: DOMString, canBubbleArg: Bool, cancelableArg: Bool, dataArg: Dynamic): Void;
}

extern interface XMLHttpRequestEventTarget implements EventTarget {
  // for future use
}

//Tested
extern interface XMLHttpRequest implements XMLHttpRequestEventTarget {
    public var readyState           (default, null): Int;
    public var status           (default, null): Int;
    public var statusText       (default, null): DOMString;
    public var responseText     (default, null): DOMString;
    public var responseXML      (default, null): Document;
    public var response      (default, null): Dynamic;
    
    public var onreadystatechange: Void -> Void;
    
    public function overrideMimeType(mimeType: DOMString): Void;
    
    public function open(method: DOMString, url: DOMString, ?async: Bool, ?user: DOMString, ?password: DOMString): Void;
    
    public function setRequestHeader(header: DOMString, value: DOMString): Void;
    
    public function send(?data: String): Void;
    
    public function abort(): Void;
    
    public function getResponseHeader(header: DOMString): DOMString;
    
    public function getAllResponseHeaders(): DOMString;
}

