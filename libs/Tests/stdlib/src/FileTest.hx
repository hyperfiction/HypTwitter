import chx.io.File;

class FileTest extends haxe.unit.TestCase
{

	public static function main() {
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
		var r = new haxe.unit.TestRunner();
		r.add(new FileTest());

		r.run();
	}

	public function testFileContents() {
		var s = File.getContent("sample.txt");
		assertEquals("Test content", s);
		assertEquals("5465737420636f6e74656e74", File.getBytes("sample.txt").toHex());
	}

	public function testFileWriteBytes() {
		var data = "test data";

		var fo = File.write("testFileWriteBytes.txt", true);
		var b = Bytes.ofString(data);
		fo.writeBytes(b, 0, b.length);
		fo.close();
		assertEquals(true, true);

		// read
		b = Bytes.alloc(1024);
		var fi = File.read("testFileWriteBytes.txt", true);
		var len = fi.readBytes(b, 0, 1024);
		assertEquals(len, data.length);
		var s : String = b.sub(0, len).toString();
		assertEquals(data, s);
	}
}
