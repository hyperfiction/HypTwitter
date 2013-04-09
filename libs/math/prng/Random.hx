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

/**
 * Random number generator. By default, a Prng backend of ArcFour will be created,
 * but any IPrng backend can be used.
 **/
package math.prng;

import chx.io.Output;

class Random {
	var state : #if as3gen Dynamic #else IPrng #end;
	var pool : Array<Int>;
	var pptr : Int;
	var initialized: Bool;

	public function new(?backend: IPrng) {
		createState(backend);
		initialized = false;
	}

	/**
	 * Get one random byte value
	 **/
	public function next() : Int {
		if(initialized == false) {
			createState();
			state.init(pool);
			for(i in 0...pool.length)
				pool[i] = 0;
			pptr = 0;
			pool = new Array();
			initialized = true;
		}
		return state.next();
	}

	/**
	 * Fill the provided Bytes with random bytes, starting at position pos for len bytes
	 * @param bytes Bytes array to put random bytes into
	 * @param pos Starting position in output bytes
	 * @param len Number of bytes to write
	 **/
	public function nextBytes(bytes : Bytes, pos:Int, len:Int) : Void {
		for(i in 0...len)
			bytes.set(pos+i, next());
	}

	/**
	 * Stream to the provided Output a certain number of random bytes
	 * @param out An output stream
	 * @param count Number of bytes to write
	 **/
	public function nextBytesStream(out:Output, count:Int) : Void {
		for(i in 0...count)
			out.writeUInt8(next());
	}

	/**
		Mix in a 32-bit integer into the pool
	**/
	function seedInt(x : Int) {
		pool[pptr++] ^= x & 255;
		pool[pptr++] ^= (x >> 8) & 255;
		pool[pptr++] ^= (x >> 16) & 255;
		pool[pptr++] ^= (x >> 24) & 255;
		if(pptr >= state.size)
			pptr -= state.size;
	}

	// Mix in the current time (w/milliseconds) into the pool
	function seedTime() {
		var dt = Date.now().getTime();
		var m = Std.int(dt * 1000);
		seedInt(m);
	}

	function createState(?backend: IPrng) {
		if(backend == null)
			state = new ArcFour();
		else
			state = backend;
		if(pool == null) {
			pool = new Array();
			pptr = 0;
			var t;
/*
			// TODO:
			if(navigator.appName == "Netscape" && navigator.appVersion < "5" && window.crypto) {
				// Extract entropy (256 bits) from NS4 RNG if available
				var z = window.crypto.random(32);
				for(t = 0; t < z.length; ++t)
				pool[pptr++] = z.charCodeAt(t) & 255;
			}
*/
			while(pptr < state.size) {  // extract some randomness from Math.random()
				t = Math.floor(65536 * Math.random());
				pool[pptr++] = t >>> 8;
				pool[pptr++] = t & 255;
			}
			pptr = 0;
			seedTime();
		}
	}

}

