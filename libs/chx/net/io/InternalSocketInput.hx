/*
* Copyright (c) 2008-2009, Russell Weir, The haXe Project Contributors
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are permitted
* provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice, this list of conditions
*  and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice, this list of conditions
*  and the following disclaimer in the documentation and/or other materials provided with the distribution.
* - Neither the name of the author nor the names of its contributors may be used to endorse or promote
*  products derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package chx.net.io;

import chx.net.InternalSocket;

import chx.lang.Exception;
import chx.lang.EofException;
import chx.lang.BlockedException;
import chx.lang.OutsideBoundsException;
import chx.lang.OverflowException;

/**
	An Input class for chx.net.InternalSocket
	@todo test
	@todo what is readInit doing?
	@todo override readBytes
**/
class InternalSocketInput extends chx.io.Input
{
	private var __handle 	: InternalSocket;

	private var idx			: Int;
	private var data		: Bytes;

	public function new(s) {
		__handle = s;
		idx = 0;
		data = null;
	}

	public override function close() {
		super.close();
		if( __handle != null ) __handle.close();
	}

	override function getBytesAvailable() : Int {
		if(data == null)
			return 0;
		return data.length - idx;
	}

	private function readInit() {
		var p : InternalSocket;
		switch(__handle.getType()) {
		case UNKNOWN:
			new EofException();
		case CLIENT:
			__handle = __handle.getPeer();
		case SERVER:
		case PEER:
			//__handle = __handle;
		}
		if(__handle == null) {
			trace(here.methodName + " SOCKET NULL");
			new EofException();
		}
	}

	public override function readByte() : Int {
		while(getBytesAvailable() == 0) {
			idx = 0;
			data = null;
			// exceptions can propagate
			data = __handle.read();
		}
		var c = data.get(idx++);
		if(getBytesAvailable() <= 0) {
			data = null;
			idx = 0;
		}
		return c;
	}

	/*
	public override function readAll( ?bufsize : Int ) : String {
		if( bufsize == null )
				bufsize = (1 << 14); // 16 Ko
		var buf = chx.Lib.makeString(bufsize);
		var total = new StringBuf();
		var oldBlock = __handle.getBlocking();
		__handle.setBlocking(false);
		try {
				while( true ) {
						var len = readBytes(buf,0,bufsize);
						if( len == 0 )
								return total.toString();
						total.addSub(buf,0,len);
				}
		} catch(e: Dynamic) {
			__handle.setBlocking(oldBlock);
			throw e;
		}
		__handle.setBlocking(oldBlock);
		return total.toString();
	}
	*/

	/**
	@deprecated rweir: not required with .bytesAvailable property in chx.io.Input
	@todo locate where this method is called from and recode with .bytesAvailable
	**/
	public function hasData() : Bool {
		return (getBytesAvailable() > 0);
	}

	/**
	@deprecated rweir: should not be exposed
	@todo locate where this method is called from and recode
	**/
	public function getData() : Bytes {
		return data;
	}
}
