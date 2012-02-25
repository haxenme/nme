package nme.net;
#if (cpp || neko || js)


enum URLRequestMethod
{
	DELETE;
	GET;
	HEAD;
	OPTIONS;
	POST;
	PUT;
}


#else
typedef URLRequestMethod = flash.net.URLRequestMethod;
#end