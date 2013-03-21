package nme.utils;

/**
 * ...
 * @author Andreas Rønning
 */
class StringUtils
{
	public static inline function capitalize(s:String):String {
		return s.substr(0, 1).toUpperCase() + s.substr(1);
	}
	
}