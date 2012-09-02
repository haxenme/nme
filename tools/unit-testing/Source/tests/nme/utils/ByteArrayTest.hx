package tests.nme.utils;

import haxe.unit.TestCase;
import nme.utils.ByteArray;
import nme.utils.Endian;

@:keep class ByteArrayTest extends TestCase {

	@Test
	public function testWritePos() 
	{
		var ba:ByteArray = new ByteArray();
		
		ba.endian = Endian.LITTLE_ENDIAN;
		
		assertEquals(0, ba.length);
		
		ba.writeByte(0xFF);
		assertEquals(1, ba.length);
		assertEquals(1, ba.position);
		assertEquals(0xFF, ba[0]);

		ba.position = 0;
		assertEquals(0, ba.position);
		ba.writeByte(0x7F);
		assertEquals(1, ba.length);
		assertEquals(1, ba.position);
		assertEquals(0x7F, ba[0]);
		
		ba.writeShort(0x1234);
		assertEquals(3, ba.length);
		assertEquals(3, ba.position);
		assertEquals(0x34, ba[1]);
		assertEquals(0x12, ba[2]);
		
		ba.clear();
		assertEquals(0, ba.length);
		
		ba.writeUTFBytes("TEST");
		assertEquals(4, ba.length);
		assertEquals(4, ba.position);

		ba.writeInt(0x12345678);
		assertEquals(8, ba.length);
		assertEquals(8, ba.position);

		ba.writeShort(0x1234);
		assertEquals(10, ba.length);
		assertEquals(10, ba.position);
		
		ba.position = 3;
		assertEquals(10, ba.length);
		ba.writeShort(0x1234);
		assertEquals(10, ba.length);
		assertEquals(5, ba.position);
	}
	
}