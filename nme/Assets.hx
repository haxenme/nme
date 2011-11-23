package nme;
#if (!nme_install_tool)


import nme.display.BitmapData;
import nme.media.Sound;
import nme.text.Font;
import nme.utils.ByteArray;


/**
 * Provides a cross-platform interface for accessing embedded assets
 * @author Joshua Granick
 */
class Assets
{
	
	/**
	 * Gets an instance of an embedded bitmap
	 * @usage		var bitmap = new Bitmap (Assets.getBitmapData ("image.jpg"));
	 * @param	id		The ID or asset path for the bitmap
	 * @return		A new BItmapData object
	 */
	public static function getBitmapData(id:String):BitmapData
	{
		return null;	
	}
	
	
	/**
	 * Gets an instance of an embedded binary asset
	 * @usage		var bytes = Assets.getBytes ("file.zip");
	 * @param	id		The ID or asset path for the file
	 * @return		A new ByteArray object
	 */
	public static function getBytes(id:String):ByteArray
	{	
		return null;
	}
	
	
	/**
	 * Gets an instance of an embedded font
	 * @usage		var fontName = Assets.getFont ("font.ttf").fontName;
	 * @param	id		The ID or asset path for the font
	 * @return		A new Font object
	 */
	public static function getFont(id:String):Font
	{
		return null;	
	}
	
	
	/**
	 * Gets an instance of an embedded sound
	 * @usage		var sound = Assets.getSound ("sound.wav");
	 * @param	id		The ID or asset path for the sound
	 * @return		A new Sound object
	 */
	public static function getSound(id:String):Sound
	{
		return null;
	}
	
	
	/**
	 * Gets an instance of an embedded text asset
	 * @usage		var text = Assets.getText ("text.txt");
	 * @param	id		The ID or asset path for the file
	 * @return		A new String object
	 */
	public static function getText(id:String):String
	{
		return null;
	}
	
}


#else
typedef Assets = nme.installer.Assets;
#end