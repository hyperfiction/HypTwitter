import chx.crypt.ModeECB;
import chx.crypt.ModeCBC;
import chx.crypt.IMode;
import chx.crypt.RSA;
import chx.crypt.RSAEncrypt;
import chx.crypt.PadPkcs1Type1;
import chx.crypt.PadPkcs1Type2;
import chx.crypt.PadPkcs5;

//1024 bit exponent 3
class RSAK1 {
	public static var modulus: String = "00:bc:7a:6e:3d:6b:11:e0:c3:2f:e2:4a:31:1b:07:b3:42:73:ab:27:29:55:b2:f7:05:9a:43:e2:33:96:63:5f:20:a1:a0:70:44:82:1e:16:08:65:ea:51:58:5c:a6:36:b2:b2:1e:76:97:87:b5:8f:ec:c4:38:de:55:88:71:24:d2:59:ca:dc:1c:8d:70:fe:3f:11:d7:39:5f:20:b2:35:ab:0b:62:c2:b2:07:b8:a8:d4:4a:31:95:0e:56:f1:46:94:ba:37:41:cf:94:e3:54:8f:9f:d5:05:05:69:5a:5b:31:c6:24:20:30:8f:db:74:52:14:89:d9:f9:86:3e:cf:01";
	public static var publicExponent: String = "3";
	public static var privateExponent: String = "7d:a6:f4:28:f2:0b:eb:2c:ca:96:dc:20:bc:af:cc:d6:f7:c7:6f:70:e3:cc:a4:ae:66:d7:ec:22:64:42:3f:6b:16:6a:f5:83:01:69:64:05:99:46:e0:e5:93:19:79:cc:76:be:f9:ba:5a:79:0a:9d:d8:25:e9:8e:5a:f6:18:8b:16:ef:dc:54:d5:6f:40:5d:63:2b:d7:57:7c:ab:21:31:5f:90:ef:40:40:e9:16:a3:a3:c3:cd:8b:9a:35:ba:eb:ff:db:65:da:a9:30:1c:52:93:df:76:53:32:dc:fb:11:b8:9b:78:d7:82:1b:c0:3c:f4:f0:e9:b8:a5:16:3d:cb";
	public static var prime1:String = "00:df:8a:67:bf:66:bd:ed:7e:7b:7f:3b:9a:ff:0f:d1:ac:eb:69:ef:12:0e:a5:eb:6d:38:d2:8a:92:29:f0:5f:47:3b:dd:37:48:cc:15:21:35:cf:bf:d4:cf:51:89:34:3d:5a:bf:fb:55:31:89:f1:ee:91:be:88:87:0d:92:bc:3d";
	public static var prime2:String = "00:d7:d8:a9:dd:e6:8c:30:34:81:96:3a:c0:e6:a1:b2:34:10:9f:6c:bf:97:b5:1b:71:9b:b9:56:2a:c5:b0:4e:eb:7e:90:f1:be:cb:06:08:dd:f2:45:fe:b9:4b:85:ae:59:d6:7a:ef:98:1b:27:e2:08:13:61:f2:dd:81:0a:b6:15";
	public static var exponent1:String = "00:95:06:ef:d4:ef:29:48:fe:fc:ff:7d:11:ff:5f:e1:1d:f2:46:9f:61:5f:19:47:9e:25:e1:b1:b6:c6:a0:3f:84:d2:93:7a:30:88:0e:16:23:df:d5:38:8a:36:5b:78:28:e7:2a:a7:8e:21:06:a1:49:b6:7f:05:af:5e:61:d2:d3";
	public static var exponent2:String = "00:8f:e5:c6:93:ef:08:20:23:01:0e:d1:d5:ef:16:76:cd:60:6a:48:7f:ba:78:bc:f6:67:d0:e4:1c:83:ca:df:47:a9:b5:f6:7f:32:04:05:e9:4c:2e:a9:d0:dd:03:c9:91:39:a7:4a:65:67:6f:ec:05:62:41:4c:93:ab:5c:79:63";
	public static var coefficient:String = "48:ba:40:c3:e7:ce:91:1c:c5:51:3b:e1:3c:72:31:12:07:1b:20:5e:c2:2d:c6:d2:7c:68:62:85:3b:95:4a:49:86:fa:23:fa:ed:24:e9:40:4e:04:56:f9:4a:f2:48:4e:39:ca:05:75:a5:11:5f:5e:d3:c1:36:bd:fa:71:b5:19";
}

// 1024 bit exponent 0x10001
class RSAK2 {
	public static var modulus: String = "00:d4:79:4c:3d:82:85:1a:d1:ca:71:f1:b4:48:1d:98:1c:2c:86:51:14:be:55:8f:bf:11:1f:cc:d4:e1:ed:c9:2c:06:42:4a:29:8e:0b:5a:31:6d:9e:9b:73:3b:7b:15:01:e1:04:c3:82:59:55:05:51:87:c4:5c:38:a6:8a:46:da:7f:ce:2a:47:4c:ea:89:c0:08:d9:2b:38:7b:d0:21:d4:ef:80:07:4b:57:22:b0:cc:86:92:67:38:5b:6b:c3:25:59:21:c0:40:64:01:ba:d8:3c:46:56:9f:1f:e7:0c:b8:8e:ea:0e:f9:39:be:8a:05:3a:92:79:7c:a5:d9:2c:43";
	public static var publicExponent: String = "01:00:01"; // 65537 
	public static var privateExponent: String = "35:8f:d2:69:5b:22:c4:cd:08:14:cb:52:a0:2f:5d:ae:14:87:53:9f:40:0f:ff:a9:b1:de:6b:5b:6b:0c:ef:7e:ba:a1:31:62:e2:5c:f8:42:a7:98:a9:25:56:64:43:ba:72:88:29:e5:0d:32:02:a2:37:f0:87:32:fc:c0:b4:f5:5f:d9:c3:51:17:5a:00:37:4d:e8:3f:0c:86:75:da:7f:a3:8c:a7:50:70:eb:a0:1a:05:c0:3a:4f:12:2c:73:d6:d4:0b:10:16:61:d4:ed:fe:82:df:c5:d9:40:49:9a:7c:7e:0f:c8:b6:12:99:51:82:dd:a2:ea:d6:c0:4d:ba:e9";

	public static var prime1:String = "00:ff:6d:00:81:ef:40:ca:30:17:76:20:3b:5e:53:8b:55:98:67:60:e3:52:c8:4d:68:b6:17:8e:60:6d:4b:0b:64:9d:5e:2e:e7:74:06:b3:06:3b:71:d2:0d:23:87:e2:5e:67:a4:95:6a:d9:da:9a:de:22:02:40:b9:0a:c8:b5:0f";
	public static var prime2:String = "00:d4:f3:93:af:3a:60:e9:35:92:58:4a:2e:c1:30:a5:39:d7:ac:3f:00:fb:f8:11:c3:f3:47:5a:d4:7b:93:d5:48:65:d3:f5:bc:43:ae:9c:1a:d1:7c:b9:9c:59:a4:17:b5:ad:29:c1:cc:4e:14:7e:c2:f2:5a:e1:0c:b2:09:5d:8d";
	public static var exponent1:String = "00:e5:f9:bf:8e:3d:db:a8:ef:d9:ff:ea:8f:69:a3:70:fd:95:65:e6:ef:66:36:a0:b3:d9:d7:a5:c2:9e:45:06:32:06:1a:a9:c2:8d:4e:06:dc:62:a3:5d:8b:a4:e5:10:e5:0d:0e:3b:d5:e3:e6:96:af:d0:11:15:33:46:49:65:f3";
	public static var exponent2:String = "00:c5:35:5d:8b:65:30:e2:47:ee:63:3d:2f:d7:51:49:72:2b:bd:24:0b:b1:4c:a6:87:25:00:eb:a8:e3:58:a0:a8:0f:45:1f:c9:5d:94:92:94:73:74:62:1f:dd:14:0d:b0:fd:d0:31:dd:16:61:fc:92:65:06:ac:6b:a9:64:ea:f1";
	public static var coefficient:String = "00:c9:c9:32:e0:fa:7b:55:b9:f8:c2:cd:47:94:0f:8b:a1:6b:06:38:29:eb:e1:8a:b2:02:6e:26:84:be:f0:be:ca:ea:7d:00:29:50:0e:f8:c2:ce:cd:cf:2e:5f:07:36:36:7f:7a:3e:d1:34:1e:f2:89:f1:d4:f5:6e:e4:c2:68:df";
}

	// a 256 bit key
class RSAK3 {
	// n
	public static var modulus : String = "b59a93b2891782d4929e5e89b52ffd61852704c3ee7b15643ffe53910d3bad19";
	// e
	public static var publicExponent : String = "3";
	// d
	public static var privateExponent : String = "7911b7cc5b6501e30c69945bce1ffe3fe21e66ee5d4c6a77297904d2e1daeb23";

	// p
	public static var prime1 : String = "f155e239a68fb5a0208e2abe6787d1d7";
	// q
	public static var prime2 : String = "c0a38824bbf8c011613aa19652eb7a8f";
	// dmp1
	public static var exponent1:String = "a0e3ec266f0a79156b0971d44505368f";
	// dmq1
	public static var exponent2:String = "806d056dd2a5d560eb7c6bb98c9cfc5f";
	// coeff
	public static var coefficient : String = "3e5323aa1e3c5ac2860f6b389d08d885";
}

class RsaTest extends haxe.unit.TestCase {

	public static function main() {
#if (FIREBUG && ! neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new RsaTest());
		//r.run();

		var r = new RSAEncrypt(RSAK1.modulus, RSAK1.publicExponent);
		var rsa = new ModeECB( r, new PadPkcs5(r.blockSize) );
		trace(rsa.encrypt(Bytes.ofString("message")).toHex());
	}

	function test0() {
		//trace('===== test0 =====');
		var r = new RSA(RSAK1.modulus, RSAK1.publicExponent, RSAK1.privateExponent);
		//r.setPrivateEx(modulus, publicExponent,privateExponent,prime1,prime2,null,null,coefficient);

		for(s in CommonData.msgs) {
			var e = r.encrypt(Bytes.ofString(s));
			var u = r.decrypt(e);
			assertTrue(u.toString() == s);
			// expensive and slow, RSA will timeout flash or JS
			#if flash break; #end
		}
	}

	function testECB() {
		var s = "Message";
		var r = new RSA(RSAK1.modulus, RSAK1.publicExponent, RSAK1.privateExponent);
// trace('');
// var te = t.encryptBlock( s );
// trace("Hex dump");
// trace(BytesUtil.hexDump(te));
// var td = t.decryptBlock(te);
// trace("Raw td");
// trace(td);
// trace("Hex dump");
// trace(BytesUtil.hexDump(td));
		var rsa = new ModeECB( r, new PadPkcs5(r.blockSize) );
		for(s in CommonData.msgs) {
			//trace(s);
			//trace(s.length);
			var e = rsa.encrypt(Bytes.ofString(s));
			//trace(e.length);
			var u = rsa.decrypt(e);
			//trace(u.toString());
			assertTrue(u.toString() == s);
			// expensive and slow, RSA will timeout flash or JS
			#if flash break; #end
		}
	}

	function testCBC() {
		var s = "Message";
		var r = new RSA(RSAK1.modulus, RSAK1.publicExponent, RSAK1.privateExponent);
		var rsa = new ModeCBC( r, new PadPkcs5(r.blockSize) );
		for(s in CommonData.msgs) {
			//trace(s);
			//trace(s.length);
			var e = rsa.encrypt(Bytes.ofString(s));
			//trace(e.length);
			var u = rsa.decrypt(e);
			//trace(u.toString());
			assertTrue(u.toString() == s);
			// expensive and slow, RSA will timeout flash or JS
			#if flash break; #end
		}
	}

	function test02() {
		var msg = "Hello";
		var rsa:RSA = RSA.generate(512, "3");
		//trace(rsa);
		var e = rsa.encrypt(Bytes.ofString(msg));
		var u = rsa.decrypt(e);
		assertEquals(msg,u.toString());
		assertEquals(true, true);
	}


	function test03() {
		var msg = "Hello";

		var rsa = new RSA();
		rsa.setPrivate(RSAK3.modulus, RSAK3.publicExponent, RSAK3.privateExponent);
		//rsa.setPrivateEx(RSAK3.modulus, RSAK3.publicExponent, RSAK3.privateExponent,
		//				RSAK3.prime1, RSAK3.prime2, null, null, RSAK3.coefficient);

		var e = rsa.encrypt(Bytes.ofString(msg));
		var u = rsa.decrypt(e);
		assertEquals(msg,u.toString());

	}

	function testSigning() {
		var msg = "Hello";
		var md5 = new chx.hash.Md5();
		var hashed = md5.calculate(Bytes.ofString(msg));

		var rsa = new RSA();
		//rsa.setPrivate(RSAK3.modulus, RSAK3.publicExponent, RSAK3.privateExponent);
		rsa.setPrivateEx(RSAK2.modulus, RSAK2.publicExponent, RSAK2.privateExponent,
						RSAK2.prime1, RSAK2.prime2, RSAK2.exponent1, RSAK2.exponent2, RSAK2.coefficient);
		//rsa.setPrivateEx(RSAK3.modulus, RSAK3.publicExponent, RSAK3.privateExponent,
		//				RSAK3.prime1, RSAK3.prime2, RSAK3.exponent1, RSAK3.exponent2, RSAK3.coefficient);
		trace(rsa);
		trace(rsa.blockSize);
		trace(rsa.n.bitLength());

		var e : Bytes = rsa.sign(hashed);

		var rsa2 = new RSAEncrypt(RSAK2.modulus, RSAK2.publicExponent);
		trace(rsa2.blockSize);
		trace(rsa2.n.bitLength());
		var u = rsa2.verify(e);
		//assertEquals(msg,u.toString());

		trace(hashed);
		assertEquals(hashed.toHex(), u.toHex());
	}

	function testSpeed() {
		var msg = "Hello";
		var rsa = new RSA();
		rsa.setPrivate(RSAK3.modulus, RSAK3.publicExponent, RSAK3.privateExponent);

		var start = haxe.Timer.stamp();
		for(x in 0...100) {
			var e = rsa.sign(Bytes.ofString(msg));
		}
		var time = haxe.Timer.stamp() - start;

		rsa.setPrivateEx(RSAK3.modulus, RSAK3.publicExponent, RSAK3.privateExponent,
						RSAK3.prime1, RSAK3.prime2, null, null, RSAK3.coefficient);
		start = haxe.Timer.stamp();
		for(x in 0...100) {
			var e = rsa.sign(Bytes.ofString(msg));
		}
		var time2 = haxe.Timer.stamp() - start;
		trace("Normal time: " + time + " CRT time: " + time2);
		assertEquals(1,1);
	}

#if neko

	function testRsa128Generate() {
		var num : Int = 10;
		var bits : Int = 128;
		var exp : String = "10001";
		trace("Generating " + num +" " + bits + " bit RSA keys");
		var msg = "Hello";
		for(x in 0...num) {
			var rsa:RSA = RSA.generate(bits, exp);
			var e = rsa.encrypt(Bytes.ofString("Hello"));
			if(e == null)
				throw "e is null";
			var u = rsa.decrypt(e);
			if (u == null) {
				trace(e);
				trace(u);
				throw "u is null";
			}
			assertEquals(msg, u.toString().substr(u.length-msg.length));
		}
	}
#end
}

