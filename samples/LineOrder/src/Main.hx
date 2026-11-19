import nme.display.*;
import nme.text.*;
import nme.events.*;
import nme.geom.*;

// Test for Graphics.lineOrder and Graphics.fillStyleSoftEdge.
//
// Each cell draws the same path with a different combination of line order and
//  soft-edge request.  The "Software" button sets cacheAsBitmap on the grid, which
//  renders the whole thing with the software renderer instead of the hardware one.
// The software renderer has no soft edge, so the soft-edge rows should look the
//  same as the rows above them there.
//
// Run with "software" on the command line to start in software mode.

class Main extends Sprite
{
   static inline var CELL = 110;
   static inline var MARGIN_X = 170;
   static inline var MARGIN_Y = 85;

   // Line order / soft edge combinations - one per row
   static inline var NO_LINE = 0;
   static inline var OVER = 1;
   static inline var UNDER = 2;
   static inline var LEGACY_SOFT = 3;
   // Two overlapping shapes, where the second one is flushed after a mid-path
   //  lineStyle change - this is the job insert-position case
   static inline var TWO_SHAPES = 4;

   static var rows:Array<{ name:String, mode:Int, soft:Bool }> = [
      { name:"no line",          mode:NO_LINE,     soft:false },
      { name:"no line + soft",   mode:NO_LINE,     soft:true  },
      { name:"over",             mode:OVER,        soft:false },
      { name:"over + soft",      mode:OVER,        soft:true  },
      { name:"under",            mode:UNDER,       soft:false },
      { name:"under + soft",     mode:UNDER,       soft:true  },
      { name:"lineStyleSoftEdge",mode:LEGACY_SOFT, soft:false },
      { name:"2 shapes: over,under", mode:TWO_SHAPES,  soft:false },
   ];

   // Path / paint combinations - one per column
   static inline var CLOSED = 0;
   static inline var OPEN = 1;

   static var cols:Array<{ name:String, path:Int, fillAlpha:Float, lineAlpha:Float, thickness:Float }> = [
      { name:"closed",      path:CLOSED, fillAlpha:1.0, lineAlpha:1.0, thickness:8.0 },
      { name:"alpha",       path:CLOSED, fillAlpha:0.4, lineAlpha:0.5, thickness:8.0 },
      { name:"thin",        path:CLOSED, fillAlpha:1.0, lineAlpha:1.0, thickness:1.0 },
      { name:"open",        path:OPEN,   fillAlpha:1.0, lineAlpha:1.0, thickness:8.0 },
   ];

   static inline var FILL_COLOUR = 0xe08020;
   static inline var LINE_COLOUR = 0x202060;

   var grid:Sprite;
   var butPos = 0.0;
   var modeLabel:TextField;

   // A single closed loop, with concave corners - explicitly closed, so no closing
   //  segment needs to be added by the flush
   static function starPath(gfx:Graphics, r:Float)
   {
      var n = 5;
      for(i in 0...n*2+1)
      {
         var theta = i*Math.PI/n - Math.PI*0.5;
         var rad = (i&1)==0 ? r : r*0.45;
         var x = Math.cos(theta)*rad;
         var y = Math.sin(theta)*rad;
         if (i==0)
            gfx.moveTo(x,y);
         else
            gfx.lineTo(x,y);
      }
   }

   // An open path - the fill closes it with a chord, and the flush adds a closing
   //  segment to the line
   static function openPath(gfx:Graphics, r:Float)
   {
      var n = 14;
      gfx.moveTo( Math.cos(-2.2)*r, Math.sin(-2.2)*r );
      for(i in 1...n+1)
      {
         var theta = -2.2 + i*4.4/n;
         gfx.lineTo( Math.cos(theta)*r, Math.sin(theta)*r*0.8 );
      }
   }

   // Two overlapping filled shapes, where the second one has a lineStyle change
   //  part way through its path.  That flushes the line job before the fill job,
   //  so the fill has to be inserted into the job list rather than appended.
   // The second shape (blue) must end up on top of the first (orange).
   static function twoShapes(gfx:Graphics, under:Bool, r:Float)
   {
      if (under)
         gfx.lineOrder(LineOrder.UNDER_FILL);

      gfx.beginFill(FILL_COLOUR);
      gfx.drawRect(-r, -r, r*1.3, r*1.3);

      gfx.beginFill(0x3060c0);
      gfx.lineStyle(4, 0x000000);
      var n = 8;
      for(i in 0...n+1)
      {
         var theta = i*2*Math.PI/n;
         var x = Math.cos(theta)*r*0.8 + r*0.25;
         var y = Math.sin(theta)*r*0.8 + r*0.25;
         if (i==0)
            gfx.moveTo(x,y);
         else
         {
            // Change the line style part way around
            if (i==n>>1)
               gfx.lineStyle(4, 0xffffff);
            gfx.lineTo(x,y);
         }
      }
      gfx.endFill();
   }

   static function drawCase(gfx:Graphics, row:Int, col:Int, r:Float)
   {
      var spec = rows[row];
      var paint = cols[col];

      if (spec.mode==TWO_SHAPES)
      {
         if (col<2)
            twoShapes(gfx, col==1, r);
         return;
      }

      if (spec.mode==UNDER)
         gfx.lineOrder(LineOrder.UNDER_FILL);

      if (spec.soft)
         gfx.fillStyleSoftEdge();

      gfx.beginFill(FILL_COLOUR, paint.fillAlpha);

      if (spec.mode==LEGACY_SOFT)
         gfx.lineStyleSoftEdge();
      else if (spec.mode!=NO_LINE)
         gfx.lineStyle(paint.thickness, LINE_COLOUR, paint.lineAlpha);

      if (paint.path==OPEN)
         openPath(gfx,r);
      else
         starPath(gfx,r);

      gfx.endFill();
   }

   function label(text:String, x:Float, y:Float, width:Float, ?size:Int)
   {
      var t = new TextField();
      t.text = text;
      t.x = x;
      t.y = y;
      t.width = width;
      t.height = 20;
      t.selectable = false;
      if (size!=null)
      {
         var fmt = t.defaultTextFormat;
         fmt.size = size;
         t.defaultTextFormat = fmt;
         t.text = text;
      }
      grid.addChild(t);
      return t;
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
      grid.cacheAsBitmap = value;
      modeLabel.text = value ? "software renderer" : "hardware renderer";
   }

   public function new()
   {
      super();

      grid = new Sprite();
      addChild(grid);

      var inset = 4.0;
      var size = CELL - inset*2;

      for(col in 0...cols.length)
         label(cols[col].name, MARGIN_X + col*CELL, MARGIN_Y-22, CELL);

      for(row in 0...rows.length)
      {
         label(rows[row].name, 10, MARGIN_Y + row*CELL + CELL*0.5 - 10, MARGIN_X-15);

         for(col in 0...cols.length)
         {
            var cx = MARGIN_X + col*CELL + inset;
            var cy = MARGIN_Y + row*CELL + inset;

            // Background, so semi-transparent paint can be seen
            var bg = new Shape();
            bg.x = cx;
            bg.y = cy;
            bg.graphics.beginFill(0xffffff);
            bg.graphics.drawRect(0,0,size,size);
            bg.graphics.beginFill(0x80a0c0);
            bg.graphics.drawRect(0,size*0.55,size,size*0.45);
            grid.addChild(bg);

            var s = new Shape();
            s.x = cx + size*0.5;
            s.y = cy + size*0.5;
            drawCase(s.graphics, row, col, size*0.42);
            grid.addChild(s);
         }
      }

      addButton("Software", ()->setSoftware(true));
      addButton("Hardware", ()->setSoftware(false));

      modeLabel = new TextField();
      modeLabel.width = 220;
      modeLabel.height = 25;
      modeLabel.selectable = false;
      modeLabel.x = butPos + 10;
      modeLabel.y = 2;
      addChild(modeLabel);

      setSoftware( Sys.args().indexOf("software") >= 0 );
   }
}
