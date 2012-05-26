package nme.display;
#if code_completion


/**
 * The BitmapData class lets you work with the data (pixels) of a Bitmap object. 
 * You can use the methods of the BitmapData class
 * to create arbitrarily sized transparent or opaque bitmap images and manipulate them in various 
 * ways at runtime. 
 * 
 * The methods of the BitmapData class support 
 * effects that are not available through the filters available to non-bitmap display objects.
 * 
 * A BitmapData object contains an array of pixel data. This data can represent either 
 * a fully opaque bitmap or a transparent bitmap that contains alpha channel data. 
 * Either type of BitmapData object is stored as a buffer of 32-bit integers. 
 * Each 32-bit integer determines the properties of a single pixel in the bitmap.
 * 
 * Each 32-bit integer is a combination of four 8-bit channel values (from 0 to 255) that 
 * describe the alpha transparency and the red, green, and blue (ARGB) values of the pixel.
 * (For ARGB values, the most significant byte represents the alpha channel value, followed by red, 
 * green, and blue.)
 * 
 * The four channels (alpha, red, green, and blue) are represented as numbers
 * when you use them with the <code>BitmapData.copyChannel()</code> method, and these numbers
 * are represented by the following constants in the BitmapDataChannel class:
 * 
 * <ul>
 * <li>
 * <code>BitmapDataChannel.ALPHA</code>
 * </li>
 * <li>
 * <code>BitmapDataChannel.RED</code>
 * </li>
 * <li>
 * <code>BitmapDataChannel.GREEN</code>
 * </li>
 * <li>
 * <code>BitmapDataChannel.BLUE</code>
 * </li>
 * </ul>
 * 
 * You can attach BitmapData objects to a Bitmap object by using the 
 * <code>bitmapData</code> property of the Bitmap object.
 * 
 * You can use a BitmapData object to fill a Graphics object by using the 
 * <code>Graphics.beginBitmapFill()</code> method.
 */
extern class BitmapData implements IBitmapDrawable {
	
	/**
	 * The height of the bitmap image in pixels.
	 */
	var height (default, null):Int;
	
	/**
	 * The rectangle that defines the size and location of the bitmap image. The 
	 * top and left of the rectangle are 0; the width and height are equal to the 
	 * width and height in pixels of the BitmapData object. 
	 */
	var rect (default, null):nme.geom.Rectangle;
	
	/**
	 * Defines whether the bitmap image supports per-pixel transparency. You can set 
	 * this value only when you construct a BitmapData object by passing in 
	 * <code>true</code> for the transparent parameter of the <code>constructor</code>.
	 * Then, after you create a BitmapData object, you can check whether it supports 
	 * per-pixel transparency by determining if the value of the transparent property 
	 * is <code>true</code>. 
	 */
	var transparent (default, null):Bool;
	
	/**
	 * The width of the bitmap image in pixels.
	 */
	var width (default, null):Int;
	
	/**
	 * Creates a BitmapData object with a specified width and height. If you specify a value for 
	 * the <code>fillColor</code> parameter, every pixel in the bitmap is set to that color. 
	 * 
	 * By default, the bitmap is created as transparent, unless you pass the value <code>false</code>
	 * for the transparent parameter. After you create an opaque bitmap, you cannot change it 
	 * to a transparent bitmap. Every pixel in an opaque bitmap uses only 24 bits of color channel 
	 * information. If you define the bitmap as transparent, every pixel uses 32 bits of color 
	 * channel information, including an alpha transparency channel.
	 * 
	 * @param	width		The width of the bitmap image in pixels. 
	 * @param	height		The height of the bitmap image in pixels. 
	 * @param	transparent		Specifies whether the bitmap image supports per-pixel transparency. The default value is <code>true</code> (transparent). To create a fully transparent bitmap, set the value of the <code>transparent</code> parameter to <code>true</code> and the value of the <code>fillColor</code> parameter to 0x00000000 (or to 0). Setting the <code>transparent</code> property to <code>false</code> can result in minor improvements in rendering performance.
	 * @param	fillColor		A 32-bit ARGB color value that you use to fill the bitmap image area. The default value is 0xFFFFFFFF (solid white).
	 */
	function new (width:Int, height:Int, transparent:Bool = true, fillColor:Int = 0xFFFFFFFF):Void;
	
	/**
	 * Takes a source image and a filter object and generates the filtered image. 
	 * 
	 * This method relies on the behavior of built-in filter objects, which determine the 
	 * destination rectangle that is affected by an input source rectangle.
	 * 
	 * After a filter is applied, the resulting image can be larger than the input image. 
	 * For example, if you use a BlurFilter class to blur a source rectangle of (50,50,100,100) 
	 * and a destination point of (10,10), the area that changes in the destination image is 
	 * larger than (10,10,60,60) because of the blurring. This happens internally during the 
	 * applyFilter() call.
	 * 
	 * If the <code>sourceRect</code> parameter of the sourceBitmapData parameter is an 
	 * interior region, such as (50,50,100,100) in a 200 x 200 image, the filter uses the source 
	 * pixels outside the <code>sourceRect</code> parameter to generate the destination rectangle.
	 * 
	 * If the BitmapData object and the object specified as the <code>sourceBitmapData</code> 
	 * parameter are the same object, the application uses a temporary copy of the object to 
	 * perform the filter. For best performance, avoid this situation.
	 * 
	 * @param	sourceBitmapData		The input bitmap image to use. The source image can be a different BitmapData object or it can refer to the current BitmapData instance.
	 * @param	sourceRect		A rectangle that defines the area of the source image to use as input.
	 * @param	destPoint		The point within the destination image (the current BitmapData instance) that corresponds to the upper-left corner of the source rectangle. 
	 * @param	filter		The filter object that you use to perform the filtering operation. 
	 */
	function applyFilter (sourceBitmapData:BitmapData, sourceRect:nme.geom.Rectangle, destPoint:nme.geom.Point, filter:nme.filters.BitmapFilter):Void;
	
	/**
	 * Returns a new BitmapData object that is a clone of the original instance with an exact copy of the contained bitmap. 
	 * @return		A new BitmapData object that is identical to the original.
	 */
	function clone ():BitmapData;
	
	/**
	 * Adjusts the color values in a specified area of a bitmap image by using a <code>ColorTransform</code>
	 * object. If the rectangle matches the boundaries of the bitmap image, this method transforms the color 
	 * values of the entire image. 
	 * @param	rect		A Rectangle object that defines the area of the image in which the ColorTransform object is applied.
	 * @param	colorTransform		A ColorTransform object that describes the color transformation values to apply.
	 */
	function colorTransform (rect:nme.geom.Rectangle, colorTransform:nme.geom.ColorTransform):Void;
	
	function compare(otherBitmapData : BitmapData) : Dynamic;
	function copyChannel(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, sourceChannel : Int, destChannel : Int) : Void;
	function copyPixels(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, ?alphaBitmapData : BitmapData, ?alphaPoint : nme.geom.Point, mergeAlpha : Bool = false) : Void;
	function dispose() : Void;
	function draw(source : IBitmapDrawable, ?matrix : nme.geom.Matrix, ?colorTransform : nme.geom.ColorTransform, ?blendMode : BlendMode, ?clipRect : nme.geom.Rectangle, smoothing : Bool = false) : Void;
	function fillRect(rect : nme.geom.Rectangle, color : Int) : Void;
	function floodFill(x : Int, y : Int, color : Int) : Void;
	function generateFilterRect(sourceRect : nme.geom.Rectangle, filter : nme.filters.BitmapFilter) : nme.geom.Rectangle;
	function getColorBoundsRect(mask : Int, color : Int, findColor : Bool = true) : nme.geom.Rectangle;
	function getPixel(x : Int, y : Int) : Int;
	function getPixel32(x : Int, y : Int) : Int;
	function getPixels(rect : nme.geom.Rectangle) : nme.utils.ByteArray;
	@:require(flash10) function getVector(rect : nme.geom.Rectangle) : nme.Vector<Int>;
	@:require(flash10) function histogram(?hRect : nme.geom.Rectangle) : nme.Vector<nme.Vector<Float>>;
	function hitTest(firstPoint : nme.geom.Point, firstAlphaThreshold : Int, secondObject : Dynamic, ?secondBitmapDataPoint : nme.geom.Point, secondAlphaThreshold : Int = 1) : Bool;
	function lock() : Void;
	function merge(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, redMultiplier : Int, greenMultiplier : Int, blueMultiplier : Int, alphaMultiplier : Int) : Void;
	function noise(randomSeed : Int, low : Int = 0, high : Int = 255, channelOptions : Int = 7, grayScale : Bool = false) : Void;
	function paletteMap(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, ?redArray : Array<Int>, ?greenArray : Array<Int>, ?blueArray : Array<Int>, ?alphaArray : Array<Int>) : Void;
	function perlinNoise(baseX : Float, baseY : Float, numOctaves : Int, randomSeed : Int, stitch : Bool, fractalNoise : Bool, channelOptions : Int = 7, grayScale : Bool = false, ?offsets : Array<nme.geom.Point>) : Void;
	function pixelDissolve(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, randomSeed : Int = 0, numPixels : Int = 0, fillColor : Int = 0) : Int;
	function scroll(x : Int, y : Int) : Void;
	function setPixel(x : Int, y : Int, color : Int) : Void;
	function setPixel32(x : Int, y : Int, color : Int) : Void;
	function setPixels(rect : nme.geom.Rectangle, inputByteArray : nme.utils.ByteArray) : Void;
	@:require(flash10) function setVector(rect : nme.geom.Rectangle, inputVector : nme.Vector<Int>) : Void;
	function threshold(sourceBitmapData : BitmapData, sourceRect : nme.geom.Rectangle, destPoint : nme.geom.Point, operation : String, threshold : Int, color : Int = 0, mask : Int = 0xFFFFFFFF, copySource : Bool = false) : Int;
	function unlock(?changeRect : nme.geom.Rectangle) : Void;
}


#elseif (cpp || neko)
typedef BitmapData = neash.display.BitmapData;
#elseif js
typedef BitmapData = jeash.display.BitmapData;
#else
typedef BitmapData = flash.display.BitmapData;
#end