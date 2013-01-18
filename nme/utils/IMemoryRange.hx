package nme.utils;
#if display


extern interface IMemoryRange {
	
	function getByteBuffer():ByteArray;
	function getStart():Int;
	function getLength():Int;
   
}


#elseif (cpp || neko)
typedef IMemoryRange = native.utils.IMemoryRange;
#elseif js
typedef IMemoryRange = browser.utils.IMemoryRange;
#end