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

/**
 * Pads with NULL (0) bytes
 **/
class PadNull implements IPad {
	public var blockSize(default,setBlockSize) : Int;
	public var textSize(default,null) : Int;

	public function new( blockSize : Null<Int> = null ) {
		if(blockSize != null)
			setBlockSize(blockSize);
	}

	public function pad( s : Bytes ) : Bytes {
		var r = blockSize - (s.length % blockSize);
		if(r == blockSize)
			return s;
		var sb = new BytesBuffer();
		sb.add(s);
		for(x in 0...r) {
			sb.addByte(0);
		}
		return sb.getBytes();
	}

	/**
	 * Null padded strings can't be reliably unpadded, since the
	 * source may contain nulls. It is up to the implementation to
	 * keep track of how many bytes in the packet are used.
	 **/
	public function unpad( s : Bytes ) : Bytes {
		return s;
	}

	public function calcNumBlocks(len : Int) : Int {
		return Math.ceil(len/blockSize);
	}

	private function setBlockSize( x : Int ) : Int {
		this.blockSize = x;
		this.textSize = x;
		return x;
	}
}
