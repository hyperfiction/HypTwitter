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
package chx.net.servers;

import haxe.remoting.Context;
import haxe.remoting.SocketConnection;

class ThreadRemotingServer extends ThreadServer<haxe.remoting.SocketConnection,String> {
	var scCreate : chx.net.Socket -> Context -> haxe.remoting.SocketConnection;
	var domains : Array<String>;
	var port : Int;

	public function new( ?domains ) {
		super();
		messageHeaderSize = 2;
		this.domains = domains;
	}

	/**
	 * Called before initClientApi, this method must create a SocketConnection of some sort. By
	 * default it is a haxe.remoting.SocketConnection.
	 */
	public dynamic function createSocketConnection(s:chx.net.Socket, ctx:Context) : SocketConnection {
		return haxe.remoting.SocketConnection.create(s,ctx);
	}

	public dynamic function initClientApi( cnx : haxe.remoting.SocketConnection, ctx : haxe.remoting.Context ) {
		throw "Not implemented";
	}

	public dynamic function onXml( cnx : haxe.remoting.SocketConnection, data : String ) {
		throw "Unhandled XML data '"+data+"'";
	}

	public dynamic function makePolicyFile() {
		var str = "<cross-domain-policy>";
		for( d in domains )
			str += '<allow-access-from domain="'+d+'" to-ports="'+port+'"/>';
		str += "</cross-domain-policy>";
		return str;
	}

	public override function run( host, port ) {
		this.port = port;
		super.run(host,port);
	}

	public override function clientConnected( s : chx.net.Socket ) {
		var ctx = new haxe.remoting.Context();
		var cnx = createSocketConnection(s, ctx);
		var me = this;
		cnx.setErrorHandler(function(e) {
			if( !Std.is(e,chx.lang.EofException) && !Std.is(e,chx.lang.IOException) )
				me.logError(e);
			me.stopClient(s);
		});
		initClientApi(cnx,ctx);
		return cnx;
	}

	override function readClientMessage( cnx : haxe.remoting.SocketConnection, buf : Bytes, pos : Int, len : Int ) {
		var o = cnx.getProtocol().decodeMessageLength(buf, pos, len);
		if( o.length == null ) {
			if( buf.get(pos) != 60 )
				throw "Invalid remoting message '"+buf.readString(pos,len)+"'";
			var p = pos;
			while( p < len ) {
				if( buf.get(p) == 0 )
					break;
				p++;
			}
			if( p == len )
				return null;
			p -= pos;
			return {
				msg : buf.readString(pos,p),
				bytes : p + 1,
			};
		}
		if( len < o.length )
			return null;
		if( buf.get(pos + o.bytesUsed + o.length-1) != 0 )
			throw "Truncated message";
		return {
			msg : buf.readString(pos+o.bytesUsed, o.length-1),
			bytes : o.length + o.bytesUsed,
		};
	}

	public override function clientMessage( cnx : haxe.remoting.SocketConnection, msg : String ) {
		try {
			if( msg.charCodeAt(0) == 60 ) {
				if( domains != null && msg == "<policy-file-request/>" )
					cnx.getProtocol().socket.write(Bytes.ofString(makePolicyFile()+"\x00"));
				else
					onXml(cnx,msg);
			} else
				cnx.processMessage(msg);
		} catch( e : Dynamic ) {
			if( !Std.is(e,chx.lang.EofException) && !Std.is(e,chx.lang.IOException) )
				logError(e);
			stopClient(cnx.getProtocol().socket);
		}
	}

}
