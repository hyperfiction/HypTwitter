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

package chx.crypt.padding;

class PadPkcs5 extends PadBase, implements IPad {

	override public function calcNumBlocks(len : Int) : Int {
		var chr : Int = blockSize - (len % blockSize);
		Assert.isEqual(0, (len + chr) % blockSize);
		return Math.floor((len + chr) / blockSize);
	}

	override public function pad( s : Bytes ) : Bytes {
		var sb = new BytesBuffer();
		if(s.length > 0)
			sb.add ( s );
		var chr : Int = blockSize - (s.length % blockSize);
		if(s.length == blockSize)
			chr = blockSize;
		for( i in 0...chr) {
			sb.addByte( chr );
		}
		var rv = sb.getBytes();
		return rv;
	}

	override public function unpad( s : Bytes ) : Bytes {
		if( s.length % blockSize != 0 || s.length < blockSize)
			throw "crypt.padpkcs5 unpad: buffer length "+s.length+" not multiple of block size " + blockSize;
		var c : Int = s.get(s.length-1);
		var i = c;
		var pos = s.length - 1;
		while(i > 0) {
			var n = s.get(pos);
			if (c != n)
				throw "crypt.padpkcs5 unpad: invalid byte";
			pos--;
			i--;
		}
		return s.sub(0, s.length - c);
	}

}
