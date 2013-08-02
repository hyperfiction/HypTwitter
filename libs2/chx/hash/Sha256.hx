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
 * Adapted from:
 * A JavaScript implementation of the Secure Hash Algorithm, SHA-256
 * Version 0.3 Copyright Angel Marin 2003-2004 - http://anmar.eu.org/
 * http://anmar.eu.org/projects/jssha2/
 * Distributed under the BSD License
 * Some bits taken from Paul Johnston's SHA-1 implementation
 */

package chx.hash;

import BytesUtil;
import I32;

class Sha256 implements IHash {
	/**
	 * Length of Sha256 hashes
	 **/
	public static inline var BYTES : Int = 32;

	public function new() {
	}

	public function toString() : String {
		return "sha256";
	}

	public function calculate( msg:Bytes ) : Bytes {
		return encode(msg);
	}

	public function calcHex( msg:Bytes ) : String {
		return encode(msg).toHex();
	}

	public function getLengthBytes() : Int {
		return 32;
	}

	public function getLengthBits() : Int {
		return 256;
	}

	public function getBlockSizeBytes() : Int {
		return 64;
	}

	public function getBlockSizeBits() : Int {
		return 512;
	}

	public function dispose() : Void {
		#if !(neko || useOpenSSL)
		#end
	}

#if !(neko || useOpenSSL)
	private static var charSize : Int = 8;
	public static function encode(s : Bytes) : Bytes {
		var pb : Array<Int> = cast I32.unpackBE(BytesUtil.nullPad(s,4));
		var res = core_sha256(pb, s.length * charSize);
		return I32.packBE(cast res);
	}

	static inline function S (X, n) {return ( X >>> n ) | (X << (32 - n));}
	static inline function R (X, n) {return ( X >>> n );}
	static inline function Ch(x, y, z) {return ((x & y) ^ ((~x) & z));}
	static inline function Maj(x, y, z) {return ((x & y) ^ (x & z) ^ (y & z));}
	static inline function Sigma0256(x) {return (S(x, 2) ^ S(x, 13) ^ S(x, 22));}
	static inline function Sigma1256(x) {return (S(x, 6) ^ S(x, 11) ^ S(x, 25));}
	static inline function Gamma0256(x) {return (S(x, 7) ^ S(x, 18) ^ R(x, 3));}
	static inline function Gamma1256(x) {return (S(x, 17) ^ S(x, 19) ^ R(x, 10));}
	static function core_sha256 (m, l) {
		var K : Array<Int> = [
			0x428A2F98,0x71374491,0xB5C0FBCF,0xE9B5DBA5,0x3956C25B,
			0x59F111F1,0x923F82A4,0xAB1C5ED5,0xD807AA98,0x12835B01,
			0x243185BE,0x550C7DC3,0x72BE5D74,0x80DEB1FE,0x9BDC06A7,
			0xC19BF174,0xE49B69C1,0xEFBE4786,0xFC19DC6,0x240CA1CC,
			0x2DE92C6F,0x4A7484AA,0x5CB0A9DC,0x76F988DA,0x983E5152,
			0xA831C66D,0xB00327C8,0xBF597FC7,0xC6E00BF3,0xD5A79147,
			0x6CA6351,0x14292967,0x27B70A85,0x2E1B2138,0x4D2C6DFC,
			0x53380D13,0x650A7354,0x766A0ABB,0x81C2C92E,0x92722C85,
			0xA2BFE8A1,0xA81A664B,0xC24B8B70,0xC76C51A3,0xD192E819,
			0xD6990624,0xF40E3585,0x106AA070,0x19A4C116,0x1E376C08,
			0x2748774C,0x34B0BCB5,0x391C0CB3,0x4ED8AA4A,0x5B9CCA4F,
			0x682E6FF3,0x748F82EE,0x78A5636F,0x84C87814,0x8CC70208,
			0x90BEFFFA,0xA4506CEB,0xBEF9A3F7,0xC67178F2
		];
		var HASH : Array<Int> = [
			0x6A09E667,0xBB67AE85,0x3C6EF372,0xA54FF53A,
			0x510E527F,0x9B05688C,0x1F83D9AB,0x5BE0CD19
		];

		var W = new Array<Int>();
		W[64] = 0;
		var a:Int,b:Int,c:Int,d:Int,e:Int,f:Int,g:Int,h:Int;
		var T1, T2;
		/* append padding */
		m[l >> 5] |= 0x80 << (24 - l % 32);
		m[((l + 64 >> 9) << 4) + 15] = l;
		var i : Int = 0;
		while ( i < m.length ) {
			a = HASH[0]; b = HASH[1]; c = HASH[2]; d = HASH[3]; e = HASH[4]; f = HASH[5]; g = HASH[6]; h = HASH[7];
			for ( j in 0...64 ) {
				if (j < 16)
					W[j] = m[j + i];
				else
					W[j] = Util.safeAdd(Util.safeAdd(Util.safeAdd(Gamma1256(W[j - 2]), W[j - 7]), Gamma0256(W[j - 15])), W[j - 16]);
				T1 = Util.safeAdd(Util.safeAdd(Util.safeAdd(Util.safeAdd(h, Sigma1256(e)), Ch(e, f, g)), K[j]), W[j]);
				T2 = Util.safeAdd(Sigma0256(a), Maj(a, b, c));
				h = g; g = f; f = e; e = Util.safeAdd(d, T1); d = c; c = b; b = a; a = Util.safeAdd(T1, T2);
			}
			HASH[0] = Util.safeAdd(a, HASH[0]);
			HASH[1] = Util.safeAdd(b, HASH[1]);
			HASH[2] = Util.safeAdd(c, HASH[2]);
			HASH[3] = Util.safeAdd(d, HASH[3]);
			HASH[4] = Util.safeAdd(e, HASH[4]);
			HASH[5] = Util.safeAdd(f, HASH[5]);
			HASH[6] = Util.safeAdd(g, HASH[6]);
			HASH[7] = Util.safeAdd(h, HASH[7]);
			i += 16;
		}
		return HASH;
	}
#else
	public static function encode(s : Bytes) : Bytes {
		var _ctx : Void = sha_init(256);
		sha_update(_ctx, s.getData());
		return Bytes.ofData(sha_final(_ctx));
	}

	private static var sha_init = chx.Lib.load("hash","sha_init",1);
	private static var sha_update = chx.Lib.load("hash","sha_update",2);
	private static var sha_final = chx.Lib.load("hash","sha_final",1);
#end

}
