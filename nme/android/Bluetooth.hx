package nme.android;

import nme.JNI;

class BluetoothDeviceCallback
{
   var onDevices:Int->Array<String>->Void;
   public function new(inCallback:Int->Array<String>->Void) onDevices = inCallback;
   public function setDevicesAsync(inCode:Int, inDevices:Array<String>) onDevices(inCode,inDevices);
}

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
      return 0;
   }

   public function readBytes(length:Int):String return "";

   public function writeByte(byte:Int):Bool return false;

   public function readByte():Int return 0;

   public function flush(?flushIn:Bool = false, ?flushOut = false):Void return;

   public function available():Int return 0;

   public function close():Int
   {
      return 0;
   }

   static var create = JNI.createStaticMethod("org.haxe.nme.Bluetooth", "create", "(Ljava/lang/String;)Lorg/haxe/nme/Bluetooth;");
   static var getDevices = JNI.createStaticMethod("org.haxe.nme.Bluetooth", "getDevices", "()V");
   static var devicesAsync = JNI.createStaticMethod("org.haxe.nme.Bluetooth", "getDeviceListAsync", "(Lorg/haxe/nme/HaxeObject;Z)V");
}

