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

package chx.hash;

class Md2 implements IHash {

	public function new() {
	}

	public function dispose() : Void {
		for(i in 0...16) {
			data[i] = 0;
			checksum[i] = 0;
			state[i] = 0;
		}
	}

	public function toString() : String {
		return "md2";
	}

	public function calculate( msg:Bytes ) : Bytes {
		init();
		update(msg);
		return(final());
	}

	public function calcHex( msg:Bytes ) : String {
		return encode(msg).toHex();
	}

	public function getLengthBytes() : Int {
		return 16;
	}

	public function getLengthBits() : Int {
		return 128;
	}

	public function getBlockSizeBytes() : Int {
		return 16;
	}

	public function getBlockSizeBits() : Int {
		return 128;
	}

	public static function encode(msg : Bytes) : Bytes {
		var m = new Md2();
		m.init();
		m.update(msg);
		return m.final();
	}

	static var K : Array<Int> = function() {
		var S1: Array<Int> = [
			0x29, 0x2E, 0x43, 0xC9, 0xA2, 0xD8, 0x7C, 0x01,
			0x3D, 0x36, 0x54, 0xA1, 0xEC, 0xF0, 0x06, 0x13,
			0x62, 0xA7, 0x05, 0xF3, 0xC0, 0xC7, 0x73, 0x8C,
			0x98, 0x93, 0x2B, 0xD9, 0xBC, 0x4C, 0x82, 0xCA,
			0x1E, 0x9B, 0x57, 0x3C, 0xFD, 0xD4, 0xE0, 0x16,
			0x67, 0x42, 0x6F, 0x18, 0x8A, 0x17, 0xE5, 0x12,
			0xBE, 0x4E, 0xC4, 0xD6, 0xDA, 0x9E, 0xDE, 0x49,
			0xA0, 0xFB, 0xF5, 0x8E, 0xBB, 0x2F, 0xEE, 0x7A,
			0xA9, 0x68, 0x79, 0x91, 0x15, 0xB2, 0x07, 0x3F
		];
		var S2: Array<Int> = [
			0x94, 0xC2, 0x10, 0x89, 0x0B, 0x22, 0x5F, 0x21,
			0x80, 0x7F, 0x5D, 0x9A, 0x5A, 0x90, 0x32, 0x27,
			0x35, 0x3E, 0xCC, 0xE7, 0xBF, 0xF7, 0x97, 0x03,
			0xFF, 0x19, 0x30, 0xB3, 0x48, 0xA5, 0xB5, 0xD1,
			0xD7, 0x5E, 0x92, 0x2A, 0xAC, 0x56, 0xAA, 0xC6,
			0x4F, 0xB8, 0x38, 0xD2, 0x96, 0xA4, 0x7D, 0xB6,
			0x76, 0xFC, 0x6B, 0xE2, 0x9C, 0x74, 0x04, 0xF1,
			0x45, 0x9D, 0x70, 0x59, 0x64, 0x71, 0x87, 0x20
		];
		var S3: Array<Int> = [
			0x86, 0x5B, 0xCF, 0x65, 0xE6, 0x2D, 0xA8, 0x02,
			0x1B, 0x60, 0x25, 0xAD, 0xAE, 0xB0, 0xB9, 0xF6,
			0x1C, 0x46, 0x61, 0x69, 0x34, 0x40, 0x7E, 0x0F,
			0x55, 0x47, 0xA3, 0x23, 0xDD, 0x51, 0xAF, 0x3A,
			0xC3, 0x5C, 0xF9, 0xCE, 0xBA, 0xC5, 0xEA, 0x26,
			0x2C, 0x53, 0x0D, 0x6E, 0x85, 0x28, 0x84, 0x09,
			0xD3, 0xDF, 0xCD, 0xF4, 0x41, 0x81, 0x4D, 0x52,
			0x6A, 0xDC, 0x37, 0xC8, 0x6C, 0xC1, 0xAB, 0xFA
		];
		var S4: Array<Int> = [
			0x24, 0xE1, 0x7B, 0x08, 0x0C, 0xBD, 0xB1, 0x4A,
			0x78, 0x88, 0x95, 0x8B, 0xE3, 0x63, 0xE8, 0x6D,
			0xE9, 0xCB, 0xD5, 0xFE, 0x3B, 0x00, 0x1D, 0x39,
			0xF2, 0xEF, 0xB7, 0x0E, 0x66, 0x58, 0xD0, 0xE4,
			0xA6, 0x77, 0x72, 0xF8, 0xEB, 0x75, 0x4B, 0x0A,
			0x31, 0x44, 0x50, 0xB4, 0x8F, 0xED, 0x1F, 0x1A,
			0xDB, 0x99, 0x8D, 0x33, 0x9F, 0x11, 0x83, 0x14
		];
		return S1.concat(S2).concat(S3).concat(S4);
	}();

	private var num : Int;
	private var data : Array<Int>;
	private var checksum : Array<Int>;
	private var state : Array<Int>;

	private function init() {
		num = 0;
		data = new Array();
		checksum = new Array();
		state = new Array();

		for(i in 0...16) {
			data[i] = 0;
			checksum[i] = 0;
			state[i] = 0;
		}
	}

	private function update(s:Bytes) {
		var l = s.length;
		if(l == 0) return;

		var db:Array<Int> = [];
		var c:Int = 0;
		while (c < s.length)	db.push( s.get(c++) );

		if(num != 0) {
			if(num + l >= 16) {
				data = data.concat(db.splice(0,16-num));// + s.substr(0, 16-num);
				doBlock(data);
				l = db.length;
			}
			else {
				data = data.concat(db);
				num += l;
				return;
			}
		}
		while( l >= 16 ) {
			doBlock(db.splice(0,16));
			l -= 16;
		}
		num = l;
		data = db.slice(0,l);
	}

	private function doBlock(s : Array<Int>) {
		if(s.length != 16)
			throw "length "+s.length + " incorrect";
		var s2 = new Array<Int>();
		var t : Int = 0;
		var j : Int = checksum[16-1];
		for(i in 0...16) {
			s2[i] = state[i];
			t = s[i];
			s2[i+16] = t;
			s2[i+32] = (t^state[i]);
			checksum[i] = checksum[i] ^ K[t^j];
			j = checksum[i];
		}
		t = 0;
		for(i in 0...18) {
			j = 0;
			while(j < 48) {
				s2[j]^=K[t]; t= s2[j];
				s2[j+1]^=K[t]; t= s2[j+1];
				s2[j+2]^=K[t]; t= s2[j+2];
				s2[j+3]^=K[t]; t= s2[j+3];
				s2[j+4]^=K[t]; t= s2[j+4];
				s2[j+5]^=K[t]; t= s2[j+5];
				s2[j+6]^=K[t]; t= s2[j+6];
				s2[j+7]^=K[t]; t= s2[j+7];
				j += 8;
			}
			t = (t+i)&0xff;
		}
		state = s2;
	}

	private function final() : Bytes {
		var v : Int = 16 - num;
		for(i in num...16) data[i] = v;
		doBlock(data);

		var sb = new Array<Int>();
		for(i in 0...16) {
			sb[i] = checksum[i];
		}
		doBlock(sb);

		var bs = Bytes.alloc(16);
		for(i in 0...16)
			bs.set(i,state[i] & 0xff);
		//bs.position = 0;
		return bs;
	}
}
