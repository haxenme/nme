package nme.utils;

class WeakRef<T>
{
   var ref:Int;

   public function new(inObject:T)
   {
      ref = nme_weak_ref_create(this,inObject);
   }
   public function get() : T
   {
      if (ref<0)
         return null;
      var result = nme_weak_ref_get(ref);
      if (result==null)
         ref = -1;
      return result;
   }
   public function toString() : String
   {
      return "WeakRef(" + ref+ ")";
   }

   static var nme_weak_ref_create = nme.Loader.load("nme_weak_ref_create",2);
   static var nme_weak_ref_get = nme.Loader.load("nme_weak_ref_get",1);
}
