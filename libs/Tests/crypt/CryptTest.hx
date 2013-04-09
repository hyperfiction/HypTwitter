import chx.crypt.Aes;
import chx.crypt.ModeECB;
import chx.crypt.ModeCBC;
import chx.crypt.IMode;
import chx.crypt.RSA;
import chx.crypt.PadPkcs1Type1;
import chx.crypt.PadPkcs1Type2;

enum CryptMode {
	CBC;
	ECB;
}

class I32Functions extends haxe.unit.TestCase {
	public function testLongs() {
		var s = Bytes.ofString("Whoa there nellie");
		var longs = I32.unpackLE( BytesUtil.nullPad(s, 4) );
		var sr =  BytesUtil.unNullPad( I32.packLE(longs) );

		assertTrue(BytesUtil.eq(s, sr));

#if nekomore
		if(s.length != sr.length)
			assertEquals(0,1);
		for(x in 0...s.length) {
			if(s[x].compare(sr[x]))
				assertEquals(0,2);
		}
#end

	}
}

class AesTestFunctions extends haxe.unit.TestCase {
	static var target = "69c4e0d86a7b0430d8cdb78070b4c55a";
	static var msg = [0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff];
	static var key = [0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f];
	static var ivstr = "00000000000000000000000000000000";

	static var b : Array<Int> = [128,192,256];

	public static var latin_cbc : String = "000000000000000000000000000000003EADB4B64216760699560EAD97228B35D50B2DBCD3D12A0683FEC3F3AFD4A92B067AD65E4E48548B81DD8A6B91C5B353D8BB83A016E68AC939A4C1CDD75B4672473FA7F9058296D8A918F5C94A6E26250300AD0D53B4FC2E4748B1AB1BFD16D124B7D212FCE96EBA9749F8C3837C55AA979216C1183C27EA4282C363EAA9ED061AFE3F2A1911A72A6E516715B14AAA17B9B9BE992CC5F67E5ACA5EFB571FBE911B5E84DA652E37DC1CC2B110F1C32132E5D6BFA19468182CA82340C353E40604370B703769330BCABD199F951C483EF98BC51D7ACEC0ABA4AF233DD28B27C8C345B972FFEA11A3DB9FCA26AC63C2C45B6FDAAC5659584997CDB7538E17F1C8D4188932E4A5DEE8F8D3727FE42A9296460E659E7A542B0C0F234D1E73DE6D118F371D0990AE8290E180EFE834D900BECD6D41AC8DE0129543A880DD0CA0E003B0A3746E3350514DD21FC567D8EFA6FC2AA051E7AB04A5EDD13F0E400DEF1D1B115F6C7A363E2BB20776B5560CE65E231CD75AEA42F7E75B01AF73B671551D21F1FCC708893968CB9B0D34711A1EABE94C49E213C8335DAEF639EF26E2218922130B3B0EA44870333C45B80A5E8AB27B2588907B9293CB4897E96D09F021B3A70378F567E8054B7FB8CA19BBD7BC87845C751C558B5BB31CDBCA8CDFDA0C8E157DF2F22D5471F4B30C06580DE7B363B46D08AE8761485B93385CDF4A00B042823AFA4557ED2230FEC128D979FFA5B77302393FF5F67A806B6E46EFC4B173889C51E89CB8A70EC529BCAAEC2211C3FFCE71684D7B4828A3BAD00147F637D075F657207EE980EA7EB4E67CF7FBA83DF0CE9E03AB5113B66510E4AEC00687BD920D1EE2DDACD91825A4E4867517F799844EBE04A9504582C208E55836413945AAE6BFC5411107B45A16A967A503F28F58777BF95203C835EF1D864CB255AE1BB06416FA3032639E4A3868DBEEF6335F995024E3F82EA091F5A927790E804C0DC685BB";

	public function testEcbOne() {
		var aes = new ModeECB( new Aes(128, BytesUtil.byteArrayToBytes(key)) );
		var e = aes.encrypt(BytesUtil.byteArrayToBytes(msg));

		assertEquals( target,
			BytesUtil.encodeToBase(e, Constants.DIGITS_HEXL).toString().substr(0,32)
		);
		//trace(BytesUtil.encodeToBase(e, Constants.DIGITS_HEXL));

	}

	public function testCbcOne() {
		var aes = new ModeCBC( new Aes(128, BytesUtil.byteArrayToBytes(key)) );
		aes.iv = BytesUtil.nullBytes(16);
		var e = aes.encrypt(BytesUtil.byteArrayToBytes(msg));
		assertEquals( ivstr + target,
				BytesUtil.encodeToBase(e, Constants.DIGITS_HEXL).toString().substr(0,64)
		);
	}

	public function testCbcTwo() {
		var aes = new ModeCBC( new Aes(128, BytesUtil.byteArrayToBytes(key)) );
		aes.iv = BytesUtil.nullBytes(16);
		var e = aes.encrypt(BytesUtil.byteArrayToBytes(msg));
		assertEquals( ivstr + target + "9e978e6d16b086570ef794ef97984232",
				BytesUtil.encodeToBase(e, Constants.DIGITS_HEXL).toString()
		);

	}

	public function testCbcThree() {
		var m = "yoyttt";
		var aes = new ModeCBC( new Aes(128, Bytes.ofString("pass")) );
		aes.iv = BytesUtil.nullBytes(16);
		var e = aes.encrypt(Bytes.ofString(m));
		var u = aes.decrypt(e);
		assertEquals(m, u.toString());
	}

	public function testCbcLatinEncrypt() {
		var aes = new ModeCBC( new Aes(128, Bytes.ofString(CommonData.latin_passphrase)) );
		aes.iv = BytesUtil.nullBytes(16);
		var e = aes.encrypt(Bytes.ofString(CommonData.latin));
		assertEquals( latin_cbc.toLowerCase(),
				BytesUtil.toHex(e, "")
		);
	}

	public function testEcbAll() {
		for(bits in b) {
			for(phrase in CommonData.phrases) {
				for(msg in CommonData.msgs) {
					assertEquals( true,
							doTestAes(bits, Bytes.ofString(phrase), Bytes.ofString(msg), ECB)
					);
				}
			}
		}
	}

	public function testCbcAll() {
		for(bits in b) {
			for(phrase in CommonData.phrases) {
				for(msg in CommonData.msgs) {
					assertEquals( true,
							doTestAes(bits, Bytes.ofString(phrase), Bytes.ofString(msg), CBC)
					);
				}
			}
		}
	}

	static function doTestAes(bits:Int, phrase:Bytes, msg:Bytes, mode) {
		var a = new Aes(bits, phrase);
		var aes : IMode; // =
		switch(mode) {
		case CBC: aes = cast { var c = new ModeCBC(a); c.iv = BytesUtil.nullBytes(16); c; }
		case ECB: aes = cast new ModeECB(a);
		}
		var enc: Bytes;
		try {
			enc = aes.encrypt(msg);
		}
		catch (e:Dynamic) {
			//trace(a);
			throw(e + " :: " + msg);
		}
		var dec : Bytes = null;
		try {
			dec = aes.decrypt(enc);
			if(dec.compare(msg) != 0) {
				trace("Orig: " + msg);
				trace("Orig Hex : " + BytesUtil.hexDump(msg));
				trace("Decr: " + dec);
				trace("Decr Hex : " + BytesUtil.hexDump(dec));
				return false;
			}
		}
		catch(e : Dynamic) {
			throw(e + " msg: " + msg + " :: msg len " + msg.length + " :: enc length " +enc.length + ":: " + BytesUtil.hexDump(enc)
			+ " :: dec length " + dec.length + " :: " + BytesUtil.hexDump(dec)
			);
		}
		return true;
	}

}


class PadFunctions extends haxe.unit.TestCase {
	function testPkcs1Type1() {
		var msg = Bytes.ofString("Hello");
		var padWith : Int = 0xFF; // Std.ord("A")
		var pad = new PadPkcs1Type1(16);
		pad.padByte = padWith;

		var s = pad.pad(msg);
		assertEquals(16, s.length);

		// expected result
		var sb = new BytesBuffer();
		sb.addByte(0);
		sb.addByte(1);
		var len = 16 - msg.length - 3;
		assertEquals(8, len);
		for(x in 0...len)
			sb.addByte(padWith & 0xFF);
		sb.addByte(0);
		sb.add(msg);

		var res = sb.getBytes();
		assertEquals(16, res.length);
		//trace(res.toHex());
		assertTrue(BytesUtil.eq(s, res));
		assertTrue(BytesUtil.eq(pad.unpad(s), msg));
	}

	function testPkcs1Type2() {
		var msg = Bytes.ofString("Hello");
		var padWith : Int = 0xFF; // Std.ord("A")
		var pad = new PadPkcs1Type2(16);
		pad.padByte = padWith;

		var s = pad.pad(msg);
		assertEquals(16, s.length);

		//trace(s.toHex());
		var rv : Bytes = pad.unpad(s);
		trace(rv.toString());
		assertTrue(BytesUtil.eq(rv, msg));
	}
}


class CryptTest {

	public static function main() {
#if (FIREBUG && ! neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new PadFunctions());
 		r.add(new I32Functions());
 		r.add(new AesTestFunctions());

		r.run();
	}
}
