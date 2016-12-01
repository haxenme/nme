package nme.image;

import haxe.macro.Expr;
import haxe.macro.Context;

class PixelAlgorithm
{
   public static macro function processRgba( bitmapExpr:Expr, funcExpr:Expr, args:Array<Expr> )
   {
      args.unshift(macro image);
      var e = macro {
        var processed = true;
        var bitmap:nme.bare.Surface = ${bitmapExpr};
        switch( bitmap.format )
        {
           case nme.image.PixelFormat.pfRGBA:
              var image:nme.image.Image< nme.image.Bgra > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           case nme.image.PixelFormat.pfBGRPremA:
              var image:nme.image.Image< nme.image.BgrPremA > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           default:
              processed = false;
        }
        processed;
     }

     return e;
   }

   public static macro function processRgb( bitmapExpr:Expr, funcExpr:Expr, args:Array<Expr> )
   {
      args.unshift(macro image);
      var e = macro {
        var bitmap:nme.bare.Surface = ${bitmapExpr};
        var processed = true;
        switch( bitmap.format )
        {
           case nme.image.PixelFormat.pfRGBA:
              var image:nme.image.Image< nme.image.Bgra > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           case nme.image.PixelFormat.pfBGRPremA:
              var image:nme.image.Image< nme.image.BgrPremA > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});


           case nme.image.PixelFormat.pfRGB:
              var image:nme.image.Image< nme.image.Rgb > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           default:
              processed = false;
        }
        processed;
     };

     return e;
   }


   public static macro function processPixel( bitmapExpr:Expr, funcExpr:Expr, args:Array<Expr> )
   {
      args.unshift(macro image);
      var e = macro {
        var bitmap:nme.bare.Surface = ${bitmapExpr};
        var processed = true;
        switch( bitmap.format )
        {
           case nme.image.PixelFormat.pfRGBA:
              var image:nme.image.Image< nme.image.Bgra > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           case nme.image.PixelFormat.pfBGRPremA:
              var image:nme.image.Image< nme.image.BgrPremA > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           case nme.image.PixelFormat.pfRGB:
              var image:nme.image.Image< nme.image.Rgb > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           case nme.image.PixelFormat.pfLumaAlpha:
              var image:nme.image.Image< nme.image.LumaAlphaPixel > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           case nme.image.PixelFormat.pfLuma:
              var image:nme.image.Image< nme.image.LumaPixel > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           case nme.image.PixelFormat.pfAlpha:
              var image:nme.image.Image< nme.image.AlphaPixel > = nme.image.Image.fromSurface(bitmap);
              ${funcExpr}($a{args});

           default:
              processed = false;
        }
        processed;
     };

     return e;
   }


}


