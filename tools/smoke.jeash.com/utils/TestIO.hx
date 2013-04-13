import flash.utils.ByteArray;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class TestIO extends TestCase
{
	static function main ()
	{
		//haxe.unit.TestRunner.print = untyped print;
		var runner = new TestRunner();
		runner.add( new TestIO() );
		var res = runner.run();
#if js untyped window.phantomTestResult = res; #end
	}

	function testReadWriteBoolean()
	{
		var data = new ByteArray();
		data.writeBoolean(true);
		data.position = 0;
		assertEquals( true, data.readBoolean() );
		data.writeBoolean(false);
		data.position = 1;
		assertEquals( false, data.readBoolean() );
	}

	function testReadWriteByte()
	{
		var data = new ByteArray();
		data.writeByte(127);
		data.position = 0;
		assertEquals( 127, data.readByte() );

		data.writeByte(34);
		data.position = 1;
		assertEquals( 34, data.readByte() );

		assertEquals( 2, data.length );
	}

	function testReadWriteBytes()
	{
		var input = new ByteArray();
		input.writeByte( 118 );
		input.writeByte( 38 );
		input.writeByte( 67 );
		input.writeByte( 89 );
		input.writeByte( 19 );
		input.writeByte( 17 );
		var data = new ByteArray();
	
		data.writeBytes( input, 0, 4 );
		assertEquals( 4, data.length );

		data.position = 0;
		var output = new ByteArray();
		data.readBytes( output, 0, 2 );

		assertEquals( 2, output.length );
		assertEquals( 118, output.readByte() );
		assertEquals( 38, output.readByte() );

		data.position = 2;
		data.writeBytes( input, 2, 4 );
		assertEquals( 6, data.length );

		data.position = 4;
		data.readBytes( output, 2, 2 );
		assertEquals( 4, output.length );
		output.position = 2;

		assertEquals( 19, output.readByte() );
		assertEquals( 17, output.readByte() );
	}

	function testReadWriteDouble()
	{
		var data = new ByteArray();
		data.writeDouble( Math.PI );
		data.position = 0;

		assertEquals( Math.PI, data.readDouble() );
		assertEquals( 8, data.position );

		data.position = 0;
		assertEquals( Math.PI, data.readDouble() );

		data.writeDouble( 6 );
		data.position = 8;

		assertEquals( 6., data.readDouble() );

		data.writeDouble( 3.121244489 );
		data.position = 16;

		assertEquals( 3.121244489, data.readDouble() );

		data.writeDouble( -0.000244489 );
		data.position = 24;

		assertEquals( -0.000244489, data.readDouble() );

		data.writeDouble( -99.026771 );
		data.position = 32;

		assertEquals( -99.026771, data.readDouble() );
	}

	function testReadWriteFloat()
	{
		var data = new ByteArray();
		data.writeFloat( 2);
		data.position = 0;

		assertEquals( 2., data.readFloat() );
		assertEquals( 4, data.position );

		data.writeFloat( .18 );
		data.position = 4;
		var actual = data.readFloat();
		assertTrue( .179999 < actual );
		assertTrue( .180001 > actual );
		
		data.writeFloat( 3.452221 );
		data.position = 8;
		var actual = data.readFloat();
		assertTrue( 3.452220 < actual );
		assertTrue( 3.452222 > actual );

		data.writeFloat( 39.19442 );
		data.position = 12;
		var actual = data.readFloat();
		assertTrue( 39.19441 < actual );
		assertTrue( 39.19443 > actual );

		data.writeFloat( .994423 );
		data.position = 16;
		var actual = data.readFloat();
		assertTrue( .994422 < actual );
		assertTrue( .994424 > actual );

		data.writeFloat( -.434423 );
		data.position = 20;
		var actual = data.readFloat();
		assertTrue( -.434421 > actual );
		assertTrue( -.434424 < actual );
	}

	function testReadWriteInt()
	{
		var data = new ByteArray();
		data.writeInt( 0xFFCC );
		assertEquals( 4, data.length );
		data.position = 0;

		assertEquals( 0xFFCC, data.readInt() );
		assertEquals( 4, data.position );

		data.writeInt( 0xFFCC99 );
		assertEquals( 8, data.length );
		data.position = 4;

		assertEquals( 0xFFCC99, data.readInt() );

		data.writeInt( 0xFFCC99AA );
		assertEquals( 12, data.length );
		data.position = 8;

		assertEquals( 0xFFCC99AA, data.readInt() );

	}

	/* Note: cannot find a test for this
	function testReadWriteMultiByte()
	{
		var data = new ByteArray();
		var encoding = "utf-8";
		data.writeMultiByte("a", encoding);
		assertEquals(4, data.length );
		data.position = 0;

		assertEquals( "a", data.readMultiByte(4, encoding));
	} */

	/* TODO: use haxe's serializer
	function testReadWriteObject()
	{
		var data = new ByteArray();
		var dummy = { txt: "string of dummy text" };
		data.writeObject( dummy );

		data.position = 0;
		assertEquals( dummy.txt, data.readObject().txt );
	}*/

	function testReadWriteShort()
	{
		var data = new ByteArray();
		data.writeShort( 5 );
		data.position = 0;

		assertEquals( 5, data.readShort() );
		assertEquals( 2, data.length );

		data.writeShort( 0xFC );
		data.position = 2;

		assertEquals( 0xFC, data.readShort() );
	}

	function testReadWriteUTF()
	{
		var data = new ByteArray();
		data.writeUTF("\xE9");

		data.position = 0;
		assertEquals(3, data.readUnsignedShort() );
		data.position = 0;

		assertEquals( "\xE9", data.readUTF() );
	}

	
	function testReadWriteUTFBytes()
	{
		var data = new ByteArray();
		var str = "H\xE9llo World !";
		data.writeUTFBytes(str);
		assertEquals(15, data.length);
		data.position = 0;

		assertEquals( str, data.readUTFBytes(15) );
	}

	function testReadWriteUnsigned()
	{
		var data = new ByteArray();
		data.writeByte( 4 );
		assertEquals( 1, data.length );
		data.position = 0;
		assertEquals( 4, data.readUnsignedByte() );
		data.position = 4;

		data.writeShort( 200 );
		assertEquals( 6, data.length );
		data.position = 4;

		assertEquals( 200, data.readUnsignedShort() );

		data.writeUnsignedInt( 65000 );
		assertEquals( 10, data.length );
		data.position = 6;

		assertEquals( 65000, data.readUnsignedInt() );
	}

	function testUncompress()
	{
		var data = new ByteArray();

		data.writeByte(120);
		data.writeByte(156);
		data.writeByte(203);
		data.writeByte(72);
		data.writeByte(205);
		data.writeByte(201);
		data.writeByte(201);
		data.writeByte(87);
		data.writeByte(200);
		data.writeByte(0);
		data.writeByte(145);
		data.writeByte(0);
		data.writeByte(25);
		data.writeByte(145);
		data.writeByte(4);
		data.writeByte(73);

		data.position = 0;

		data.uncompress();

		assertEquals(104, data.readUnsignedByte());
		assertEquals(101, data.readUnsignedByte());
		assertEquals(108, data.readUnsignedByte());
		assertEquals(108, data.readUnsignedByte());
		assertEquals(111, data.readUnsignedByte());
		assertEquals(32, data.readUnsignedByte());
		assertEquals(104, data.readUnsignedByte());
		assertEquals(101, data.readUnsignedByte());
		assertEquals(108, data.readUnsignedByte());
		assertEquals(108, data.readUnsignedByte());
		assertEquals(111, data.readUnsignedByte());
	}
}
