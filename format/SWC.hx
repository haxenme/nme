package format;

import haxe.io.BytesInput;
import nme.utils.ByteArray;

#if cpp
import cpp.zip.Reader;
#elseif neko
import neko.zip.Reader;
#end

/**
 * ...
 * @author Joshua Granick
 */

class SWC extends SWF
{
	
	public function new(inStream:ByteArray)
	{
		var foundEntry = false;
		
		#if (cpp || neko)
		var entries = Reader.readZip (new BytesInput (inStream));
		
		for (entry in entries)
		{
			if (entry.fileName == "library.swf")
			{
				var swf = Reader.unzip (entry);
				super (ByteArray.fromBytes (swf));
				foundEntry = true;
			}
		}
		#end
		
		if (!foundEntry)
		{
			super (new ByteArray ());
		}
	}
	
}