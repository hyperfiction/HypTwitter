/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
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

package chx.io;

import Bytes;
import BytesBuffer;
import chx.io.Input;

/**
	Any kind of input that requires filtering before passing to reader. The actual input stream
	is stored as var 'input'
**/
class FilteredInput extends Input {
	var input : Input;

	public function new( input : Input ) {
		this.input = input;
	}

	public override function readByte() : Int {
		return input.readByte();
	}

	override function getBytesAvailable() : Int {
		return input.bytesAvailable;
	}

	override function setEndian(b) {
		input.bigEndian = b;
		return b;
	}

	public override function readBytes( s : Bytes, pos : Int, len : Int ) : Int {
		return input.readBytes( s, pos, len );
	}

	public override function close() {
		input.close();
	}


	public override function readAll( ?bufsize : Int ) : Bytes {
		return input.readAll( bufsize );
	}

	public override function readFullBytes( s : Bytes, pos : Int, len : Int ) : Void {
		input.readFullBytes( s, pos, len );
	}

	public override function read( nbytes : Int ) : Bytes {
		return input.read( nbytes );
	}

	public override function readUntil( end : Int ) : String {
		return input.readUntil( end );
	}

	public override function readLine() : String {
		return input.readLine();
	}

	public override function readFloat() : Float {
		return input.readFloat();
	}

	public override function readDouble() : Float {
		return input.readDouble();
	}

	public override function readInt8() {
		return input.readInt8();
	}

	public override function readInt16() {
		return input.readInt16();
	}

	public override function readUInt16() {
		return input.readUInt16();
	}

	public override function readInt24() {
		return input.readInt24();
	}

	public override function readUInt24() {
		return input.readUInt24();
	}

	public override function readInt31() {
		return input.readInt31();
	}

	public override function readUInt30() {
		return input.readUInt30();
	}

	public override function readInt32() {
		return input.readInt32();
	}

	public override function readString( len : Int ) : String {
		return input.readString( len );
	}
}
