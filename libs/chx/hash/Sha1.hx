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
 * Haxe code platforms adapted from SHA1 Javascript implementation
 * adapted from code covered by the LGPL © 2002-2005 Chris Veness,
 * http://www.movable-type.co.uk/scripts/sha1.html
 *
 * Alternative BSD implementation: http://pajhome.org.uk/crypt/md5/sha1src.html
*/

package chx.hash;

#if !(neko || useOpenSSL)
import BytesUtil;
import I32;
#end

class Sha1 implements IHash {

	/**
	 * Length of Sha1 hashes
	 **/
	public static inline var BYTES : Int = 20;

#if !(neko || useOpenSSL)
	static var K : Array<Int> = [0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xca62c1d6];
#end

	public function new() {
#if (neko || useOpenSSL)
		init();
#end
	}

	public function dispose() : Void {
		#if !(neko || useOpenSSL)
			for(i in 0...4)
				K[i] = 0;
		#end
	}

	public function toString() : String {
		return "sha1";
	}

	public function calculate( msg:Bytes ) : Bytes {
		return encode(msg);
	}

	public function calcHex( msg:Bytes ) : String {
		return encode(msg).toHex();
	}

	public function getLengthBytes() : Int {
		return 20;
	}

	public function getLengthBits() : Int {
		return 160;
	}

	public function getBlockSizeBytes() : Int {
		return 64;
	}

	public function getBlockSizeBits() : Int {
		return 512;
	}

#if (neko || useOpenSSL)
	var _ctx : Dynamic;
	public var value(default, null) : String;

	/**
		Prepare a streaming sha calculation
	**/
	public function init() {
		_ctx = sha_init(1);
		value = "";
	}

	/**
		Add data to the sha calculation
	**/
	public function update(s : String) {
		sha_update(_ctx, #if neko untyped s.__s #else s #end);
	}

	/**
		Finalize. Sets member var value to final sha, and returns the same value.
	**/
	public function final(?binary : Bool) {
		value = new String(sha_final(_ctx));
		if(!binary)
			value = math.BaseCode.encode(value, Constants.DIGITS_HEXL);
		return value;
	}

	/**
		Encode any dynamic value, classes, objects etc.
	**/
	public static function objEncode( o : Dynamic, ?binary : Bool ) : String {
		var m : String;
		if(Std.is(o, String))
			m = Bytes.ofData(nsha1(#if neko untyped o.__s #else o #end)).toString();
		else
			m = Bytes.ofData(nsha1(o)).toString();
		if(!binary)
			m = math.BaseCode.encode(m, Constants.DIGITS_HEXL);
		return m;
	}
#end
	/**
		Calculate the Sha1 for a string.
	**/
	public static function encode(msg : Bytes) : Bytes {
#if (neko || useOpenSSL)
		return Bytes.ofData(nsha1(msg.getData()));
#else
		//
		// function 'f' [§4.1.1]
		//
		var f = function(s, x, y, z)
		{
			switch (s) {
			case 0: return (x & y) ^ (~x & z);           // Ch()
			case 1: return x ^ y ^ z;                    // Parity()
			case 2: return (x & y) ^ (x & z) ^ (y & z);  // Maj()
			case 3: return x ^ y ^ z;                    // Parity()
			default: throw "err";
			}
			return 0;
		}

		//
		// rotate left (circular left shift) value x by n positions [§3.2.5]
		//
		var ROTL = function(x, n) {
			return (x<<n) | (x>>>(32-n));
		}

		//msg += BytesUtil.ofHex('0x80').toString(); // add trailing '1' bit to string [§5.1.1]
		var bb = new BytesBuffer();
		bb.add(msg);
		bb.addByte(0x80);
		msg = bb.getBytes();

		// convert string msg into 512-bit/16-integer blocks arrays of ints [§5.2.1]
		var l : Int = Math.ceil(msg.length/4) + 2;  // long enough to contain msg plus 2-word length
		var N : Int = Math.ceil(l/16);              // in N 16-int blocks
		var M : Array<Array<Int>> = new Array();
		for(i in 0...N) {
			M[i] = new Array<Int>();
			for(j in 0...16) { // encode 4 chars per integer, big-endian encoding
				M[i][j] = (msg.get(i*64+j*4)<<24) | (msg.get(i*64+j*4+1)<<16) |
					(msg.get(i*64+j*4+2)<<8) | (msg.get(i*64+j*4+3));
			}
		}

		// add length (in bits) into final pair of 32-bit integers (big-endian) [5.1.1]
		// note: most significant word would be ((len-1)*8 >>> 32, but since JS converts
		// bitwise-op args to 32 bits, we need to simulate this by arithmetic operators
		M[N-1][14] = Math.floor( ((msg.length-1)*8) / Math.pow(2, 32) );
		//M[N-1][14] = Math.floor(M[N-1][14]);
		M[N-1][15] = ((msg.length-1)*8) & 0xffffffff;

		// set initial hash value [§5.3.1]
		var H0 = 0x67452301;
		var H1 = 0xefcdab89;
		var H2 = 0x98badcfe;
		var H3 = 0x10325476;
		var H4 = 0xc3d2e1f0;

		// HASH COMPUTATION [§6.1.2]
		var W = new Array<Int>();
		var a, b, c, d, e;
		for(i in 0...N) {
			// 1 - prepare message schedule 'W'
			for(t in 0...16)
				W[t] = M[i][t];
			for(t in 16...80)
				W[t] = ROTL(W[t-3] ^ W[t-8] ^ W[t-14] ^ W[t-16], 1);

			// 2 - initialise five working variables a, b, c, d, e with previous hash value
			a = H0; b = H1; c = H2; d = H3; e = H4;

			// 3 - main loop
			for(t in 0...80) {
				// seq for blocks of 'f' functions and 'K' constants
				var s = Math.floor(t/20);
				var T = (ROTL(a,5) + f(s,b,c,d) + e + K[s] + W[t]) & 0xffffffff;
				e = d;
				d = c;
				c = ROTL(b, 30);
				b = a;
				a = T;
			}

			// 4 - compute the new intermediate hash value
			H0 = (H0+a) & 0xffffffff;  // note 'addition modulo 2^32'
			H1 = (H1+b) & 0xffffffff;
			H2 = (H2+c) & 0xffffffff;
			H3 = (H3+d) & 0xffffffff;
			H4 = (H4+e) & 0xffffffff;
    	}

		bb = new BytesBuffer();
		bb.add(I32.encodeBE(cast H0));
		bb.add(I32.encodeBE(cast H1));
		bb.add(I32.encodeBE(cast H2));
		bb.add(I32.encodeBE(cast H3));
		bb.add(I32.encodeBE(cast H4));
		return bb.getBytes();
#end
	}

#if (neko || useOpenSSL)
        private static var nsha1 = chx.Lib.load("hash","nsha1",1);
		private static var sha_init = chx.Lib.load("hash","sha_init",1);
		private static var sha_update = chx.Lib.load("hash","sha_update",2);
		private static var sha_final = chx.Lib.load("hash","sha_final",1);
#end
}
