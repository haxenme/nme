package nme.display;
#if code_completion


/**
 * The Bitmap class represents display objects that represent bitmap images.
 * These can be images that you load with the nme.display.Loader class, or
 * they can be images that you create with the <code>Bitmap()</code>
 * constructor.
 *
 * <p>The <code>Bitmap()</code> constructor allows you to create a Bitmap
 * object that contains a reference to a BitmapData object. After you create a
 * Bitmap object, use the <code>addChild()</code> or <code>addChildAt()</code>
 * method of the parent DisplayObjectContainer instance to place the bitmap on
 * the display list.</p>
 *
 * <p>A Bitmap object can share its BitmapData reference among several Bitmap
 * objects, independent of translation or rotation properties. Because you can
 * create multiple Bitmap objects that reference the same BitmapData object,
 * multiple display objects can use the same complex BitmapData object without
 * incurring the memory overhead of a BitmapData object for each display
 * object instance.</p>
 *
 * <p>A BitmapData object can be drawn to the screen by a Bitmap object in one
 * of two ways: by using the vector renderer as a fill-bitmap shape, or by
 * using a faster pixel-copying routine. The pixel-copying routine is
 * substantially faster than the vector renderer, but the Bitmap object must
 * meet certain conditions to use it:</p>
 *
 * <ul>
 *   <li> No stretching, rotation, or skewing can be applied to the Bitmap
 * object.</li>
 *   <li> No color transform can be applied to the Bitmap object. </li>
 *   <li> No blend mode can be applied to the Bitmap object. </li>
 *   <li> No clipping can be done through mask layers or
 * <code>setMask()</code> methods. </li>
 *   <li> The image itself cannot be a mask. </li>
 *   <li> The destination coordinates must be on a whole pixel boundary. </li>
 * </ul>
 *
 * <p>If you load a Bitmap object from a domain other than that of the Loader
 * object used to load the image, and there is no URL policy file that permits
 * access to the domain of the Loader object, then a script in that domain
 * cannot access the Bitmap object or its properties and methods. For more
 * information, see the Flash Player Developer Center Topic: <a
 * href="http://www.adobe.com/go/devnet_security_en"
 * scope="external">Security</a>.</p>
 *
 * <p><b>Note:</b> The Bitmap class is not a subclass of the InteractiveObject
 * class, so it cannot dispatch mouse events. However, you can use the
 * <code>addEventListener()</code> method of the display object container that
 * contains the Bitmap object.</p>
 */
extern class Bitmap extends DisplayObject {
	

	/**
	 * The BitmapData object being referenced.
	 */
	var bitmapData:BitmapData;
	

	/**
	 * Controls whether or not the Bitmap object is snapped to the nearest pixel.
	 * The PixelSnapping class includes possible values:
	 * <ul>
	 *   <li><code>PixelSnapping.NEVER</code>—No pixel snapping occurs.</li>
	 *   <li><code>PixelSnapping.ALWAYS</code>—The image is always snapped to
	 * the nearest pixel, independent of transformation.</li>
	 *   <li><code>PixelSnapping.AUTO</code>—The image is snapped to the
	 * nearest pixel if it is drawn with no rotation or skew and it is drawn at a
	 * scale factor of 99.9% to 100.1%. If these conditions are satisfied, the
	 * bitmap image is drawn at 100% scale, snapped to the nearest pixel.
	 * Internally, this value allows the image to be drawn as fast as possible
	 * using the vector renderer.</li>
	 * </ul>
	 */
	var pixelSnapping:PixelSnapping;
	

	/**
	 * Controls whether or not the bitmap is smoothed when scaled. If
	 * <code>true</code>, the bitmap is smoothed when scaled. If
	 * <code>false</code>, the bitmap is not smoothed when scaled.
	 */
	var smoothing:Bool;
	
	function new (?bitmapData:BitmapData, ?pixelSnapping:PixelSnapping, smoothing:Bool = false):Void;
	
}


#elseif (cpp || neko)
typedef Bitmap = neash.display.Bitmap;
#elseif js
typedef Bitmap = jeash.display.Bitmap;
#else
typedef Bitmap = flash.display.Bitmap;
#end
