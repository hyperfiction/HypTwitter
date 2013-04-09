/*
 * Copyright (c) 2005, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package system.net.servers;

class TcpRealtimeRemoting extends TcpRealtimeServer<haxe.remoting.SocketConnection> {

	public function new() {
		super();
		config.messageHeaderSize = 2;
	}

	/**
		Must be implemented in a subclass. May be as simple as <code>var c = new ClientData(cnx, ctx);</code>
	**/
	public dynamic function initClientApi(cnx : haxe.remoting.SocketConnection, ctx : haxe.remoting.Context) {
		throw "Not implemented";
	}

	/**
		In flash, policy file requests are sent to remoting servers. This method
		must deal with those directly, by sending the policy file text followed by
		a NULL byte. <br />
		For example: <br />
		<code>
		var policy = "<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>";
		cnx.getProtocol().socket.write(policy + String.fromCharCode(0))
		</code>
	**/
	public dynamic function onXml(cnx : haxe.remoting.SocketConnection, data : String) {
		throw "Unhandled XML data '"+data+"'";
	}

	/**
		Do not override when subclassing, will call initClientApi during a new connection.
	**/
	public override function clientConnected( s : chx.net.Socket ) {
		var ctx = new haxe.remoting.Context();
		var cnx = haxe.remoting.SocketConnection.create(s,ctx);
		var me = this;
		cnx.setErrorHandler(function(e) {
			if( !Std.is(e,chx.lang.EofException) && !Std.is(e,chx.lang.IOException) )
				me.logError(e);
			me.stopClient(s);
		});
		initClientApi(cnx,ctx);
		return cnx;
	}

	/**
		Do not override when subclassing.
	**/
	public override function readClientMessage( cnx : haxe.remoting.SocketConnection, buf : Bytes, pos : Int, len : Int ) {
		var msgLen = cnx.getProtocol().messageLength(buf.get(pos),buf.get(pos+1));
		if( msgLen == null ) {
			if( buf.get(pos) != 60 )
				throw "Invalid remoting message '"+buf.sub(pos,len).toString()+"'";
			var p = pos;
			while( p < len ) {
				if( buf.get(p) == 0 )
					break;
				p++;
			}
			if( p == len )
				return null;
			p -= pos;
			handleClientMessage(cnx, buf.sub(pos,p));
			return p + 1;
		}
		if( len < msgLen )
			return null;
		if( buf.get(pos + msgLen-1) != 0 )
			throw "Truncated message";
		handleClientMessage(cnx, buf.sub(pos+2,msgLen-3));
		return msgLen;
	}

	function handleClientMessage( cnx : haxe.remoting.SocketConnection, msg : Bytes ) {
		if( msg.get(0) == 60 ) {
			onXml(cnx,msg.toString());
			return;
		}
		try {
			cnx.processMessage(msg.toString());
		} catch( e : Dynamic ) {
			if( !Std.is(e,chx.lang.EofException) && !Std.is(e,chx.lang.IOException) )
				logError(e);
			stopClient(cnx.getProtocol().socket);
			return;
		}
	}

}
