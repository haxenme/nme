package nme.net;

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import haxe.io.Bytes;

/**
* @author   Hugh Sanderson
* @author   Niel Drummond
* @author   Russell Weir
* @todo open and progress events
* @todo Complete Variables type
**/
class URLLoader extends nme.events.EventDispatcher
{
   public var bytesLoaded(default,null):Int;
   public var bytesTotal(default,null):Int;
   public var data:Dynamic;
   public var dataFormat:URLLoaderDataFormat;

   public function new(?request:URLRequest)
   {
      super();
      bytesLoaded = 0;
      bytesTotal = 0;
      dataFormat = URLLoaderDataFormat.TEXT;
      if(request != null)
         load(request);
   }

   public function close() { }

   public function load(request:URLRequest)
   {
      #if (neko || cpp)
         var ereg = ~/^(http:\/\/)/;

         if(!ereg.match(request.url)) { // local file
            #if neko
            if(!neko.FileSystem.exists(request.url)) {
            #else
            if(!cpp.FileSystem.exists(request.url)) {
            #end
               onError("File not found");
               return;
            }
            #if neko
            switch(neko.FileSystem.kind(request.url)) {
            #else
            switch(cpp.FileSystem.kind(request.url)) {
            #end
            case kdir:
               onError("File " + request.url + " is a directory");
            default:
            }

            try {
               switch(dataFormat) {
               case BINARY:
					   #if neko
                  this.data = Bytes.ofString(neko.io.File.getContent(request.url));
                  #else
                  this.data = cpp.io.File.getBytes(request.url);
                  #end


               case TEXT, VARIABLES:
                  #if neko
                  this.data = neko.io.File.getContent(request.url);
                  #else
                  this.data = cpp.io.File.getContent(request.url);
                  #end
               }
            } catch(e:Dynamic) {
               onError(e);
               return;
            }
            dispatchEvent( new nme.events.Event(nme.events.Event.COMPLETE) );
            return;
         }
      #end
      var h = new haxe.Http( request.url );
      h.onData = onData;
      h.onError = onError;
      h.request( false );

   }

   public dynamic function onData (data:String) :Void {
      switch(dataFormat) {
      case BINARY:
         this.data = haxe.io.Bytes.ofString( data );
			bytesLoaded = bytesTotal= this.data.lenght;
      case TEXT:
         this.data = data;
			bytesLoaded = bytesTotal= data.length;
      case VARIABLES:
         throw "Not complete";
      }

      dispatchEvent( new nme.events.Event(nme.events.Event.COMPLETE) );
   }

   public dynamic function onError (msg) :Void {
      //trace(msg);
      dispatchEvent( new nme.events.IOErrorEvent(nme.events.IOErrorEvent.IO_ERROR, true, false, msg) );
   }

}

