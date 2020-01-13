package nme.script;

import nme.filesystem.File;
import nme.system.System;
import nme.utils.ByteArray;
import nme.events.Event;
import sys.net.Host;
import sys.net.Socket;
import sys.FileSystem;
#if haxe4
import sys.thread.Thread;
import sys.thread.Deque;
#else
import cpp.vm.Thread;
import cpp.vm.Deque;
#end
import Sys;

using StringTools;


class Server
{
   public static var values = new Map<String,Dynamic>();
   public static var functions = new Map<String,Dynamic>();
   public static var enabled = true;
   public static var password:String = "";

   public var connectedHost(default,null):String;
   public var directory(default,null):String;
   public var restartOnScript:Bool;

   var script:String;
   var socket:Socket;
   var connectionStatus:String;
   var handler:IScriptHandler;
   var deque:Deque<Void->Void>;
   var postedResults:Deque<String>;

   public function new(inEngineName:String,
                       ?inDirectory:String,
                       ?inHandler:IScriptHandler)
   {
      handler = inHandler;
      restartOnScript = false;
      connectionStatus = "Not connected";
      connectedHost = null;
      setDir(inEngineName,inDirectory);
      deque = new Deque<Void->Void>();
      postedResults = new Deque<String>();
   }

   public static function setPassword(inValue:String) password = inValue;
   public static function setEnabled(inValue:Bool) enabled = inValue;

   public function pollQueue() : Void->Void
   {
      return deque.pop(false);
   }

   function log(inString:String)
   {
      if (handler!=null)
         handler.scriptLog(inString);
   }

   function setDir(inEngineName:String, inDirectory:String)
   {
      trace("setDir: " + inEngineName + "=" + inDirectory);
      directory = inDirectory;
      if (directory==null || directory=="")
      {
         directory = null;
         var host = nme.system.System.systemName();
         trace("Host : " + host);
         if (host=="android")
         {
            directory = "/mnt/sdcard/" + inEngineName;
            try
            {
               if (!sys.FileSystem.exists(directory))
               {
                  sys.FileSystem.createDirectory(directory);
                  trace('Made $directory');
               }
               else
               {
                  if (!sys.FileSystem.isDirectory(directory))
                  {
                     trace("Exists, but not directory:" + directory);
                     directory = null;
                  }
                  else
                  {
                     trace('Exists $directory, test write');
                     var bytes = haxe.io.Bytes.ofString("test");
                     sys.io.File.saveBytes(directory + "/test.txt", bytes);
                     trace("wrote ok.");
                  }
               }
            }
            catch(e:Dynamic)
            {
               trace('could not make directory');
               directory = null;
            }
         }
         if (directory==null)
         {
            var docsDir = nme.filesystem.File.documentsDirectory.nativePath;
            //directory = sys.FileSystem.fullPath( docsDir ) +  "/" + inEngineName;
            directory = docsDir +  "/" + inEngineName;
            trace("Docs dir: " + directory);
            try
            {
               sys.FileSystem.createDirectory(directory);
            }
            catch(e:Dynamic) {
               trace("Error creating " + directory + ":" + e);
            }
         }
      }
   }

   function readDir(outFiles:Array<String>, dir:String, file:String, recurse:Bool)
   {
      var path = file=="" ? dir :
           (file.substr(0,1)=="/" || file.substr(0,1)=="\\" || file.substr(1,1)==":") ? file : dir+"/"+file;
      if (!FileSystem.exists(path))
      {
         outFiles.push(" not a file - " + file);
      }
      else if (FileSystem.isDirectory(path))
      {
         try
         {
            var files = FileSystem.readDirectory(path);
            if (recurse)
               for(f in files)
                  readDir(outFiles, dir, file=="" ? f : file + "/" + f, true);
            else
               for(f in files)
                   outFiles.push(f);
         }
         catch(e:Dynamic)
         {
            outFiles.push(e);
         }
      }
      else
         outFiles.push(file);
   }

   function ls(args:Array<String>)
   {
      var result = new Array<String>();

      var recurse = false;
      if (args[0]=="-r")
      {
         recurse = true;
         args.shift();
      }

      if (args.length==0)
         args = [""];

      for(arg in args)
         readDir(result,directory,arg,recurse);

      return result.join("\n");
   }

   function getClasses() : String
   {
      #if cpp
      var newLine = "\n";
      untyped __cpp__("\n #ifdef HXCPP_HAS_CLASSLIST\n return __hxcpp_get_class_list()->join(newLine);\n #endif\n");
      #end
      return "";
   }

   function eval(value:Value):Dynamic
   {
      if (value==null)
         return null;

      switch(value)
      {
         case VMap(name): return values.get(name);
         case VValue(value) : return value;
         case VMember(instance,fieldName):
            return Reflect.getProperty(eval(instance),fieldName);
      }
   }

   function parseValue(instance:Value, inValue:String) : Value
   {
      if (inValue==null || inValue.length==0)
      {
         if (instance==null)
            throw "Missing identifier";
         return VValue(null);
      }

      if (inValue.length>1 && inValue.charAt(0)=="\"")
      {
         if (instance!=null)
            throw "Invalid mixing of string and value";
         if (inValue.charAt(inValue.length-1)!="\"")
            throw "Missing string termination";
         return VValue( inValue.substr(1, inValue.length-2) );
      }

      var parts=inValue.split(".");
      if (instance!=null)
      {
         if (parts.length==1)
         {
            return VMember(instance,inValue);
         }
         var id = parts.shift();
         return parseValue( VMember(instance,id), parts.join(".") );
      }

      if (inValue.charAt(0)=="$")
      {
         var id = parts.shift().substr(1);
         if (parts.length>0)
            return parseValue( VMap(id), parts.join(".") );

         return VMap(id);
      }


      var className = "";
      while(parts.length>0)
      {
         className += (className=="" ? "" : "." ) + parts.shift();
         var cls = Type.resolveClass(className);
         if (cls!=null)
         {
            if (parts.length==0)
               return VValue(cls);
            return parseValue( VValue(cls), parts.join("."));
         }
      }

      if (inValue=="null")
         return VValue(null);

      var value = Std.parseFloat(inValue);
      if (value!=Math.NaN)
         return VValue( value );

      // throw "unknown value :" + inValue;

      return VValue(inValue);
   }

   function evalGet(inValue:Value) : String
   {
      try
      {
         return eval(inValue);
      }
      catch(e:Dynamic)
      {
         return e;
      }
   }

   function evalSet(inTarget:Value, inValue:Value)
   {
      try
      {
         switch(inTarget)
         {
            case VMap(name) : values[name] = eval(inValue); return "set " + values[name];
            case VValue(_) : return "Can't set const value";
            case VMember(instance,fieldName):
               if (instance==null)
                   return "null instance";
               var value = eval(inValue);
               Reflect.setProperty(eval(instance), fieldName, value);
               return "set " + value;
         }
      }
      catch(e:Dynamic)
         return e;
   }

   function evalCall(inFunc:Value, inArgs:Array<Value>)
   {
      try
      {
         #if cpp
         var values = new Array<Dynamic>();
         var func = eval(inFunc);
         if (!Reflect.isFunction(func))
            return "value is not a function";
         for(a in inArgs)
            values.push( eval(a) );
         return untyped func.__Run(values);
         #else
         return "not supported";
         #end
      }
      catch(e:Dynamic)
         return e;
   }

   function postResult(inResult:String)
   {
       postedResults.push(inResult);
   }

   function waitSyncResult():String
   {
       return postedResults.pop(true);
   }


   function shell(inCommand:Array<String>) : String
   {
      var cmd = inCommand.shift();
      switch(cmd)
      {
         case "help":
            var extras = [];
            for(k in functions.keys()) extras.push(k);
            return "Commands: help, pwd, ls, kill, set, get, aset, aget, call, acall, classes, exit.\n"
             + "Extras :" + extras.join(", ");
         case "pwd":
            return directory;
         case "ls":
            return ls(inCommand);
         case "kill":
            Sys.exit(0);
            return "Dead";
         case "set","aset":
            var async = cmd=="aset";
            if (inCommand[0]=="" || inCommand[0]==null)
               return "usage: set name [value]";
            else if (handler==null && !async)
               return "no handler";
            else
            {
               try
               {
                  var target = parseValue(null,inCommand[0]);
                  var value = parseValue(null,inCommand[1]);
                  if (async)
                     return evalSet(target,value);
                  handler.scriptRunSync( function() postResult(evalSet(target,value)) );
                  return waitSyncResult();
               }
               catch(e:Dynamic)
                  { return Std.string(e); }
            }

         case "get","aget":
            var async = cmd=="aget";
            if (inCommand[0]=="" || inCommand[0]==null)
               return "usage: get name";
            else if (handler==null && !async)
               return "Error: no handler";
            else
               try
               {
                  var target = parseValue(null,inCommand[0]);
                  if (async)
                     return evalGet(target);
                  handler.scriptRunSync( function() postResult(evalGet(target)) );
                  return waitSyncResult();
               }
               catch(e:Dynamic)
                  { return Std.string(e); }

         case "call","acall":
            var async = cmd=="acall";
            if (inCommand[0]=="" || inCommand[0]==null)
               return "usage: call func arg arg ...";
            else if (handler==null && !async)
               return "Error: no handler";
            else
               try
               {
                  var func = parseValue(null,inCommand[0]);
                  var args = new Array<Value>();
                  for(i in 1...inCommand.length)
                     args.push( parseValue(null,inCommand[1]));

                  if (async)
                     return evalCall(func,args);
                  handler.scriptRunSync( function() postResult(evalCall(func,args)) );
                  return waitSyncResult();

               }
               catch(e:Dynamic)
                  { return Std.string(e); }


         case "classes":
            return getClasses();

         default:
            var func = functions.get(cmd);
            if (func!=null)
            {
               return untyped func.__Run(inCommand);
            }
            return "Unkown command: " + cmd;
      }
   }

   function handleConnection(connection:Socket)
   {
      try
      {
         var fromSocket = connection.input;
         var toSocket = connection.output;

         if (password!="")
         {
            var query = haxe.crypto.Md5.encode( Date.now().toString() );
            toSocket.writeInt32(query.length);
            toSocket.writeString(query);
            var len = fromSocket.readInt32();
            var result = "";
            if (len==query.length)
               result = fromSocket.readString(len);
            var target = haxe.crypto.Md5.encode( password + query );
            if (target!=result)
            {
               var message = "bad password";
               toSocket.writeInt32(message.length);
               toSocket.writeString(message);
               throw message;
            }
         }


         while(true)
         {
            var len = fromSocket.readInt32();
            if (len==0)
               break;
            var command = fromSocket.readString(len);
            log("command : " + command);
            if (command=="bye")
            {
               break;
            }
            else if (command=="shell")
            {
               var args = new Array<String>();
               var argCount = fromSocket.readInt32();
               for(i in 0...argCount)
               {
                  var len = fromSocket.readInt32();
                  args.push(fromSocket.readString(len));
               }

               var result = shell(args);
               toSocket.writeInt32(result.length);
               toSocket.writeString(result);
            }
            else if (command=="run")
            {
               var len = fromSocket.readInt32();
               var app = fromSocket.readString(len);
               log("Run " + app);
               var message = restartOnScript ? "restart" : "ok";
               toSocket.writeInt32(message.length);
               toSocket.writeString(message);

               var fullPath:String = null;
               var nmeName = directory+"/"+app;
               log("nmeName " + nmeName);
               if (FileSystem.exists(nmeName) && !FileSystem.isDirectory(nmeName) )
                  fullPath = nmeName;
               else
                  fullPath = directory+"/"+app+"/ScriptMain.cppia";
               log("fullPath " + fullPath);

               if (restartOnScript)
               {
                  connection.close();
                  // Restart
                  #if android
                  nme.system.System.restart();
                  #else
                  var exeName = nme.system.System.exeName;
                  var host = nme.system.System.systemName();
                  log("Restart " + exeName + " on " + host);
                  if (host=="mac")
                  {
                     var parts = exeName.split(".app");
                     if (parts.length>1)
                        exeName = parts[0] + ".app";
                     Sys.command("/usr/bin/open", ["-n", "-a", exeName, "--args", fullPath]);
                  }
                  else if (host=="linux")
                      Sys.command("/usr/bin/xdg-open", [exeName,fullPath]);
                  else
                      Sys.command(exeName,[fullPath]);
                  #end

                  if (socket!=null)
                  {
                     log("Closing socket");
                     try socket.close() catch(e:Dynamic) { }
                  }
                  Sys.exit(0);
               }
               else
               {
                  restartOnScript = true;
                  deque.push( function() Nme.runFile(fullPath) );
               }
            }
            else if (command=="put")
            {
               var len = fromSocket.readInt32();
               var to = fromSocket.readString(len);
               var dataLen = fromSocket.readInt32();
               var bytes = fromSocket.read(dataLen);
               log("Write " + to + " bytes :" + bytes.length);

               try
               {
                  to = to.split("\\").join("/");
                  var parts = to.split("/");
                  if (parts.length>1)
                  {
                     parts.pop();
                     var path = directory;
                     for(part in parts)
                     {
                        path += "/" + part;
                        if (!sys.FileSystem.exists(path))
                           sys.FileSystem.createDirectory(path);
                     }
                  }

                  sys.io.File.saveBytes(directory + "/" + to, bytes);
                  toSocket.writeInt32(2);
                  toSocket.writeString("ok");
               }
               catch(e:Dynamic)
               {
                  var err:String = e.toString();
                  toSocket.writeInt32(err.length);
                  toSocket.writeString(err);
               }
            }
            else if (command=="pull")
            {
               var len = fromSocket.readInt32();
               var from = fromSocket.readString(len);
               trace("Pull " + from );

               try
               {
                  from = from.split("\\").join("/");
                  var parts = from.split("/");

                  var bytes = sys.io.File.getBytes(directory + "/" + from);
                  if (bytes==null)
                     throw "no file";

                  toSocket.writeInt32(bytes.length);
                  toSocket.writeBytes(bytes,0,bytes.length);
                  trace("Sent " + from + " bytes :" + bytes.length);
               }
               catch(e:Dynamic)
               {
                  trace("Missing " + from );
                  toSocket.writeInt32(-1);
               }
            }
            else
            {
               log("Unknown command: " + command);
               break;
            }
         }
      }
      catch(e:Dynamic)
      {
         log("Socket done : " + e);
      }
      try
      {
         connection.close();
      }
      catch(e:Dynamic)
      {
         log("Socket closed : " + e);
      }
   }

   public function start()
   {
      var hostName = nme.system.System.getLocalIpAddress();
      var host = new sys.net.Host(hostName);
      log(" Listening on " + host + " (" + hostName + ")");
      connectionStatus = "Create socket";
      socket = new Socket();
      try
      {
         socket.bind(host,0xacad);
         socket.listen(1);
         connectionStatus = "Connected";
         connectedHost = host.toString();
      }
      catch(e:Dynamic)
      {
         socket.close();
         socket = null;
            connectionStatus = "Could not bind " + host.toString();
      }

      if (socket!=null)
      {
         Thread.create( function() {
            while(true)
            {
               log("Wait connection...");
               var connection = socket.accept();
               log("got connection");
               if (enabled)
               {
                  connection.setBlocking(true);
                  handleConnection(connection);
               }
               else
               {
                  log("Not enabled");
                  connection.close();
               }
            }
         });
      }
   }
}

