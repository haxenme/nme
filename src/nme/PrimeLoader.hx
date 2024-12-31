package nme;

import haxe.macro.Expr;

class PrimeLoader
{
   public static inline macro function load(inName2:Expr, inSig:Expr)
   {
      #if nme_static_link
      return macro nme.macros.Prime.load("", $inName2, $inSig, false);
      #else
      return macro nme.macros.Prime.load("nme", $inName2, $inSig, false);
      #end
   }
}

