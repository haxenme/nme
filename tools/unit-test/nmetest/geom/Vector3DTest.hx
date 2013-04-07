package nmetest.geom;

import haxe.unit.*;
import nme.geom.Vector3D;

class Vector3DTest extends TestCase implements TestBase {
	public function testNew():Void {
		var v = new Vector3D();
		this.assertEquals(0.0, v.x);
		this.assertEquals(0.0, v.y);
		this.assertEquals(0.0, v.z);
		this.assertEquals(0.0, v.w);
		
		var v = new Vector3D(1.1, 2.2, 3.3, 4.4);
		this.assertEquals(1.1, v.x);
		this.assertEquals(2.2, v.y);
		this.assertEquals(3.3, v.z);
		this.assertEquals(4.4, v.w);
		
		var v = new Vector3D(1);
		this.assertEquals(1.0, v.x);
		this.assertEquals(0.0, v.y);
		this.assertEquals(0.0, v.z);
		this.assertEquals(0.0, v.w);
		
		var v = new Vector3D(1, 2);
		this.assertEquals(1.0, v.x);
		this.assertEquals(2.0, v.y);
		this.assertEquals(0.0, v.z);
		this.assertEquals(0.0, v.w);
		
		var v = new Vector3D(1, 2, 3);
		this.assertEquals(1.0, v.x);
		this.assertEquals(2.0, v.y);
		this.assertEquals(3.0, v.z);
		this.assertEquals(0.0, v.w);
	}
	
	public function testLength():Void {
		var v = new Vector3D(1, 1, 1);
		this.assertTrue( Math.abs(v.length - 1.732) < 0.001);
	}
	
	public function testLengthSquared():Void {
		var v = new Vector3D(1, 1, 1);
		this.assertEquals(3.0, v.lengthSquared);
	}
	
	public function testX_AXIS():Void {
		this.assertEquals(1.0, Vector3D.X_AXIS.x);
		this.assertEquals(0.0, Vector3D.X_AXIS.y);
		this.assertEquals(0.0, Vector3D.X_AXIS.z);
		this.assertEquals(0.0, Vector3D.X_AXIS.w);
	}
	
	public function testY_AXIS():Void {
		this.assertEquals(0.0, Vector3D.Y_AXIS.x);
		this.assertEquals(1.0, Vector3D.Y_AXIS.y);
		this.assertEquals(0.0, Vector3D.Y_AXIS.z);
		this.assertEquals(0.0, Vector3D.Y_AXIS.w);
	}
	
	public function testZ_AXIS():Void {
		this.assertEquals(0.0, Vector3D.Z_AXIS.x);
		this.assertEquals(0.0, Vector3D.Z_AXIS.y);
		this.assertEquals(1.0, Vector3D.Z_AXIS.z);
		this.assertEquals(0.0, Vector3D.Z_AXIS.w);
	}
	
	public function testAdd():Void {
		var v0 = new Vector3D(1., 2., 3., 4.);
		var v1 = new Vector3D(.1, .2, .3, .4);
		var v = v0.add(v1);
		
		this.assertEquals(1.1, v.x);
		this.assertEquals(2.2, v.y);
		this.assertEquals(3.3, v.z);
		this.assertEquals(0.0, v.w);
		
		this.assertTrue(v != v0);
	}
	
	public function testClone():Void {
		var v0 = new Vector3D(1.1, 2.2, 3.3, 4.4);
		var v = v0.clone();
		
		this.assertEquals(1.1, v.x);
		this.assertEquals(2.2, v.y);
		this.assertEquals(3.3, v.z);
		this.assertEquals(4.4, v.w);
		
		this.assertTrue(v != v0);
	}
	
	public function testCopyFrom():Void {
		var v0 = new Vector3D(1.1, 2.2, 3.3, 4.4);
		var v = new Vector3D(0, 0, 0, 1);
		v.copyFrom(v0);
		
		this.assertEquals(1.1, v.x);
		this.assertEquals(2.2, v.y);
		this.assertEquals(3.3, v.z);
		this.assertEquals(1.0, v.w);
	}
	
	public function testCrossProduct():Void {
		var v0 = new Vector3D(-1, 1, 2, 3);
		var v1 = new Vector3D(4, 3, 2, 1);
		var v = v0.crossProduct(v1);
		
		this.assertEquals(-4.0, v.x);
		this.assertEquals(10.0, v.y);
		this.assertEquals(-7.0, v.z);
		this.assertEquals(1.0, v.w);
		
		this.assertTrue(v != v0);
	}
	
	public function testDecrementBy():Void {
		var v = new Vector3D(1., 2., 3., 4.);
		var v1 = new Vector3D(-.1, -.2, -.3, -.4);
		v.decrementBy(v1);
		
		this.assertEquals(1.1, v.x);
		this.assertEquals(2.2, v.y);
		this.assertEquals(3.3, v.z);
		this.assertEquals(4.0, v.w);
	}
	
	public function testDistance():Void {
		var v0 = new Vector3D();
		var v1 = new Vector3D(1, 1, 1);
		
		this.assertTrue( Math.abs(Vector3D.distance(v0, v1) - 1.732) < 0.001);
	}
	
	public function testDotProduct():Void {
		var v0 = new Vector3D(-1, 1, 2, 3);
		var v1 = new Vector3D(4, 3, 2, 1);
		this.assertEquals(3.0, v0.dotProduct(v1));
	}
	
	public function testEquals():Void {
		var v0 = new Vector3D(-1, 1, 2, 3);
		var v1 = new Vector3D(-1, 1, 2, 3);
		this.assertTrue(v0.equals(v1));
		this.assertTrue(v0.equals(v1, false));
		this.assertTrue(v0.equals(v1, true));
		
		v1 = new Vector3D(-1, 1, 2, 0);
		this.assertTrue(v0.equals(v1));
		this.assertTrue(v0.equals(v1, false));
		this.assertFalse(v0.equals(v1, true));
		
		v1 = new Vector3D(0, 1, 2, 3);
		this.assertFalse(v0.equals(v1));
		this.assertFalse(v0.equals(v1, false));
		this.assertFalse(v0.equals(v1, true));
	}
	
	public function testIncrementBy():Void {
		var v = new Vector3D(1., 2., 3., 4.);
		var v1 = new Vector3D(.1, .2, .3, .4);
		v.incrementBy(v1);
		
		this.assertEquals(1.1, v.x);
		this.assertEquals(2.2, v.y);
		this.assertEquals(3.3, v.z);
		this.assertEquals(4.0, v.w);
	}
	
	public function testNearEquals():Void {
		var v0 = new Vector3D(-1, 1, 2, 3);
		var v1 = new Vector3D(-1.09, 1, 2, 3);
		this.assertTrue(v0.nearEquals(v1, 0.1));
		this.assertTrue(v0.nearEquals(v1, 0.1, false));
		//this.assertFalse(v0.nearEquals(v1, 0.1, true));
		
		v1 = new Vector3D(-1.1, 1, 2, 3);
		this.assertFalse(v0.nearEquals(v1, 0.1));
		this.assertFalse(v0.nearEquals(v1, 0.1, false));
		this.assertFalse(v0.nearEquals(v1, 0.1, true));
		
		v1 = new Vector3D(-1.09, 1, 2, 0);
		this.assertTrue(v0.nearEquals(v1, 0.1));
		this.assertTrue(v0.nearEquals(v1, 0.1, false));
		//this.assertTrue(v0.nearEquals(v1, 0.1, true));
	}
	
	public function testNegate():Void {
		var v = new Vector3D(1.1, 2.2, 3.3, 4.4);
		v.negate();
		
		this.assertEquals(-1.1, v.x);
		this.assertEquals(-2.2, v.y);
		this.assertEquals(-3.3, v.z);
		this.assertEquals(4.4, v.w);
	}
	
	public function testNormalize():Void {
		var v = new Vector3D(1.1, 0, 0, 4.4);
		this.assertEquals(1.1, v.normalize());
		this.assertEquals(1.0, v.x);
		this.assertEquals(0.0, v.y);
		this.assertEquals(0.0, v.z);
		this.assertEquals(4.4, v.w);
	}
	
	public function testProject():Void {
		var v = new Vector3D(2, 4, 6, 2);
		v.project();
		this.assertEquals(1.0, v.x);
		this.assertEquals(2.0, v.y);
		this.assertEquals(3.0, v.z);
		this.assertEquals(2.0, v.w);
	}
	
	public function testSetTo():Void {
		var v = new Vector3D(0, 0, 0, 4.4);
		v.setTo(1.1, 2.2, 3.3);
		this.assertEquals(1.1, v.x);
		this.assertEquals(2.2, v.y);
		this.assertEquals(3.3, v.z);
		this.assertEquals(4.4, v.w);
	}
	
	public function testScaleBy():Void {
		var v = new Vector3D(1, 2, 3, 4);
		v.scaleBy(1.5);
		this.assertEquals(1.5, v.x);
		this.assertEquals(3.0, v.y);
		this.assertEquals(4.5, v.z);
		this.assertEquals(4.0, v.w);
	}
	
	public function testSubtract():Void {
		var v0 = new Vector3D(1., 2., 3., 4.);
		var v1 = new Vector3D(-.1, -.2, -.3, -.4);
		var v = v0.subtract(v1);
		
		this.assertEquals(1.1, v.x);
		this.assertEquals(2.2, v.y);
		this.assertEquals(3.3, v.z);
		this.assertEquals(0.0, v.w);
		
		this.assertTrue(v != v0);
	}
	
	public function testToString():Void {
		var v = new Vector3D(1.1, 2.2, 3.3, 4.4);
		this.assertEquals("Vector3D(1.1, 2.2, 3.3)", v.toString());
	}
}