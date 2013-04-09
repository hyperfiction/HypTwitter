import chx.hash.Md2;
import chx.hash.Md5;
import chx.hash.Sha1;
import chx.hash.Sha256;


class Vectors {
	public static function Sha1() {
		var message : Array<String> = new Array();
		var hash : Array<String> = new Array();
		message.push("");
		hash.push("DA39A3EE5E6B4B0D3255BFEF95601890AFD80709");

		message.push("a");
		hash.push("86F7E437FAA5A7FCE15D1DDCB9EAEAEA377667B8");

		message.push("abc");
		hash.push("A9993E364706816ABA3E25717850C26C9CD0D89D");

		message.push("message digest");
		hash.push("C12252CEDA8BE8994D5FA0290A47231C1D16AAE3");

		message.push("abcdefghijklmnopqrstuvwxyz");
		hash.push("32D10C7B8CF96570CA04CE37F2A19D84240D3A89");

		message.push("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
		hash.push("84983E441C3BD26EBAAE4AA1F95129E5E54670F1");

		message.push("ABCDEFGHIJKLMNOPQRSTUVWXYZZabcdefghijklmnopqrstuvwxyzz0123456789");
		hash.push("32ebf96b6fe3561d2368873b45c82af1d101dad3");

		var sb = new StringBuf();
		for(x in 0...8)
			sb.add("1234567890");
		message.push(sb.toString());
		hash.push("50ABF5706A150990A08B2C5EA40FA0E585554732");

#if neko
		//1 million times "a"
		sb = new StringBuf();
		for(x in 0...100000)
			sb.add("aaaaaaaaaa");
		message.push(sb.toString());
		hash.push("34AA973CD4C4DAA4F61EEB2BDBAD27316534016F");
#end

		for(x in 0...hash.length)
			hash[x] = hash[x].toLowerCase();
		return { messages: message, hashes : hash };
	}
}

class Sha1TestFunctions extends haxe.unit.TestCase {

	public function testSha() {
		assertEquals(
			"a9993e364706816aba3e25717850c26c9cd0d89d",
			Sha1.encode(Bytes.ofString("abc")).toHex()
		);
		assertEquals(
			"03cfd743661f07975fa2f1220c5194cbaff48451",
			Sha1.encode(Bytes.ofString("abc\n")).toHex()
		);
		assertEquals(
			"84983e441c3bd26ebaae4aa1f95129e5e54670f1",
			Sha1.encode(Bytes.ofString("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")).toHex()
		);
	}

	public function testVectors() {
		var o = Vectors.Sha1();
		for(x in 0...o.messages.length) {
			try {
				assertEquals(o.hashes[x], Sha1.encode(Bytes.ofString(o.messages[x])).toHex());
			}
			catch(e:Dynamic) {
				trace("Error on Sha1 Test Vector # " + Std.string(x+1));
				throw currentTest;
			}
		}
	}

	public function testNulls() {
		// nulls
		var blah = BytesUtil.nullBytes(30);
		var res = "deb6c11e1971aa61dbbcbc76e5ea7553a5bea7b7";

		assertEquals(res, Sha1.encode(blah).toHex());
	}

#if neko
	public function testObjSha() {

		assertEquals(
			"a9993e364706816aba3e25717850c26c9cd0d89d",
			Sha1.objEncode("abc")
		);
		assertEquals(
			"03cfd743661f07975fa2f1220c5194cbaff48451",
			Sha1.objEncode("abc\n")
		);
		assertEquals(
			"84983e441c3bd26ebaae4aa1f95129e5e54670f1",
			Sha1.objEncode("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
		);

	}

	public function testPrintValues() {
		var o = {
			field1 : "abc",
			field2 : "def"
		}
		neko.Lib.println("\n"+ Sha1.objEncode(o));
		neko.Lib.println(Sha1.objEncode(this));

		assertEquals(1,1);
	}

	public function testStream() {
		var sha = new Sha1();
		sha.init();
		sha.update("a");
		sha.update("b");
		sha.update("c");
		var rv = sha.final();

		assertEquals(
			"a9993e364706816aba3e25717850c26c9cd0d89d",
			rv
		);

	}
#end

}

class Sha256TestFunctions extends haxe.unit.TestCase {
	public function testSha256() {
		assertEquals(
			"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
			Sha256.encode(Bytes.ofString("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")).toHex()
		);
	}
}

class Md5TestFunctions extends haxe.unit.TestCase {
	function testMd5() {
		assertEquals("098f6bcd4621d373cade4e832627b4f6",
			Md5.encode(Bytes.ofString("test")).toHex());
	}

	function testMd5Empty() {
		assertEquals("d41d8cd98f00b204e9800998ecf8427e",
			Md5.encode(Bytes.ofString("")).toHex());
	}
}

class Md2Test extends haxe.unit.TestCase {
	function test01() {
		assertEquals("8350e5a3e24c153df2275c9f80692773",
			Md2.encode(Bytes.ofString("")).toHex());
	}

	function test02() {
		assertEquals("32ec01ec4a6dac72c0ab96fb34c0b5d1",
			Md2.encode(Bytes.ofString("a")).toHex());
	}

	function test03() {
		assertEquals("da853b0d3f88d99b30283a69e6ded6bb",
			Md2.encode(Bytes.ofString("abc")).toHex());
	}

	function test04() {
		assertEquals("ab4f496bfb2a530b219ff33031fe06b0",
			Md2.encode(Bytes.ofString("message digest")).toHex());
	}

	function test05() {
		assertEquals("4e8ddff3650292ab5a4108c3aa47940b",
			Md2.encode(Bytes.ofString("abcdefghijklmnopqrstuvwxyz")).toHex());
	}

	function test06() {
		assertEquals("da33def2a42df13975352846c30338cd",
			Md2.encode(Bytes.ofString("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")).toHex());
	}

}

class HashTest {
	static function main()
	{
#if (FIREBUG && !neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end

		var r = new haxe.unit.TestRunner();
		//r.add(new Sha1TestFunctions());
		r.add(new Sha256TestFunctions());
		r.add(new Md5TestFunctions());
		r.add(new Md2Test());
		r.run();
	}
}
