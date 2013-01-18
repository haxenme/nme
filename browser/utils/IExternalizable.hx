package browser.utils;
#if js


interface IExternalizable {
	
	function readExternal(input:IDataInput):Void;
	function writeExternal(output:IDataOutput):Void;
	
}


#end