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

package math.prng;

class ArcFour implements IPrng {
	var i : Int;
	var j : Int;
	var S : Array<Int>;
	public var size(default,null) : Int;

	public function new() {
		i = 0;
		j = 0;
		S = new Array();
		setSize(256);
	}

	/**
		Initialize arcfour context from key, an array of ints,
		each from [0..255]. An array of bytes the size of the
		pool must be passed to init()
	**/
	public function init(key : Array<Int>) : Void {
		var t : Int;
		for(x in 0 ... 256)
			S[x] = x;
		j = 0;
		for(i in  0...256) {
			j = (j + S[i] + key[i % key.length]) & 255;
			t = S[i];
			S[i] = j;
			S[j] = t;
		}
		i = 0;
		j = 0;
	}

	/**
		Returns the next byte.
	**/
	public function next() : Int {
		if(S.length == 0)
			throw "not initialized";
		var t;
		i = (i + 1) & 255;
		j = (j + S[i]) & 255;
		t = S[i];
		S[i] = S[j];
		S[j] = t;
		return S[(t + S[i]) & 255];
	}

	/**
		Pool size must be a multiple of 4 and greater than 32.
	**/
	function setSize( v : Int ) : Int {
		if( v % 4 != 0 || v < 32)
			throw "invalid size";
		size = v;
		return v;
	}

	public function toString() : String {
		return "rc4";
	}
}
