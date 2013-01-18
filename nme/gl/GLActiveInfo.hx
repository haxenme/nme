package nme.gl;
#if display


typedef GLActiveInfo = {
	
    size : Int,
    type : Int,
    name : String,
	
};


#elseif (cpp || neko)
typedef GLActiveInfo = native.gl.GLActiveInfo;
#elseif js
typedef GLActiveInfo = browser.gl.GLActiveInfo;
#end