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
/*
 * Derived from javascript implementation Copyright (c) 2005 Tom Wu
 */

package chx.crypt.rsa;

import math.BigInteger;

/**
	Full RSA encryption class. For encryption only, the base class
	RSAEncrypt can be used instead.
**/
class RSA extends RSAEncrypt, implements IBlockCipher {
	public var d : BigInteger;		// private key
	public var p : BigInteger;		// prime 1
	public var q : BigInteger;		// prime 2
	public var dmp1 : BigInteger;	// d % (p-1)
	public var dmq1 : BigInteger;	// d % (q -1)
	public var coeff: BigInteger;

	public function new(nHex:String=null,eHex:String=null,dHex:String=null) {
		super(null,null);
		init();
		if(nHex != null)
			setPrivate(nHex,eHex,dHex);
	}

	override private function init() {
		super.init();
		this.d = null;		// private exponent
		this.p = null;		// prime 1
		this.q = null;		// prime 2
		this.dmp1 = null;	// d % (p-1)
		this.dmq1 = null;	// d % (q -1)
		this.coeff = null;
	}

	/**
	* Return the PKCS#1 RSA decryption of buf
	*
	* @param buf Bytes of any length
	**/
	public function decrypt( buf : Bytes ) : Bytes {
		return doBufferDecrypt(buf, doPrivate, new PadPkcs1Type2(blockSize));
	}

	/**
	* 
	**/
	override public function decryptBlock( enc : Bytes ) : Bytes {
		var c : BigInteger = BigInteger.ofBytes(enc, true);
		var m : BigInteger = doPrivate(c);
		if(m == null)
			throw "doPrivate error";

		// the encrypted block is a BigInteger, so any leading
		// 0's will have been truncated. Push them back in.
		var ba = m.toBytesUnsigned();
		if(ba.length < blockSize) {
			var b2 = Bytes.alloc(blockSize);
			for(i in 0...blockSize - ba.length + 1)
				b2.set(i, 0);
			b2.blit(blockSize - ba.length, ba, 0, ba.length);
			ba = b2;
		}
		else {
			while(ba.length > blockSize) {
				var cnt = ba.length - blockSize;
				for(i in 0...cnt)
					if(ba.get(i) != 0)
						throw "decryptBlock length error";
				ba = ba.sub(cnt, blockSize);
			}
		}
		return ba;
	}

	/**
	* Return the PKCS#1 RSA decryption of "text", which is any valid
	* hex string, optionally separated w with : or whitespace as
	* a separator character.
	*
	* @param hexString Hexadecimal string
	* @return Bytes of decrypted data
	**/
	public function decryptText( hexString : String ) : Bytes {
		return decrypt( BytesUtil.ofHex(BytesUtil.cleanHexFormat(hexString)) );
	}

	/**
	* Generate a new random private key B bits long, using public expt E.
	* Generating keys over 512 bits in neko, or 256 bit on other platforms
	* is just not practical. If you need large keys, generate them with
	* openssl and load them into RSA.<br />
	* <b>openssl genrsa -des3 -out user.key 1024</b><br />
	* <b>openssl genrsa -3 -out user.key 1024</b> no password, 3 as exponent<br />
	* will generate a 1024 bit key, which can be displayed with<br />
	* <b>openssl rsa -in user.key -noout -text</b>
	*
	* @param B Number of bits for key
	* @param E public exponent, a hexadecimal string
	*/
	public static function generate(B:Int, E:String) : RSA {
		var rng = new math.prng.Random();
		var key:RSA = new RSA();
		var qs : Int = B>>1;
		key.e = Std.parseInt(StringTools.startsWith(E, "0x") ? E : "0x" + E);
		var ee : BigInteger = BigInteger.ofInt(key.e);
		while(true) {
			key.p = BigInteger.randomPrime(B-qs, ee, 10, true, rng);
			key.q = BigInteger.randomPrime(qs, ee, 10, true, rng);
			if(key.p.compare(key.q) <= 0) {
				var t = key.p;
				key.p = key.q;
				key.q = t;
			}
			var p1:BigInteger = key.p.sub(BigInteger.ONE);
			var q1:BigInteger = key.q.sub(BigInteger.ONE);
			var phi:BigInteger = p1.mul(q1);
			if(phi.gcd(ee).compare(BigInteger.ONE) == 0) {
				key.n = key.p.mul(key.q);
				key.d = ee.modInverse(phi);
				key.dmp1 = key.d.mod(p1);
				key.dmq1 = key.d.mod(q1);
				key.coeff = key.q.modInverse(key.p);
				break;
			}
		}
		return key;
	}

	/**
	* Sign a certificate
	*
	* @param content buffer string
	**/
	public function sign( content : Bytes ) : Bytes {
		return doBufferEncrypt(content, doPrivate, new PadPkcs1Type1(blockSize));
	}

	/**
	* Set the private key fields N (modulus), E (public exponent)
	* and D (private exponent) from hex strings.
	*
	* @param N modulus, a hexadecimal string
	* @param E public exponent, a hexadecimal string
	* @param D private exponent, a hexadecimal string
	* @throws String on errors
	**/
	public function setPrivate(N:String,E:String,D:String) : Void {
		init();
		super.setPublic(N, E);
		if(D != null && D.length > 0) {
			var s = BytesUtil.cleanHexFormat(D);
			d = BigInteger.ofString(s, 16);
		}
		else
			throw("Invalid RSA private key");
	}

	/**
	* Set the private key fields N, E, D and CRT params from
	* hex strings.
	*
	* @param N modulus, a hexadecimal string
	* @param E public exponent, a hexadecimal string
	* @param D private exponent, a hexadecimal string
	* @param P prime1, a hexadecimal string
	* @param Q prime2, a hexadecimal string
	* @param DP d % (p-1), a hexadecimal string or null
	* @param DQ d % (q-1), a hexadecimal string or null
	* @param C coefficient, a hexadecimal string
	* @throws String on errors
	**/
	public function setPrivateEx(
			N:String,E:String,D:String,P:String,Q:String,
			DP:String=null,DQ:String=null,C:String=null) : Void
	{
		init();
		setPrivate(N, E, D);
		if(P != null && Q != null)
		{
			p = BigInteger.ofString(BytesUtil.cleanHexFormat(P), 16);
			q = BigInteger.ofString(BytesUtil.cleanHexFormat(Q), 16);

			dmp1 = null;
			dmq1 = null;
			coeff = null;

			if(DP != null)
				dmp1 = BigInteger.ofString(BytesUtil.cleanHexFormat(DP),16);

			if(DQ != null)
				dmq1 = BigInteger.ofString(BytesUtil.cleanHexFormat(DQ),16);

			if(C != null)
				coeff = BigInteger.ofString(BytesUtil.cleanHexFormat(C), 16);

			recalcCRT();
		}
		else
			throw("Invalid RSA private key ex");
	}

	function recalcCRT() {
		if(p != null && q != null) {
			if(dmp1 == null)
				dmp1 = d.mod(p.sub(BigInteger.ONE));
			if(dmq1 == null)
				dmq1 = d.mod(q.sub(BigInteger.ONE));
			if(coeff == null)
				coeff = q.modInverse(p);
		}
	}

	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
	/**
		Perform raw private operation on "x": return x^d (mod n)
	**/
	function doPrivate( x:BigInteger ) : BigInteger {
		if(this.p == null || this.q == null) {
			return x.modPow(this.d, this.n);
		}

		var xp = x.mod(this.p).modPow(this.dmp1, this.p);
		var xq = x.mod(this.q).modPow(this.dmq1, this.q);

		while(xp.compare(xq) < 0)
			xp = xp.add(this.p);
		return xp.sub(xq).mul(this.coeff).mod(this.p).mul(this.q).add(xq);
	}

	/*
	override public function toString() {
		var sb = new StringBuf();
		sb.add(super.toString());
		sb.add("Private:\n");
		sb.add("D:\t" + d.toHex() + "\n");
		if(p != null) sb.add("P:\t" + p.toHex() + "\n");
		if(q != null) sb.add("Q:\t" + q.toHex() + "\n");
		if(dmp1 != null) sb.add("DMP1:\t" + dmp1.toHex() + "\n");
		if(dmq1 != null) sb.add("DMQ1:\t" + dmq1.toHex() + "\n");
		if(coeff != null) sb.add("COEFF:\t" + coeff.toHex() + "\n");
		return sb.toString();
	}
	*/
}

