package browser.utils;
#if js


interface IMemoryRange {
	
	public function getByteBuffer():ByteArray;
	public function getStart():Int;
	public function getLength():Int;
   
}


#end