import chx.crypt.Cipher;
import chx.crypt.CipherParams;
import chx.crypt.mode.CBC;
import chx.crypt.mode.CFB;
import chx.crypt.mode.CFB8;
import chx.crypt.mode.CTR;
import chx.crypt.mode.OFB;
import chx.crypt.padding.PadNone;
import chx.crypt.symmetric.Aes;
import chx.crypt.symmetric.XXTea;
import chx.io.BytesOutput;

import haxe.unit.TestCase;

/**
 * Hawt NIST Vectors: http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf
 **/
class IVModeTest extends TestCase
{

	public static function main() {
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
		var r = new haxe.unit.TestRunner();
		r.add(new IVModeTest());

		r.run();
	}

	// IVs may need left padding... test it here
	public function testPad() : Void {
		var b = Bytes.alloc(0);
		b = BytesUtil.leftPad(b, 8);
		assertEquals(8, b.length);
		assertEquals(0, b.get(1));

		b = Bytes.alloc(8);
		for(i in 0...8) b.set(i,23);
		b = BytesUtil.leftPad(b,8);
		assertEquals(8, b.length);
		for(i in 0...8)
			assertEquals(23, b.get(i));
		
		b = Bytes.alloc(1);
		b.set(0, 23);
		b = BytesUtil.leftPad(b, 7, 1);
		assertEquals(7, b.length);
		assertEquals(1, b.get(0));
		assertEquals(23, b.get(6));
	}
	
	function aes_common(key:Bytes, bits:Int, mode, iv:Bytes, pt:Bytes, ct:Bytes) : Cipher {
		var p = new CipherParams();
		p.iv = iv;
		var cipher = new Cipher(new Aes(bits,key), mode, new PadNone());
		cipher.init(ENCRYPT, p);

		var out = new BytesOutput();
		var num = cipher.final(pt,0,pt.length,out);
		var crypted = out.getBytes();
		assertEquals(ct.toHex(), crypted.toHex());

		cipher.init(DECRYPT, p);
		out = new BytesOutput();
		num = cipher.final(crypted,0,crypted.length,out);
		var decrypted = out.getBytes();
		assertEquals(pt.toHex(), decrypted.toHex());
		return cipher;
	}

	function aescbc(key:Bytes, bits:Int, iv:Bytes, pt:Bytes, ct:Bytes) {
		aes_common(key, bits, new CBC(), iv, pt, ct);
	}

	function aesofb(key:Bytes, bits:Int, iv:Bytes, pt:Bytes, ct:Bytes) {
		aes_common(key, bits, new OFB(), iv, pt, ct);
	}

	function aescfb8(key:Bytes, bits:Int, iv:Bytes, pt:Bytes, ct:Bytes) {
		aes_common(key, bits, new CFB8(), iv, pt, ct);
	}

	function aescfb(key:Bytes, bits:Int, iv:Bytes, pt:Bytes, ct:Bytes) {
		aes_common(key, bits, new CFB(), iv, pt, ct);
	}

	public function testStepped() : Void {
		trace("\n============== STEPPED CBC AES 128 ==========\n");
		var key:Bytes = Bytes.ofHex("2b7e151628aed2a6abf7158809cf4f3c");
		var iv:Bytes = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		var pt:Bytes = Bytes.ofHex("6bc1bee22e409f96e93d7e117393172a"+"ae2d8a571e03ac9c9eb76fac45af8e51");
		var ct:Bytes = Bytes.ofHex("7649abac8119b246cee98e9b12e9197d"+"5086cb9b507219ee95db113a917678b2");

		var p = new CipherParams();
		p.iv = iv;
		var cipher = new Cipher(new Aes(128,key), new CBC(), new PadNone());
		cipher.init(ENCRYPT, p);
		var out = new BytesOutput();
		var num = cipher.update(pt, 0, 3, out);
		assertEquals(3, num);
		num = cipher.update(pt,3,2,out);
		assertEquals(2, num);
		num = cipher.update(pt,5, 13,out);
		assertEquals(13, num);
		num = cipher.final(pt, 18, pt.length-18, out);
		assertEquals(14, num);
		var crypted = out.getBytes();
		assertEquals(ct.toHex(), crypted.toHex());

		cipher.init(DECRYPT, p);
		out = new BytesOutput();
		num = cipher.final(crypted,0,crypted.length,out);
		var decrypted = out.getBytes();
		assertEquals(pt.toHex(), decrypted.toHex());
	}

	public function testCBC_AES128():Void {
		trace("\n============== CBC AES 128 ==========\n");
		var key:Bytes = Bytes.ofHex("2b7e151628aed2a6abf7158809cf4f3c");
		var iv:Bytes = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d8a571e03ac9c9eb76fac45af8e51" +
			"30c81c46a35ce411e5fbc1191a0a52ef" +
			"f69f2445df4f9b17ad2b417be66c3710");
		var ct:Bytes = Bytes.ofHex(
			"7649abac8119b246cee98e9b12e9197d" +
			"5086cb9b507219ee95db113a917678b2" +
			"73bed6b8e3c1743b7116e69e22229516" +
			"3ff1caa1681fac09120eca307586e1a7");


		aescbc(key, 128, iv, pt, ct);

		// Encryption vectors
		// Use "-debug -D CAFFEINE_DEBUG" to see engine traces

// 		Key 2b7e151628aed2a6abf7158809cf4f3c
// 		IV 000102030405060708090a0b0c0d0e0f
// 		Block #1
// 		Plaintext 6bc1bee22e409f96e93d7e117393172a
// 		Input Block 6bc0bce12a459991e134741a7f9e1925
// 		Output Block 7649abac8119b246cee98e9b12e9197d
// 		Ciphertext 7649abac8119b246cee98e9b12e9197d
// 
// 		Block #2
// 		Plaintext ae2d8a571e03ac9c9eb76fac45af8e51
// 		Input Block d86421fb9f1a1eda505ee1375746972c
// 		Output Block 5086cb9b507219ee95db113a917678b2
// 		Ciphertext 5086cb9b507219ee95db113a917678b2
// 
// 		Block #3
// 		Plaintext 30c81c46a35ce411e5fbc1191a0a52ef
// 		Input Block 604ed7ddf32efdff7020d0238b7c2a5d
// 		Output Block 73bed6b8e3c1743b7116e69e22229516
// 		Ciphertext 73bed6b8e3c1743b7116e69e22229516
// 
// 		Block #4
// 		Plaintext f69f2445df4f9b17ad2b417be66c3710
// 		Input Block 8521f2fd3c8eef2cdc3da7e5c44ea206
// 		Output Block 3ff1caa1681fac09120eca307586e1a7
// 		Ciphertext 3ff1caa1681fac09120eca307586e1a7

		// Decryption
		
// 		Key 2b7e151628aed2a6abf7158809cf4f3c
// 		IV 000102030405060708090a0b0c0d0e0f
// 		
// 		Block #1
// 		Ciphertext 7649abac8119b246cee98e9b12e9197d
// 		Input Block 7649abac8119b246cee98e9b12e9197d
// 		Output Block 6bc0bce12a459991e134741a7f9e1925
// 		Plaintext 6bc1bee22e409f96e93d7e117393172a
// 
// 		Block #2
// 		Ciphertext 5086cb9b507219ee95db113a917678b2
// 		Input Block 5086cb9b507219ee95db113a917678b2
// 		Output Block d86421fb9f1a1eda505ee1375746972c
// 		Plaintext ae2d8a571e03ac9c9eb76fac45af8e51
// 
// 		Block #3
// 		Ciphertext 73bed6b8e3c1743b7116e69e22229516
// 		Input Block 73bed6b8e3c1743b7116e69e22229516
// 		Output Block 604ed7ddf32efdff7020d0238b7c2a5d
// 		Plaintext 30c81c46a35ce411e5fbc1191a0a52ef
// 
// 		Block #4
// 		Ciphertext 3ff1caa1681fac09120eca307586e1a7
// 		Input Block 3ff1caa1681fac09120eca307586e1a7
// 		28
// 		Output Block 8521f2fd3c8eef2cdc3da7e5c44ea206
// 		Plaintext f69f2445df4f9b17ad2b417be66c3710
	}

	public function testCBC_AES192():Void {
		trace("\n============== CBC AES 192 ==========\n");
		var key:Bytes = Bytes.ofHex("8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b");
		var iv:Bytes = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d8a571e03ac9c9eb76fac45af8e51" +
			"30c81c46a35ce411e5fbc1191a0a52ef" +
			"f69f2445df4f9b17ad2b417be66c3710");
		var ct:Bytes = Bytes.ofHex(
			"4f021db243bc633d7178183a9fa071e8" +
			"b4d9ada9ad7dedf4e5e738763f69145a" +
			"571b242012fb7ae07fa9baac3df102e0" +
			"08b0e27988598881d920a9e64f5615cd");
		aescbc(key, 192, iv, pt, ct);
		assertTrue(true);
	}

	public function testCBC_AES256():Void {
		trace("\n============== CBC AES 256 ==========\n");
		var key:Bytes = Bytes.ofHex(
			"603deb1015ca71be2b73aef0857d7781" +
			"1f352c073b6108d72d9810a30914dff4");
		var iv = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d8a571e03ac9c9eb76fac45af8e51" +
			"30c81c46a35ce411e5fbc1191a0a52ef" +
			"f69f2445df4f9b17ad2b417be66c3710");
		var ct:Bytes = Bytes.ofHex(
			"f58c4c04d6e5f1ba779eabfb5f7bfbd6" +
			"9cfc4e967edb808d679f777bc6702c7d" +
			"39f23369a9d9bacfa530e26304231461" +
			"b2eb05e2c39be9fcda6c19078c6a9d1b");

		aescbc(key,256,iv,pt,ct);
	}

	public function testOFB_AES128() : Void {

		trace("\n============== OFB AES 128 ==========\n");
		var key:Bytes = Bytes.ofHex(
			"2b7e151628aed2a6abf7158809cf4f3c");
		var iv = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d8a571e03ac9c9eb76fac45af8e51" +
			"30c81c46a35ce411e5fbc1191a0a52ef" +
			"f69f2445df4f9b17ad2b417be66c3710");
		var ct:Bytes = Bytes.ofHex(
			"3b3fd92eb72dad20333449f8e83cfb4a" +
			"7789508d16918f03f53c52dac54ed825" +
			"9740051e9c5fecf64344f7a82260edcc" +
			"304c6528f659c77866a510d9c1d6ae5e");

		aesofb(key,128,iv,pt,ct);
			
// 		F.4.1 OFB-AES128.Encrypt
// 		Key 2b7e151628aed2a6abf7158809cf4f3c
// 		IV 000102030405060708090a0b0c0d0e0f
// 		Block #1
// 		Input Block 000102030405060708090a0b0c0d0e0f
// 		Output Block 50fe67cc996d32b6da0937e99bafec60
// 		Plaintext 6bc1bee22e409f96e93d7e117393172a
// 		Ciphertext 3b3fd92eb72dad20333449f8e83cfb4a
// 
// 		Block #2
// 		Input Block 50fe67cc996d32b6da0937e99bafec60
// 		53
// 		Output Block d9a4dada0892239f6b8b3d7680e15674
// 		Plaintext ae2d8a571e03ac9c9eb76fac45af8e51
// 		Ciphertext 7789508d16918f03f53c52dac54ed825
// 
// 		Block #3
// 		Input Block d9a4dada0892239f6b8b3d7680e15674
// 		Output Block a78819583f0308e7a6bf36b1386abf23
// 		Plaintext 30c81c46a35ce411e5fbc1191a0a52ef
// 		Ciphertext 9740051e9c5fecf64344f7a82260edcc
// 
// 		Block #4
// 		Input Block a78819583f0308e7a6bf36b1386abf23
// 		Output Block c6d3416d29165c6fcb8e51a227ba994e
// 		Plaintext f69f2445df4f9b17ad2b417be66c3710
// 		Ciphertext 304c6528f659c77866a510d9c1d6ae5e
// 
// 
// 		F.4.2 OFB-AES128.Decrypt
// 		Key 2b7e151628aed2a6abf7158809cf4f3c
// 		IV 000102030405060708090a0b0c0d0e0f
// 		Block #1
// 		Input Block 000102030405060708090a0b0c0d0e0f
// 		Output Block 50fe67cc996d32b6da0937e99bafec60
// 		Ciphertext 3b3fd92eb72dad20333449f8e83cfb4a
// 		Plaintext 6bc1bee22e409f96e93d7e117393172a
// 		Block #2
// 		Input Block 50fe67cc996d32b6da0937e99bafec60
// 		Output Block d9a4dada0892239f6b8b3d7680e15674
// 		Ciphertext 7789508d16918f03f53c52dac54ed825
// 		Plaintext ae2d8a571e03ac9c9eb76fac45af8e51
// 		Block #3
// 		Input Block d9a4dada0892239f6b8b3d7680e15674
// 		Output Block a78819583f0308e7a6bf36b1386abf23
// 		Ciphertext 9740051e9c5fecf64344f7a82260edcc
// 		Plaintext 30c81c46a35ce411e5fbc1191a0a52ef
// 		Block #4
// 		Input Block a78819583f0308e7a6bf36b1386abf23
// 		Output Block c6d3416d29165c6fcb8e51a227ba994e
// 		Ciphertext 304c6528f659c77866a510d9c1d6ae5e
// 		Plaintext f69f2445df4f9b17ad2b417be66c3710
	}


	public function testCFB8_AES128() : Void {

		trace("\n============== CFB8 AES 128 ==========\n");
		var key:Bytes = Bytes.ofHex(
			"2b7e151628aed2a6abf7158809cf4f3c");
		var iv = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d");
		var ct:Bytes = Bytes.ofHex(
			"3b79424c9c0dd436bace9e0ed4586a4f" +
			"32b9");

		// you'll have to read the vectors out of the pdf here... way too long
		aescfb8(key,128,iv,pt,ct);
	}


	public function testCFB_AES128() : Void {

		trace("\n============== CFB128 AES 128 ==========\n");
		var key:Bytes = Bytes.ofHex(
			"2b7e151628aed2a6abf7158809cf4f3c");
		var iv = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d8a571e03ac9c9eb76fac45af8e51" +
			"30c81c46a35ce411e5fbc1191a0a52ef" +
			"f69f2445df4f9b17ad2b417be66c3710");
		var ct:Bytes = Bytes.ofHex(
			"3b3fd92eb72dad20333449f8e83cfb4a" +
			"c8a64537a0b3a93fcde3cdad9f1ce58b" +
			"26751f67a3cbb140b1808cf187a4f4df" +
			"c04b05357c5d1c0eeac4c66f9ff7f2e6");

		aescfb(key,128,iv,pt,ct);
		
// 		Key 2b7e151628aed2a6abf7158809cf4f3c
// 		IV 000102030405060708090a0b0c0d0e0f
// 
// 		Segment #1
// 		Input Block 000102030405060708090a0b0c0d0e0f
// 		Output Block 50fe67cc996d32b6da0937e99bafec60
// 		Plaintext 6bc1bee22e409f96e93d7e117393172a
// 		Ciphertext 3b3fd92eb72dad20333449f8e83cfb4a
// 
// 		Segment #2
// 		Input Block 3b3fd92eb72dad20333449f8e83cfb4a
// 		Output Block 668bcf60beb005a35354a201dab36bda
// 		Plaintext ae2d8a571e03ac9c9eb76fac45af8e51
// 		Ciphertext c8a64537a0b3a93fcde3cdad9f1ce58b
// 
// 		Segment #3
// 		Input Block c8a64537a0b3a93fcde3cdad9f1ce58b
// 		Output Block 16bd032100975551547b4de89daea630
// 		Plaintext 30c81c46a35ce411e5fbc1191a0a52ef
// 		Ciphertext 26751f67a3cbb140b1808cf187a4f4df
// 
// 		Segment #4
// 		Input Block 26751f67a3cbb140b1808cf187a4f4df
// 		Output Block 36d42170a312871947ef8714799bc5f6
// 		Plaintext f69f2445df4f9b17ad2b417be66c3710
// 		Ciphertext c04b05357c5d1c0eeac4c66f9ff7f2e6


// 		Key 2b7e151628aed2a6abf7158809cf4f3c
// 		IV 000102030405060708090a0b0c0d0e0f
// 		
// 		Segment #1
// 		Input Block 000102030405060708090a0b0c0d0e0f
// 		Output Block 50fe67cc996d32b6da0937e99bafec60
// 		Ciphertext 3b3fd92eb72dad20333449f8e83cfb4a
// 		Plaintext 6bc1bee22e409f96e93d7e117393172a
// 
// 		Segment #2
// 		Input Block 3b3fd92eb72dad20333449f8e83cfb4a
// 		Output Block 668bcf60beb005a35354a201dab36bda
// 		Ciphertext c8a64537a0b3a93fcde3cdad9f1ce58b
// 		Plaintext ae2d8a571e03ac9c9eb76fac45af8e51
// 
// 		Segment #3
// 		Input Block c8a64537a0b3a93fcde3cdad9f1ce58b
// 		Output Block 16bd032100975551547b4de89daea630
// 		Ciphertext 26751f67a3cbb140b1808cf187a4f4df
// 		Plaintext 30c81c46a35ce411e5fbc1191a0a52ef
// 
// 		Segment #4
// 		Input Block 26751f67a3cbb140b1808cf187a4f4df
// 		Output Block 36d42170a312871947ef8714799bc5f6
// 		Ciphertext c04b05357c5d1c0eeac4c66f9ff7f2e6
// 		Plaintext f69f2445df4f9b17ad2b417be66c3710
	}


	function aesctr128(key:Bytes, bits:Int, iv:Bytes, pt:String, ct:String) : Cipher {
		return aes_common(key, bits, new CTR(), iv, Bytes.ofHex(pt), Bytes.ofHex(ct));
	}

	/**
	 * Section F.5
	 **/
	public function testCTR_AES128() : Void {

		trace("\n============== CTR AES 128 ==========\n");
		var key:Bytes = Bytes.ofHex(
			"2b7e151628aed2a6abf7158809cf4f3c");
		var iv = Bytes.ofHex("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff");

		var c = aesctr128(key,128,iv,"6bc1bee22e409f96e93d7e117393172a", "874d6191b620e3261bef6864990db6ce");
		c = aesctr128(key,128,c.getCurrentIV(),"ae2d8a571e03ac9c9eb76fac45af8e51","9806f66b7970fdff8617187bb9fffdff");
		
// 		Key 2b7e151628aed2a6abf7158809cf4f3c
// 		Init. Counter f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff
// 		
// 		Block #1
// 		Input Block f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff
// 		Output Block ec8cdf7398607cb0f2d21675ea9ea1e4
// 		Plaintext 6bc1bee22e409f96e93d7e117393172a
// 		Ciphertext 874d6191b620e3261bef6864990db6ce
// 		
// 		Block #2
// 		Input Block f0f1f2f3f4f5f6f7f8f9fafbfcfdff00
// 		Output Block 362b7c3c6773516318a077d7fc5073ae
// 		Plaintext ae2d8a571e03ac9c9eb76fac45af8e51
// 		Ciphertext 9806f66b7970fdff8617187bb9fffdff
// 		
// 		Block #3
// 		Input Block f0f1f2f3f4f5f6f7f8f9fafbfcfdff01
// 		Output Block 6a2cc3787889374fbeb4c81b17ba6c44
// 		Plaintext 30c81c46a35ce411e5fbc1191a0a52ef
// 		Ciphertext 5ae4df3edbd5d35e5b4f09020db03eab
// 		
// 		Block #4
// 		Input Block f0f1f2f3f4f5f6f7f8f9fafbfcfdff02
// 		Output Block e89c399ff0f198c6d40a31db156cabfe
// 		Plaintext f69f2445df4f9b17ad2b417be66c3710
// 		Ciphertext 1e031dda2fbe03d1792170a0f3009cee
	}

	public function testCTR_AES192() : Void {
		trace("\n============== CTR AES 192 ==========\n");
		var key:Bytes = Bytes.ofHex(
			"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b");
		var iv = Bytes.ofHex("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff");

		var c = aesctr128(key,192,iv,"6bc1bee22e409f96e93d7e117393172a", "1abc932417521ca24f2b0459fe7e6e0b");
		c = aesctr128(key,192,c.getCurrentIV(),"ae2d8a571e03ac9c9eb76fac45af8e51","090339ec0aa6faefd5ccc2c6f4ce8e94");

// 		Key 8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b
// 		Init. Counter f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff
// 		
// 		Block #1
// 		Input Block f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff
// 		Output Block 717d2dc639128334a6167a488ded7921
// 		Plaintext 6bc1bee22e409f96e93d7e117393172a
// 		Ciphertext 1abc932417521ca24f2b0459fe7e6e0b
// 		
// 		Block #2
// 		Input Block f0f1f2f3f4f5f6f7f8f9fafbfcfdff00
// 		Output Block a72eb3bb14a556734b7bad6ab16100c5
// 		Plaintext ae2d8a571e03ac9c9eb76fac45af8e51
// 		Ciphertext 090339ec0aa6faefd5ccc2c6f4ce8e94
// 		
// 		Block #3
// 		Input Block f0f1f2f3f4f5f6f7f8f9fafbfcfdff01
// 		Output Block 2efeae2d72b722613446dc7f4c2af918
// 		Plaintext 30c81c46a35ce411e5fbc1191a0a52ef
// 		Ciphertext 1e36b26bd1ebc670d1bd1d665620abf7
// 		
// 		Block #4
// 		Input Block f0f1f2f3f4f5f6f7f8f9fafbfcfdff02
// 		Output Block b9e783b30dd7924ff7bc9b97beaa8740
// 		Plaintext f69f2445df4f9b17ad2b417be66c3710
// 		Ciphertext 4f78a7f6d29809585a97daec58c6b050
	}



/*
 * This code below is old, as it does not use chx.crypt.Cipher
 * 
	// For now the main goal is to show we can decrypt what we encrypt in this mode.
	// Eventually, this should get correlated with some well known vectors.
	public function testAES():Void {
		var keys:Array<String> = [
		"00010203050607080A0B0C0D0F101112",
		"14151617191A1B1C1E1F202123242526"];
		var cts:Array<String> = [
		"D8F532538289EF7D06B506A4FD5BE9C94894C5508A8D8E29AB600DB0261F0555A8FA287B89E65C0973F1F8283E70C72863FE1C8F1F782084CE05626E961A67B3",
		"59AB30F4D4EE6E4FF9907EF65B1FB68C96890CE217689B1BE0C93ED51CF21BB5A0101A8C30714EC4F52DBC9C6F4126067D363F67ABE58463005E679B68F0B496"];
		var pts:Array<String> = [
		"506812A45F08C889B97F5980038B8359506812A45F08C889B97F5980038B8359506812A45F08C889B97F5980038B8359",
		"5C6D71CA30DE8B8B00549984D2EC7D4B5C6D71CA30DE8B8B00549984D2EC7D4B5C6D71CA30DE8B8B00549984D2EC7D4B"];

		for (i in 0...keys.length) {
			var key:Bytes = Bytes.ofHex(keys[i]);
			var pt:Bytes = Bytes.ofHex(pts[i]);
			var aes:Aes = new Aes(key.length*8, key);
			var cbc:ModeCBC = new ModeCBC(aes);
			cbc.iv = Bytes.ofHex("00000000000000000000000000000000");
			cbc.setPrependMode(false);
			var crypted = cbc.encrypt(pt);
			var str:String = crypted.toHex().toUpperCase();
			assertEquals( cts[i], str);
			// back to pt
			var dec = cbc.decrypt(crypted);
			str = dec.toHex().toUpperCase();
			assertEquals(pts[i], str);
		}
	}
	*/

	/*
	public function testXTea():Void {
		var keys:Array<String>=[
		"00000000000000000000000000000000",
		"2b02056806144976775d0e266c287843"];
		var cts:Array<String> = [
		"2dc7e8d3695b0538d8f1640d46dca717790af2ab545e11f3b08e798eb3f17b1744299d4d20b534aa",
		"790958213819878370eb8251ffdac371081c5a457fc42502c63910306fea150be8674c3b8e675516"];
		var pts:Array<String>=[
		"0000000000000000000000000000000000000000000000000000000000000000",
		"74657374206d652e74657374206d652e74657374206d652e74657374206d652e"];

		for (i in 0...keys.length) {
			var key:Bytes = Bytes.ofHex(keys[i]);
			var pt:Bytes = Bytes.ofHex(pts[i]);
			var tea:XTea = new XTea(key);
			var cbc:ModeCBC = new ModeCBC(tea);
			cbc.iv = Bytes.ofHex("0000000000000000");
			
			var str:String = cbc.encrypt(pt).toHex();
			assertEquals(cts[i], str);
			// now go back to plaintext.
			str = cbc.decrypt(Bytes.ofHex(str)).toHex();
			assertEquals(pts[i], str);
		}
	}
	*/
}