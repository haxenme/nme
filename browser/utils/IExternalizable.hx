package browser.utils;


interface IExternalizable {
	
	function readExternal (input:IDataInput):Void;
	function writeExternal (output:IDataOutput):Void;
	
}