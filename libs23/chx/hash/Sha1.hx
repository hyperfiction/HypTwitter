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

import haxe.io.Bytes;
import haxe.io.BytesBuffer;

import BytesUtil;

class Sha1 implements IHash {

    public function new() {
	}

	public function dispose() : Void {
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


	public function encode(msg:Bytes) : Bytes {
	    return Bytes.ofString(haxe.crypto.Sha1.encode( msg.readString(0,msg.length)));
	}

}
