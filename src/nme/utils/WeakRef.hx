package nme.utils;
#if (!flash)

import nme.Loader;

// This should actually be "possible WeakRef"
// Sadly, the last parameter differes completely in meaning from the cpp.vm.WeakRef. Oops.
class WeakRef<T> 
{
   /** @private */ private var hardRef:T; // Allowing for the reference to be hard simplfies usage
   #if cpp
   /** @private */ private var weakRef:Dynamic;
   #else
   /** @private */ private var weakRef:Int;
   #end

   public function new(inObject:T, inMakeWeak:Bool = true) 
   {
      if (inMakeWeak) 
      {
         #if cpp
         weakRef =  untyped __global__.__hxcpp_weak_ref_create(inObject);
         #else
         weakRef = nme_weak_ref_create(this, inObject);
         #end
         hardRef = null;

      } else 
      {
         #if cpp
         weakRef = null;
         #else
         weakRef = -1;
         #end
         hardRef = inObject;
      }
   }

   public function get():T 
   {
      if (hardRef != null)
         return hardRef;

      #if cpp
      if (weakRef==null)
         return null;
      var result:Dynamic = untyped __global__.__hxcpp_weak_ref_get(weakRef);
      if (result == null)
         weakRef = null;
      #else
      if (weakRef < 0)
         return null;
      var result = nme_weak_ref_get(weakRef);
      if (result == null)
         weakRef = -1;
      #end

      return result;
   }

   public function toString():String 
   {
      if (hardRef != null)
         return "" + hardRef;

      return "WeakRef(" + get() + ")";
   }

   // Native Methods
   #if !cpp
   private static var nme_weak_ref_create:Dynamic = Loader.load("nme_weak_ref_create", 2);
   private static var nme_weak_ref_get:Dynamic = Loader.load("nme_weak_ref_get", 1);
   #end
}

#elseif flash

import flash.utils.Dictionary;

class WeakRef<T> 
{
   var value:T;
   public function new(inObject:T, inMakeWeak:Bool = true) 
   {
      value = inObject;
   }
   public function get():T 
   {
      return value;
   }
  /*
   var dict:Dictionary;
   public function new(inObject:T, inMakeWeak:Bool = true) 
   {
      dict = new Dictionary(inMakeWeak);
      dict[inObject] = 1;
   }

   public function get():T 
   {
      for(key in dict.keys())
         return key;
      return null;
   }
   */

}


#end
