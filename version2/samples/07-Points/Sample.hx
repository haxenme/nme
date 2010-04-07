import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Rectangle;
import nme.text.TextField;
import nme.text.TextFieldAutoSize;
import nme.text.TextFormat;   



/**
 * Based on code by Joa Ebert
 */


class Particle 
{
   public function new() { x=y=z=0.0; }

   public var x: Float;
   public var y: Float;
   public var z: Float;
}


class Sample extends Sprite 
{
   private static var MAX_PARTICLES: Int = 10000;
   private var _targetX: Float;
   private var _targetY: Float;

   private var _text : TextField;
   private var _particles: Array<Particle>;
   private var _xy: Array<Float>;
   private var _times: Array<Float>;
   private var _cols: Array<Int>;
   
   public function new()
   {
      super();
      nme.Lib.current.addChild(this);
      _targetX = 0.0;
      _targetY = 0.0;
      _xy = [];
      _times = [];
      _cols = [];
      screenSetup();
      createParticles();
      calculatePositions();

      addEventListener( Event.ENTER_FRAME, onEnterFrame );
   }

   private function screenSetup(): Void
   {
      var tf : TextFormat = new TextFormat();
      tf.font = 'arial';
      tf.size = 10;
      tf.color = 0xffffff;
      
      _text = new TextField();
      _text.autoSize = TextFieldAutoSize.LEFT;
      _text.defaultTextFormat = tf;
      _text.selectable = false;
      _text.text = "0 fps";
      _text.y = 400 - _text.height;
      _text.opaqueBackground = 0x000000;
      addChild( _text );
   }
   
   private function createParticles(): Void
   {
      _particles = [];
      for(i in 0...MAX_PARTICLES)
      {
         _particles.push(new Particle());
         _cols.push( nme.display.Graphics.RGBA(Std.int(Math.random()*0xffffff),0x80) );
      }
   }
   
   private function calculatePositions(): Void
   {
      var _a:Float = 1.111;
      var _b:Float = 1.479;
      var _f:Float = 4.494;
      var _g:Float = 0.44;
       var _d:Float = 0.135;
      var cx:Float = 1;
      var cy:Float = 1;
      var cz:Float = 1;
      var mx:Float = 0;
      var my:Float = 0;
      var mz:Float = 0;
      
      var scale:Float = 40;
      
      for(particle in _particles)
      {
         mx = cx + _d * (-_a * cx - cy * cy - cz * cz + _a * _f);
         my = cy + _d * (-cy + cx * cy - _b * cx * cz + _g);
         mz = cz + _d * (-cz + _b * cx * cy + cx * cz);
         
         cx = mx;
         cy = my;
         cz = mz;
         
         particle.x = mx * scale;
         particle.y = my * scale;
         particle.z = mz * scale;
      }
   }
   
   private function onEnterFrame( event: Event ): Void
   {
      _targetX += ( mouseX - 275 ) * 0.0003;
      _targetY += ( mouseY - 150 ) * 0.0003;
      
      
      var x: Float;
      var y: Float;
      var z: Float;
      var w: Float;
      
      var pz: Float;
      
      var xi: Int;
      var yi: Int;

      var cx = Math.cos(_targetX);
      var sx = Math.sin(_targetX);
      var cy = Math.cos(_targetY);
      var sy = Math.sin(_targetY);

      var p00: Float = -sy;
      var p01: Float = 0;
      var p02: Float = cy;

      var p10: Float = sx*cy;
      var p11: Float = cx;
      var p12: Float = sx*sy;

      var p20: Float = cx*cy;
      var p21: Float = -sx;
      var p22: Float = cx*sy;

      var p23: Float = 10;
  
      
      var cx: Float = 240.0;
      var cy: Float = 200.0;
      var minZ: Float = 0.0;

      var xy = _xy;
      var idx = 0;

      for(particle in _particles)
      {
         x = particle.x; y = particle.y; z = particle.z;
         xy[idx++] = (( x * p00 + y * p01 + z * p02 ) + cx );
         xy[idx++] = (( x * p10 + y * p11 + z * p12 ) + cy );
      }

      var gfx = graphics;
      gfx.clear();
      gfx.drawPoints(xy,_cols);

      var now = haxe.Timer.stamp();
      _times.push(now);
      while(_times[0]<now-1)
          _times.shift();
      _text.text = _times.length + " fps";

   }

public static function main()
{
   nme.Lib.create(function(){new Sample();},550,400,60,0x202040,
        (1*nme.Lib.HARDWARE) | nme.Lib.RESIZABLE);
}


}

