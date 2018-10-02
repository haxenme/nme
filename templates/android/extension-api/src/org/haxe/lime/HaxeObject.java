package org.haxe.lime;

public class HaxeObject extends org.haxe.nme.HaxeObject
{
   public HaxeObject(long value) { super(value); }

   public static HaxeObject create(long inHandle) { return new HaxeObject(inHandle); }
}
