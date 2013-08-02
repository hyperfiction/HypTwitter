/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package chx.crypt.rsa;

import math.BigInteger;
import math.prng.Random;

/**
	RSAEncrypt encrypts using a provided public key. If decryption is
	required, use the derived class RSADecrypt which can encypt and decrypt.
**/
class RSAEncrypt implements IBlockCipher {
	// public key
	/** modulus **/
	public var n(get_n,set_n) : BigInteger;
	/** exponent. <2^31 **/
	public var e(get_e,set_e) : Int;
	public var blockSize(__getBlockSize,null) : Int;
	public var blockPad(getBlockPad,setBlockPad) : IBlockPad;
	#if useOpenSSL
	var handle:Dynamic;
	var iBlockPad : Int;
	#end
	
	public function new(nHex:String=null,eHex:String=null) {
		init();
		if(nHex != null)
			setPublic(nHex, eHex);
	}

	private function init() {
		#if useOpenSSL
		if(handle == null)
			handle = rsa_new();
		#end
		this.n = null;
		this.e = 0;
	}

	public function getBlockPad() : IBlockPad {
		return this.blockPad;
	}

	public function setBlockPad(v:IBlockPad) : IBlockPad {
		this.blockPad = v;
		return v;
	}

	function get_n() : BigInteger {
		#if useOpenSSL
		return BigInteger.hndToBigInt(rsa_get_n(handle));
		#else
		return this.n;
		#end
	}
	function set_n(v:BigInteger) : BigInteger {
		#if useOpenSSL
		rsa_set_n(handle, BigInteger.bigIntToHnd(v));
		#end
		this.n = v;
		return v;
	}
	function get_e() : Int {
		#if useOpenSSL
		return BigInteger.hndToBigInt(rsa_get_e(handle)).toInt();
		#else
		return this.e;
		#end
	}	
	function set_e(v:Int) : Int {
		#if useOpenSSL
		rsa_set_e(handle, BigInteger.bigIntToHnd(BigInteger.ofInt(v)));
		#end
		this.e = v;
		return v;
	}

	/**
	* Decrypts a pre-padded buffer.
	*
	* @param block Block of encrypted data that must be exactly blockSize long
	* @return blockSize buffer with decrypted data.
	**/
	public function decryptBlock( enc : Bytes ) : Bytes {
		throw new chx.lang.UnsupportedException("Not a private key");
		return null;
	}

	/**
	* Return the PKCS#1 RSA encryption of [buf]
	*
	* @param buf plaintext buffer
	* TODO: Return Binary string, not text. Use padding etc...
	**/
	public function encrypt( buf : Bytes ) : Bytes {
		#if useOpenSSL
		var bd = rsa_public_encrypt(handle,RSA_PKCS1_PADDING(),buf,0,buf.length);
		return Bytes.ofData(bd);
		#else
		return doBufferEncrypt(buf, doPublic, new PadPkcs1Type2(blockSize));
		#end
	}

	/**
	* Encrypt a pre-padded buffer.
	*
	* @param block Block of plaintext that must be exactly blockSize long
	* @return blockSize buffer with crypted data.
	**/
	public function encryptBlock( block : Bytes ) : Bytes {
		var bsize : Int = blockSize;
		if(block.length != bsize)
			throw("bad block size");

		#if useOpenSSL
		var bd = rsa_public_encrypt(handle,RSA_NO_PADDING(),untyped block.getData(),0,block.length);
		return Bytes.ofData(bd);
		#else
		var biv:BigInteger = BigInteger.ofBytes(block, true);
		var biRes = doPublic(biv).toBytesUnsigned();

		var l = biRes.length;
		var i = 0;
		while(l > bsize) {
			if(biRes.get(i) != 0) {
				throw new chx.lang.FatalException("encoded length was "+biRes.length);
			}
			i++; l--;
		}
		if(i != 0) {
			biRes = biRes.sub(i, l);
		}

		if(biRes.length < bsize) {
			var bb = new BytesBuffer();
			l = bsize - biRes.length;
			for(i in 0...l)
				bb.addByte(0);
			bb.addBytes(biRes, 0, biRes.length);
			biRes = bb.getBytes();
		}
		return biRes;
		#end
	}

	/**
	* Return the PKCS#1 RSA encryption of "text" as an hex string, with [:] as
	* a separator character.
	*
	* @param text Text to encrypt.
	* @param separator character to put between hex values in output
	**/
	public function encyptText( text : String, separator:String = ":") : String {
		return BytesUtil.toHex(
				encrypt( Bytes.ofString(text) ),
				":");
	}

	/**
	* Set the public key fields N (modulus) and E (public exponent)
	* from hex strings.
	* @throw chx.lang.NullPointerException null argument
	* @throw chx.lang.IllegalArgumentError unparsable argument
	**/
	public function setPublic(nHex : String, eHex:String) : Void {
		init();
		if(nHex == null || nHex.length == 0)
			throw new chx.lang.NullPointerException("nHex not set: " + nHex);
		if(eHex == null || eHex.length == 0)
			throw new chx.lang.NullPointerException("eHex not set: " + eHex);

		var s : String = BytesUtil.cleanHexFormat(nHex);
		n = BigInteger.ofString(s, 16);
		if(n == null)
			throw new chx.lang.IllegalArgumentException("nHex not a valid big integer: "+nHex);
		var ie : Null<Int> = Std.parseInt("0x" +  BytesUtil.cleanHexFormat(eHex));
		if(ie == null || ie == 0)
			throw new chx.lang.IllegalArgumentException("eHex not a vlaid big integer: "+eHex);
		e = ie;
	}

	/**
	* Verify a signature
	* @todo verify implementation
	**/
	public function verify( data : Bytes ) : Bytes {
		return doBufferDecrypt(data, doPublic, new PadPkcs1Type1(blockSize));
	}


	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
	/**
	* Encrypts a bytes buffer
	*
	* @param src Input bytes
	* @param f Callback for encryption
	* @param pf Padding method
	**/
	private function doBufferEncrypt(src:Bytes, f : BigInteger->BigInteger, pf : IBlockPad) : Bytes
	{
		var bs = blockSize;
		var ts : Int = bs - 11;
		var idx : Int = 0;
		var msg = new BytesBuffer();
		while(idx < src.length) {
			if(idx + ts > src.length)
				ts = src.length - idx;
			var m:BigInteger = BigInteger.ofBytes(pf.pad(src.sub(idx,ts)), true);
			var c:BigInteger = f(m);

			var h = c.toBytesUnsigned();
			if((h.length & 1) != 0)
				msg.addByte( 0 );

			msg.add(h);
			idx += ts;
		}
		return msg.getBytes();
	}

	private function doBufferDecrypt(src: Bytes, f : BigInteger->BigInteger, pf : IBlockPad) : Bytes
	{
		var bs = blockSize;
		var ts : Int = bs - 11;
		var idx : Int = 0;
		var msg = new BytesBuffer();
		while(idx < src.length) {
			if(idx + bs > src.length)
				bs = src.length - idx;
			var c : BigInteger = BigInteger.ofBytes(src.sub(idx,bs), true);
			var m = f(c);
			if(m == null)
				return null;
			var up : Bytes = pf.unpad(m.toBytesUnsigned());
			if(up.length > ts)
				throw "block text length error";
			msg.add(up);
			idx += bs;
		}
		return msg.getBytes();
	}

	// Perform raw public operation on "x": return x^e (mod n)
	function doPublic(x : BigInteger) : BigInteger {
		return x.modPowInt(this.e, this.n);
	}

	//////////////////////////////////////////////////
	//             getters/setters                  //
	//////////////////////////////////////////////////
	function __getBlockSize() : Int {
		#if useOpenSSL
		return rsa_size(handle);
		#else
		if(n == null)
			return 0;
		return (n.bitLength()+7)>>3;
		#end
	}

	//////////////////////////////////////////////////
	//               Convenience                    //
	//////////////////////////////////////////////////


	public function toString() {
		return "rsa";
		/*
		var sb = new StringBuf();
		sb.add("Public:\n");
		sb.add("N:\t" + n.toHex() + "\n");
		sb.add("E:\t" + BigInteger.ofInt(e).toHex() + "\n");
		return sb.toString();
		*/
	}

	#if useOpenSSL
	public static function __init__()
	{
		chx.Lib.initDll("openssl");
	}

	private static var rsa_new = chx.Lib.load("openssl","rsa_new",0);
	private static var rsa_size = chx.Lib.load("openssl","rsa_size",1);
	private static var rsa_set_n = chx.Lib.load("openssl","rsa_set_n",2);
	private static var rsa_set_e = chx.Lib.load("openssl","rsa_set_e",2);
	private static var rsa_get_n = chx.Lib.load("openssl","rsa_get_n",1);
	private static var rsa_get_e = chx.Lib.load("openssl","rsa_get_e",1);

	private static var rsa_public_encrypt = chx.Lib.load("openssl","rsa_public_encrypt",5);
	
	private static var RSA_PKCS1_PADDING = chx.Lib.load("openssl","_RSA_PKCS1_PADDING",0);
	private static var RSA_PKCS1_OAEP_PADDING = chx.Lib.load("openssl","_RSA_PKCS1_OAEP_PADDING",0);
	private static var RSA_SSLV23_PADDING = chx.Lib.load("openssl","_RSA_SSLV23_PADDING",0);
	private static var RSA_NO_PADDING = chx.Lib.load("openssl","_RSA_NO_PADDING",0);

	#end
}

