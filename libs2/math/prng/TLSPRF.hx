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
 * Derived from actionscript implementation Copyright (c) 2007 Henri Torgemane
 */

package math.prng;

import chx.hash.HMAC;
import chx.hash.Md5;
import chx.hash.Sha1;

/**
* TLS (pseudo) Random.
*/
class TLSPRF implements IPrng
{
	public var size(default,null) : Int;

	// seed
	private var seed:Bytes;
	// P_MD5's secret
	private var s1:Bytes;
	// P_SHA-1's secret
	private var s2:Bytes;
	// HMAC_MD5's A
	private var a1:Bytes;
	// HMAC_SHA1's A
	private var a2:Bytes;
	// Pool for P_MD5
	private var p1:Array<Int>;
	// Pool for P_SHA1
	private var p2:Array<Int>;
	// Data for HMAC_MD5
	private var d1:Bytes;
	// Data for HMAC_SHA1
	private var d2:Bytes;

	private var hmac_md5:HMAC;
	private var hmac_sha1:HMAC;

	public function new(secret:Bytes, label:String, seed:Bytes) {
		var l:Int = Math.ceil(secret.length/2);
		s1 = Bytes.alloc(l);
		s1.blit(0, secret, 0, l);
		s2 = Bytes.alloc(l);	
		s2.blit(0, secret, secret.length-l, l);

		var bb = new BytesBuffer();
		bb.add(Bytes.ofString(label));
		bb.add(seed);
		this.seed = bb.getBytes();

		hmac_md5 = new HMAC(new Md5());
		hmac_sha1 = new HMAC(new Sha1());

		this.a1 = hmac_md5.calculate(s1, this.seed);
		this.a2 = hmac_sha1.calculate(s2, this.seed);

		p1 = new Array();
		p2 = new Array();

		d1 = Bytes.alloc(Md5.BYTES + this.seed.length);
		d2 = Bytes.alloc(Sha1.BYTES + this.seed.length);
		d1.blit(Md5.BYTES, this.seed, 0, this.seed.length);
		d2.blit(Sha1.BYTES, this.seed, 0, this.seed.length);

		size = d2.length;
	}

	public function toString():String {
		return "tls-prf";
	}

	/**
	 * Discards pool initialization
	 **/
	public function init(key : Array<Int>) : Void {
	}

	public function nextBytes(bytes : Bytes, pos:Int, len:Int):Void {
		for(i in 0...len) {
			bytes.set(pos+i, next());
		}
	}

	public function next():Int {
		if (p1.length==0) {
			more_md5();
		}
		if (p2.length==0) {
			more_sha1();
		}
		return p1.shift()^p2.shift();
	}

	public function dispose():Void {
		seed.dispose();
		s1.dispose();
		s2.dispose();
		a1.dispose();
		a2.dispose();
		d1.dispose();
		d2.dispose();
		while(p1.length > 0)
			p1.pop();
		while(p2.length > 0)
			p2.pop();
		seed = null;
		s1 = null;
		s2 = null;
		a1 = null;
		a2 = null;
		p1 = null;
		p2 = null;
		d1 = null;
		d2 = null;
		hmac_md5.dispose();
		hmac_md5 = null;
		hmac_sha1.dispose();
		hmac_sha1 = null;
	}

	private function more_md5():Void {
		d1.blit(0, a1, 0, a1.length);
		var more:Bytes = hmac_md5.calculate(s1, d1);
		a1 = hmac_md5.calculate(s1, a1);
		for(i in 0...more.length)
			p1.push(more.get(i));
		more.dispose();
	}

	private function more_sha1():Void {
		d2.blit(0, a2, 0, a2.length);
		var more:Bytes = hmac_sha1.calculate(s2, d2);
		a2 = hmac_sha1.calculate(s2, a2);
		for(i in 0...more.length)
			p2.push(more.get(i));
		more.dispose();
	}

}
