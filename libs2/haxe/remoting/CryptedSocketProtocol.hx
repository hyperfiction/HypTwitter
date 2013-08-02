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
package haxe.remoting;
import chx.io.StringOutput;
import chx.Serializer;
import SocketProtocol.Socket;
import chx.crypt.IMode;

/**
 * Crypted sockets allow remoting sessions to be encrypted with a cipher suite. The
 * protocol can easily be switched to and from plain text mode simply by setting the
 * crypt member to null or a cipher.
 **/
class CryptedSocketProtocol extends SocketProtocol {

	/**
	 * Starts crypting communications with the provided cipher. Setting
	 * to null will disable crypted mode.
	 **/
	public var cipher : IMode;

	public function new( sock, ctx, cipher:IMode=null ) {
		super(sock, ctx);
		this.cipher = cipher;

		var me = this;
		encodeData = function( data : String ) : String {
			if(me.cipher == null)
				return data;
			return chx.formats.Base64.encode(me.cipher.encrypt(Bytes.ofString(data)));
		}

		decodeData = function( data : String ) {
			if(me.cipher == null)
				return data;
			return me.cipher.decrypt(chx.formats.Base64.decode(data)).toString();
		}
	}

}
