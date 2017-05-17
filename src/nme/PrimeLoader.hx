package nme;

import haxe.macro.Expr;

class PrimeLoader
{
   public static inline macro function load(inName2:Expr, inSig:Expr)
   {
      return macro nme.macros.Prime.load("nme", $inName2, $inSig, false);
   }
}

