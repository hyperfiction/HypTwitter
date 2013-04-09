/*
 * Copyright (c) 2011, The Caffeine-hx project contributors
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
/**
 * Very similar to PKCS5 padding, but adds one extra byte of the pad length
 * @todo In TLS, the padding may be any random length up to 255 bytes,
 *       as per RFC 4346 Section 6.2.3.2, to decrease attacks on the protocol.
 *       Should add a method to allow for random pad lengths.
 **/
class PadTLS extends PadBase, implements IPad {

	override public function pad( s : Bytes ) : Bytes {
		var c = blockSize - ((s.length+1) % blockSize);
		if (c <= 0) return s;
		var bb = new BytesBuffer();
		bb.add(s);
		for(i in 0...c+1) {
			bb.addByte(c);
		}
		return bb.getBytes();
	}

	override public function unpad( s : Bytes ) : Bytes {
		if( s.length % blockSize != 0)
			throw new chx.lang.Exception("PadTLS unpad: buffer length "+s.length+" not multiple of block size " + blockSize);
		var c = s.get(s.length-1);
		var i:Int = c;
		var len = s.length;
		while(i > -1) {
			var n = s.get(pos);
			if (c != n)
				throw new chx.lang.Exception("PadTLS unpad: invalid byte");
			len--;
			i--;
		}
		return s.sub(0, len);
	}

}
