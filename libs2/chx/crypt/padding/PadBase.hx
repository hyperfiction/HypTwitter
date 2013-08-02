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

class PadBase implements IPad {

	public var blockSize(default,setBlockSize) : Int;

	public function new( blockSize : Null<Int> = null ) {
		if(blockSize != null)
			setBlockSize(blockSize);
	}

	public function pad( s : Bytes ) : Bytes {
		return throw new chx.lang.FatalException("not implemented");
	}
	
	public function unpad( s : Bytes ) : Bytes {
		return throw new chx.lang.FatalException("not implemented");
	}

	function setBlockSize(len : Int) : Int {
		blockSize = len;
		return len;
	}

	public function calcNumBlocks(len : Int) : Int {
		if(len == 0) return 0;
		var n : Int = Math.ceil(len/blockSize);
		// most pads will require an extra block if the input length
		// is an exact multiple of the block size
 		if(len % blockSize == 0)
 			n++;
		return n;
	}

}
