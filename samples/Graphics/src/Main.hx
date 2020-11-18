import nme.display.*;
import nme.text.*;
import nme.events.*;
import nme.geom.*;


class Main extends Sprite
{
   var views:Array< (Graphics,Float)->Void >;
   var shapes:Array<Shape>;
   var sprites:Array<Sprite>;
   var butPos = 0.0;
   static var bmpRgb:BitmapData;
   static var bmpRgba:BitmapData;
   static var tilesheet:Tilesheet;
   static var bmpPremA:BitmapData;
   static var bmpNoPremA:BitmapData;
   static var bmpPatches:BitmapData;
   static var bmpImage:BitmapData;

   public static function drawCircle(s:Shape, gfx:Graphics, t:Float)
   {
      gfx.beginFill(0xff0000);
      gfx.lineStyle(1,0x0000ff);
      gfx.drawCircle(0,0,80);
   }

   public static function drawLine(s:Shape, gfx:Graphics, t:Float)
   {
      gfx.lineStyle(5,0x000000);
      gfx.moveTo(-50,-50);
      gfx.cubicTo(-80,70,70,-33,50,50);
   }

   public static function drawBmpRepeatNearest(s:Shape, gfx:Graphics, t:Float)
   {
      gfx.beginBitmapFill(bmpRgb,null, true, false);
      gfx.drawRect(-70,-70,140,140);
   }

   public static function drawBmpNoRepeatSmooth(s:Shape, gfx:Graphics, t:Float)
   {
      gfx.beginBitmapFill(bmpRgb,null, false, true);
      gfx.drawRect(-70,-70,140,140);
   }

   public static function drawAlphaTiles(s:Shape, gfx:Graphics, t:Float)
   {
      var vals = new Array<Float>();
      for(r in 0...36)
      {
         var theta = r*Math.PI/18;
         vals.push( Math.sin(theta)*50 );
         vals.push( Math.cos(theta)*50 );
         vals.push( 0 );
         vals.push( (r+1)/36 );
      }
      tilesheet.drawTiles(gfx, vals, true, Tilesheet.TILE_ALPHA );
   }

   public static function drawGradient(s:Shape, gfx:Graphics, t:Float)
   {
      gfx.lineStyle(1,0x000000);
      var cols = [ 0xff0000, 0x00ff00 ];
      var alphas = [ 1.0, 1.0 ];
      var ratios = [ 0, 255 ];
      var mtx = new Matrix();
      mtx.createGradientBox(90, 40, Math.PI/4, -45, -20); 
      gfx.beginGradientFill( GradientType.LINEAR, cols, alphas, ratios, mtx,
             SpreadMethod.PAD, InterpolationMethod.LINEAR_RGB, 0.0);
      gfx.drawRect(-45,-20,90,40);
   }

   
   public static function drawRadialGradient(s:Shape, gfx:Graphics, t:Float)
   {
      gfx.lineStyle(1,0x000000);
      var cols = [ 0xff0000, 0x0000ff, 0x00ff00 ];
      var alphas = [ 1.0, 0.5, 1.0 ];
      var ratios = [ 0, 128, 255 ];
      var mtx = new Matrix();
      mtx.createGradientBox(90, 90, Math.PI/4, -45, -45); 
      gfx.beginGradientFill( GradientType.RADIAL, cols, alphas, ratios, mtx,
             SpreadMethod.REPEAT, InterpolationMethod.RGB, 0.75);
      gfx.drawRect(-45,-45,90,90);
   }

   static function overlayBmp(gfx:Graphics, bmp:BitmapData)
   {
      gfx.beginFill(0xf0f0f0);
      gfx.drawRect(-50,-50,100,100);
      var mtx = new Matrix();
      mtx.a = mtx.d = 100/32;
      mtx.tx -= 50;
      mtx.ty -= 50;
      gfx.beginBitmapFill(bmp, mtx, false, true);
      gfx.drawRect(-50,-50,100,100);
   }

   public static function drawPremA(s:Shape, gfx:Graphics, t:Float)
   {
      overlayBmp(gfx,bmpPremA);
   }

   public static function drawNoPremA(s:Shape, gfx:Graphics, t:Float)
   {
      overlayBmp(gfx,bmpNoPremA);
   }

   public static function drawColourTransform(s:Shape, gfx:Graphics, t:Float)
   {
      for(x in 0...4)
         for(y in 0...4)
         {
            gfx.beginFill( (x*255>>2) | (y*255>>2)<<8 | 128<<16  );
            gfx.drawRect(-45+x*24, -45+y*24, 20,20 );
         }
      s.transform.colorTransform = new ColorTransform(
            2,  0.5,  1.0,  0.9,
            -0.5, 1, 0.1, 0.15
            );
   }

   
   public static function drawBmpColourTransform(s:Shape, gfx:Graphics, t:Float)
   {
      var mtx = new Matrix();
      mtx.tx = -50;
      mtx.ty = -50;
      gfx.beginBitmapFill(bmpPatches,mtx,true);
      gfx.drawRect(-50,-50,100,100);
      s.transform.colorTransform = new ColorTransform(
            2,  0.5,  1.0,  0.9,
            -0.5, 1, 0.1, 0.15
            );
   }

   public static function drawColourVertex(s:Shape, gfx:Graphics, t:Float)
   {
      var sx = 1.0/bmpImage.width;
      var sy = 1.0/bmpImage.height;

      var theta = 0.1;
      var cos = Math.cos(theta);
      var sin = Math.cos(theta);
      var z = sin*100;
      var w0 = 150.0/(200.0+z);
      var w1 = 150.0/(200.0-z);

      var x0 = 0.0;
      var y0 = 0.0;
      var vertices = [
        x0 + 100*cos*w0,  y0  -100*w0,
        x0 + 100*cos*w0,  y0  +100*w0,
        x0 - 100*cos*w1,  y0  +100*w1,
        x0 - 100*cos*w1,  y0  -100*w1];

      var indices = [
         0, 1, 2,
         2, 3, 0 ];

      var tex_uv = [
        100.0*sx, 0.0,
        100.0*sx, 200.0*sy,
        300.0*sx, 200.0*sy,
        300.0*sx, 0.0  ];

      var tex_uvt = [
        100.0*sx, 0.0, w0,
        100.0*sx, 200.0*sy, w0,
        300.0*sx, 200.0*sy, w1,
        300.0*sx, 0.0, w1  ];

      var cols = [ 0xffff0000,
                   0xff00ff00,
                   0xff0000ff,
                   0xffffffff ];

      gfx.beginBitmapFill(bmpImage,true);
      gfx.lineStyle(1,0x0000ff);
      gfx.drawTriangles(vertices, indices, tex_uvt, null ,cols);
   }


   function changeRotation(delta:Float)
   {
      for(s in shapes)
          s.rotation += delta;
   }

   function addButton(name:String, callback:Void->Void)
   {
      var t = new TextField();
      t.text = name;
      t.height = 25;
      t.width = t.textWidth + 10;
      t.border = true;
      t.background = true;
      t.backgroundColor = 0xcccccc;
      t.borderColor = 0x000000;
      t.selectable = false;
      t.addEventListener( MouseEvent.CLICK, (_) -> callback() );
      addChild(t);
      t.x = butPos;
      t.y = 0;
      butPos += t.width+5;
   }

   function setSoftware(value:Bool)
   {
      //for(s in shapes)
         //s.cacheAsBitmap = value;
      cacheAsBitmap = value;
   }
 

   public function new()
   {
      super();
      views = [];
      shapes = [];
      sprites = [];

      bmpRgb = new BitmapData(32,32,false,0);
      var s = new Shape();
      s.graphics.beginFill(0x00ff00);
      s.graphics.drawRect( 8,8,16,16 );
      bmpRgb.draw(s);

      bmpRgba = new BitmapData(32,32,true,0);
      var s = new Shape();
      s.graphics.beginFill(0x0000ff,0.75);
      s.graphics.drawCircle( 16,16,13 );
      bmpRgba.draw(s);

      s.graphics.clear();
      s.graphics.beginFill(0xffffff);
      s.graphics.drawRect(5,5,22,22);
      bmpPremA = new BitmapData(32,32,true,0);
      bmpPremA.premultipliedAlpha = true;
      bmpPremA.draw(s);

      bmpNoPremA = new BitmapData(32,32,true,0);
      bmpNoPremA.premultipliedAlpha = false;
      bmpNoPremA.draw(s);

      tilesheet = new Tilesheet(bmpRgba);
      tilesheet.addTileRect( new Rectangle(0,0,32,32), new Point(16,16) );

      bmpPatches = new BitmapData(100,100,true,0);
      s.graphics.clear();
      for(x in 0...4)
         for(y in 0...4)
         {
            s.graphics.beginFill( (x*255>>2) | (y*255>>2)<<8 | 128<<16  );
            s.graphics.drawRect(5+x*24, 5+y*24, 20,20 );
         }
      bmpPatches.draw(s);

      bmpImage = nme.Assets.getBitmapData("Image.jpg");



      var v = 0;
      for(f in Type.getClassFields(Main))
      {
         if (f.substr(0,4)=="draw")
         {
            var c = new Sprite();
            addChild(c);
            sprites.push(c);
            c.x = 100 + (v%4) * 200;
            c.y = 100 + (v>>2) * 200;
            var t = new TextField();
            t.text = f.substr(4);
            c.addChild(t);
            t.x=-100;
            t.y=75;
            t.width=200;
            t.height=25;

            var s = new Shape();
            shapes.push(s);
            c.addChild(s);
            v+=1;
            Reflect.field(Main,f)(s, s.graphics, 0.0);
         }
      }


      addButton("Software", ()->setSoftware(true));
      addButton("Hardware", ()->setSoftware(false));
      addButton("R+", ()->changeRotation(45));
      addButton("R-", ()->changeRotation(-30));

   }
}

