package nme.display;
#if code_completion


/**
 * The Bitmap class represents display objects that represent bitmap images. These can be images
 * that you load with the flash.display.Loader class, or they can be images that you create with
 * the <code>Bitmap()</code> constructor. 
 * 
 * The <code>Bitmap()</code> constructor allows you to create a Bitmap object that
 * contains a reference to a BitmapData object. After you create a Bitmap object, use the 
 * <code>addChild()</code> or <code>addChildAt()</code> method of the parent DisplayObjectContainer
 * instance to place the bitmap on the display list.</p>
 * 
 * A Bitmap object can share its BitmapData reference among several Bitmap objects,
 * independent of translation or rotation properties. Because you can create multiple Bitmap
 * objects that reference the same BitmapData object, multiple display objects can use the
 * same complex BitmapData object without incurring the memory overhead of a BitmapData
 * object for each display object instance.
 * 
 * <b>Note:</b> The Bitmap class is not a subclass of the InteractiveObject class, so
 * it cannot dispatch mouse events. However, you can use the <code>addEventListener()</code> method
 * of the display object container that contains the Bitmap object.
 */
extern class Bitmap extends DisplayObject {
	
	/**
	 * The BitmapData object being referenced.
	 */
	var bitmapData:BitmapData;
	
	/**
	 * Controls whether or not the Bitmap object is snapped to the nearest pixel. The PixelSnapping
	 * class includes possible values:
	 * 
	 * <ul><li><code>PixelSnapping.NEVER</code>&mdash;No pixel snapping occurs.</li>
	 * <li><code>PixelSnapping.ALWAYS</code>&mdash;The image is always snapped to the nearest
	 * pixel, independent of transformation.</li>
	 * <li><code>PixelSnapping.AUTO</code>&mdash;The image is snapped
	 * to the nearest pixel if it is drawn with no rotation
	 * or skew and it is drawn at a scale factor of 99.9% to 100.1%. If these conditions are satisfied,
	 * the bitmap image is drawn at 100% scale, snapped to the nearest pixel. Internally, this value allows the image
	 * to be drawn as fast as possible.
	 */
	var pixelSnapping:PixelSnapping;
	
	/**
	 * Controls whether or not the bitmap is smoothed when scaled. If <code>true</code>, the bitmap 
	 * is smoothed when scaled. If <code>false</code>, the bitmap is not smoothed when scaled. 
	 */
	var smoothing:Bool;
	
	/**
	 * Initializes a Bitmap object to refer to the specified BitmapData object.
	 * @param	?bitmapData		The BitmapData object being referenced.
	 * @param	?pixelSnapping		Whether or not the Bitmap object is snapped to the nearest pixel. 
	 * @param	smoothing		Whether or not the bitmap is smoothed when scaled.
	 */
	function new (?bitmapData:BitmapData, ?pixelSnapping:PixelSnapping, smoothing:Bool = false):Void;
	
}


#elseif (cpp || neko)
typedef Bitmap = neash.display.Bitmap;
#elseif js
typedef Bitmap = jeash.display.Bitmap;
#else
typedef Bitmap = flash.display.Bitmap;
#end