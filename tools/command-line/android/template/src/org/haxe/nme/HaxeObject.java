package org.haxe.nme;

public class HaxeObject
{
   long __haxeHandle;

   public HaxeObject(long value)
   {
      __haxeHandle = value;
   }

   protected void finalize() throws Throwable {
    try {
        NME.releaseInterface(__haxeHandle);
    } finally {
        super.finalize();
    }
   }

   public Object call0(String function)
   {
      return NME.callObjectFunction(__haxeHandle,function,new Object[0]);
   }
   public Object call1(String function,Object arg0)
   {
      Object[] args = new Object[1];
      args[0] = arg0;
      return NME.callObjectFunction(__haxeHandle,function,args);
   }
   public Object call2(String function,Object arg0,Object arg1)
   {
      Object[] args = new Object[2];
      args[0] = arg0;
      args[1] = arg1;
      return NME.callObjectFunction(__haxeHandle,function,args);
   }
   public Object call3(String function,Object arg0,Object arg1,Object arg2)
   {
      Object[] args = new Object[2];
      args[0] = arg0;
      args[1] = arg1;
      args[2] = arg2;
      return NME.callObjectFunction(__haxeHandle,function,args);
   }

   public Object callD0(String function)
   {
      return NME.callNumericFunction(__haxeHandle,function,new Object[0]);
   }
   public Object callD1(String function,Object arg0)
   {
      Object[] args = new Object[1];
      args[0] = arg0;
      return NME.callNumericFunction(__haxeHandle,function,args);
   }
   public Object callD2(String function,Object arg0,Object arg1)
   {
      Object[] args = new Object[2];
      args[0] = arg0;
      args[1] = arg1;
      return NME.callNumericFunction(__haxeHandle,function,args);
   }
   public Object callD3(String function,Object arg0,Object arg1,Object arg2)
   {
      Object[] args = new Object[2];
      args[0] = arg0;
      args[1] = arg1;
      args[2] = arg2;
      return NME.callNumericFunction(__haxeHandle,function,args);
   }





   public Object call(String function, Object[] args)
   {
      return NME.callObjectFunction(__haxeHandle,function,args);
   }
   public double callD(String function, Object[] args)
   {
     return NME.callNumericFunction(__haxeHandle,function,args);
   }
}
