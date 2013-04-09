
import chx.io.BytesInput;
import haxe.Int32;

class BytesInputTestFunctions extends haxe.unit.TestCase {
	var b : Bytes;
	public function new() {
		super();
		var bb : BytesBuffer = new BytesBuffer();
		for(i in 0...256) {
			bb.addByte(i);
		}
		b = bb.getBytes();
	}

	public function testLength() {
		assertEquals(256, b.length);
	}

	public function testReadSingleByte() {
		var bi:BytesInput = new BytesInput(b);
		var v:Int = -1;
		for(i in 0...256) {
			v = bi.readUInt8();
			assertEquals(i, v);
			assertEquals(i+1,bi.position);
		}
	}

	public function testRead2Byte() {
		var bi:BytesInput = new BytesInput(b);
		var v:Int = -1;
		for(i in 0...128) {
			v = bi.readUInt16();
			//assertEquals(i, v);
			assertEquals((i+1)*2,bi.position);
		}
	}

	public function testRead3Byte() {
		var bi:BytesInput = new BytesInput(b);
		var v:Int = -1;
		for(i in 0...85) {
			v = bi.readInt24();
			//assertEquals(i, v);
			assertEquals((i+1)*3,bi.position);
		}

		bi = new BytesInput(b);
		for(i in 0...85) {
			v = bi.readUInt24();
			//assertEquals(i, v);
			assertEquals((i+1)*3,bi.position);
		}
	}

	public function testRead4Byte() {
		var bi:BytesInput = new BytesInput(b);
		var v:Int = -1;
		for(i in 0...64) {
			try v = bi.readInt31() catch(e:Dynamic) {};
			//assertEquals(i, v);
			assertEquals((i+1)*4,bi.position);
		}

		bi = new BytesInput(b);
		for(i in 0...64) {
			try v = bi.readUInt30() catch(e:Dynamic) {};
			//assertEquals(i, v);
			assertEquals((i+1)*4,bi.position);
		}
	}

	public function testReadInt32() {
		var bi:BytesInput = new BytesInput(b);
		var v:Int32 = Int32.ofInt(-1);
		for(i in 0...64) {
			v = bi.readInt32();
			//assertEquals(i, v);
			assertEquals((i+1)*4,bi.position);
		}
	}

	public function testPosition() {
		var bi:BytesInput = new BytesInput(b);
		var p:Int = bi.position;
		assertEquals(0, p);
		bi.position = 10;
		p = bi.readUInt8();
		assertEquals(10, p);
		bi.position = 0;
		p = bi.readUInt8();
		assertEquals(0, p);
	}

	public function testReadBytes() {
		var bi:BytesInput = new BytesInput(b);
		bi.position = 10;
		var p:Int = bi.position;
		var dest = Bytes.alloc(10);
		bi.readBytes(dest, 0, 10);
		assertEquals(20,bi.position);
		for(i in 0...10) {
			assertEquals(i+10, dest.get(i));
		}
	}

}

class BytesTest {

	public static function main() {
#if (FIREBUG && ! neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new BytesInputTestFunctions());
		r.run();
	}
}