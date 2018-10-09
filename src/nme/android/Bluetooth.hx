package nme.android;

import nme.JNI;

@:nativeProperty
class BluetoothDeviceCallback
{
   var onDevices:Int->Array<String>->Void;
   public function new(inCallback:Int->Array<String>->Void) onDevices = inCallback;
   public function setDevicesAsync(inCode:Int, inDevices:Array<String>) onDevices(inCode,inDevices);
}

@:nativeProperty
class Bluetooth
{
   // ASync return codes
   public static inline var DISABLED = -2;
   public static inline var MISSING = -1;
   public static inline var OK = 0;
   public static inline var SCANNING = 1;
   public static inline var NONE_PAIRED = 2;

   var handle:Dynamic;


   public var portName(default,null):String;
   public var baud(default,null):Int;
   public var isSetup(default,null):Bool;


   public function new(inPortName:String, ?baud:Int = 9600, ?setupImmediately:Bool = false)
   {
      portName = inPortName;
      baud = 57600;

      handle = create(inPortName);

      if (!okFunc(handle))
        throw "Could not open bluetooth connection";

      isSetup = true;
   }

   static public function getDeviceListAsync(onDevices:Int->Array<String>->Void,inFullScan:Bool)
   {
      devicesAsync(new BluetoothDeviceCallback(onDevices),inFullScan);
   }

   static public function getDeviceList():Array<String>
   {
      getDevices();
      return [];
   }

   public function setup():Bool  return true;

   public function writeBytes(buffer:String):Int
   {
      return writeBytesFunc(handle,buffer);
   }

   public function readBytes(length:Int):String
   {
      return readBytesFunc(handle,length);
   }

   public function writeByte(byte:Int):Bool
   {
      return writeByteFunc(handle,byte);
   }

   public function readByte():Int
   {
      return readByteFunc(handle);
   }

   public function flush(?flushIn:Bool = false, ?flushOut = false):Void
   {
      //flushFunc(handle,flushIn,flushOut);
   }

   public function available():Int
   {
      return availableFunc(handle);
   }

   public function close():Int
   {
      var result =  closeFunc(handle);
      handle = null;
      return result;
   }

   static var create = JNI.createStaticMethod("org.haxe.nme.Bluetooth", "create", "(Ljava/lang/String;)Lorg/haxe/nme/Bluetooth;");
   static var getDevices = JNI.createStaticMethod("org.haxe.nme.Bluetooth", "getDevices", "()V");
   static var devicesAsync = JNI.createStaticMethod("org.haxe.nme.Bluetooth", "getDeviceListAsync", "(Lorg/haxe/nme/HaxeObject;Z)V");

   static var okFunc = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "ok", "()Z");
   static var writeBytesFunc = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "writeBytes", "(Ljava/lang/String;)I");
   static var readBytesFunc = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "readBytes", "(I)Ljava/lang/String;");
   static var writeByteFunc = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "writeByte", "(I)Z");
   static var readByteFunc = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "readByte", "()I");
   static var flushFunc = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "flush", "(ZZ)V");
   static var availableFunc = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "available", "()I");
   static var closeFunc = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "close", "()I");
}

