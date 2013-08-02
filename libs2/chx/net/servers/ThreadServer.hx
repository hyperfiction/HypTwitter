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

private typedef ThreadInfos = {
	var id : Int;
	var t : chx.vm.Thread;
	var p : chx.net.Poll;
	var socks : Array<chx.net.Socket>;
}

private typedef ClientInfos<Client> = {
	var client : Client;
	var sock : chx.net.Socket;
	var thread : ThreadInfos;
	var buf : Bytes;
	var bufpos : Int;
}

class ThreadServer<Client,Message> {

	var threads : Array<ThreadInfos>;
	var sock : chx.net.Socket;
	var worker : chx.vm.Thread;
	var timer : chx.vm.Thread;
	public var listen : Int;
	public var nthreads : Int;
	public var connectLag : Float;
	public var errorOutput : chx.io.Output;
	public var initialBufferSize : Int;
	public var maxBufferSize : Int;
	public var messageHeaderSize : Int;
	public var updateTime : Int;
	public var maxSockPerThread : Int;

	public function new() {
		threads = new Array();
		nthreads = if( chx.Sys.systemName() == "Windows" ) 150 else 10;
		messageHeaderSize = 1;
		listen = 10;
		connectLag = 0.5;
		errorOutput = chx.io.File.stderr();
		initialBufferSize = (1 << 10);
		maxBufferSize = (1 << 16);
		maxSockPerThread = 64;
		updateTime = 1000;
	}

	function runThread(t) {
		while( true ) {
			try {
				loopThread(t);
			} catch( e : Dynamic ) {
				logError(e);
			}
		}
	}

	function readClientData( c : ClientInfos<Client> ) {
		var available = c.buf.length - c.bufpos;
		if( available == 0 ) {
			var newsize = c.buf.length * 2;
			if( newsize > maxBufferSize ) {
				newsize = maxBufferSize;
				if( c.buf.length == maxBufferSize )
					throw "Max buffer size reached";
			}
			var newbuf = Bytes.alloc(newsize);
			newbuf.blit(0,c.buf,0,c.bufpos);
			c.buf = newbuf;
			available = newsize - c.bufpos;
		}
		var bytes = c.sock.input.readBytes(c.buf,c.bufpos,available);
		var pos = 0;
		var len = c.bufpos + bytes;
		while( len >= messageHeaderSize ) {
			var m = readClientMessage(c.client,c.buf,pos,len);
			if( m == null )
				break;
			pos += m.bytes;
			len -= m.bytes;
			work(callback(clientMessage,c.client,m.msg));
		}
		if( pos > 0 )
			c.buf.blit(0,c.buf,pos,len);
		c.bufpos = len;
	}

	function loopThread( t : ThreadInfos ) {
		if( t.socks.length > 0 )
			for( s in t.p.poll(t.socks,connectLag) ) {
				var infos : ClientInfos<Client> = s.custom;
				try {
					readClientData(infos);
				} catch( e : Dynamic ) {
					t.socks.remove(s);
					if( !Std.is(e,chx.lang.EofException) && !Std.is(e,chx.lang.IOException) )
						logError(e);
					work(callback(doClientDisconnected,s,infos.client));
				}
			}
		while( true ) {
			var m : { s : chx.net.Socket, cnx : Bool } = chx.vm.Thread.readMessage(t.socks.length == 0);
			if( m == null )
				break;
			if( m.cnx )
				t.socks.push(m.s);
			else if( t.socks.remove(m.s) ) {
				var infos : ClientInfos<Client> = m.s.custom;
				work(callback(doClientDisconnected,m.s,infos.client));
			}
		}
	}

	function doClientDisconnected(s:chx.net.Socket,c) {
		try s.close() catch( e : Dynamic ) {};
		clientDisconnected(c);
	}

	function runWorker() {
		while( true ) {
			var f = chx.vm.Thread.readMessage(true);
			try {
				f();
			} catch( e : Dynamic ) {
				logError(e);
			}
			try {
				afterEvent();
			} catch( e : Dynamic ) {
				logError(e);
			}
		}
	}

	public function work( f : Void -> Void ) {
		worker.sendMessage(f);
	}

	function logError( e : Dynamic ) {
		var stack = haxe.Stack.exceptionStack();
		if( chx.vm.Thread.current() == worker )
			onError(e,stack);
		else
			work(callback(onError,e,stack));
	}

	function addClient( sock : chx.net.Socket ) {
		var infos : ClientInfos<Client> = {
			thread : threads[Std.random(nthreads)],
			client : clientConnected(sock),
			sock : sock,
			buf : Bytes.alloc(initialBufferSize),
			bufpos : 0,
		};
		sock.custom = infos;
		infos.thread.t.sendMessage({ s : sock, cnx : true });
	}

	function runTimer() {
		var l = new chx.vm.Lock();
		while( true ) {
			l.wait(updateTime);
			work(update);
		}
	}

	function init() {
		worker = chx.vm.Thread.create(runWorker);
		timer = chx.vm.Thread.create(runTimer);
		for( i in 0...nthreads ) {
			var t = {
				id : i,
				t : null,
				socks : new Array(),
				p : new chx.net.Poll(maxSockPerThread),
			};
			threads.push(t);
			t.t = chx.vm.Thread.create(callback(runThread,t));
		}
	}

	public function addSocket( s : chx.net.Socket ) {
		s.setBlocking(false);
		work(callback(addClient,s));
	}

	public function run( host:String, port:Int ) {
		sock = new chx.net.TcpSocket();
		sock.bind(host,port);
		sock.listen(listen);
		init();
		while( true ) {
			try {
				addSocket(sock.accept());
			} catch( e : Dynamic ) {
				logError(e);
			}
		}
	}

	public function sendData( s : chx.net.Socket, data : Bytes ) {
		try {
			s.write(data);
		} catch( e : Dynamic ) {
			stopClient(s);
		}
	}

	public function stopClient( s : chx.net.Socket ) {
		var infos : ClientInfos<Client> = s.custom;
		try s.shutdown(true,true) catch( e : Dynamic ) { };
		infos.thread.t.sendMessage({ s : s, cnx : false });
	}

	// --- CUSTOMIZABLE API ---

	public dynamic function onError( e : Dynamic, stack ) {
		var estr = try Std.string(e) catch( e2 : Dynamic ) "???" + try "["+Std.string(e2)+"]" catch( e : Dynamic ) "";
		errorOutput.writeString( estr + "\n" + haxe.Stack.toString(stack) );
		errorOutput.flush();
	}

	public dynamic function clientConnected( s : chx.net.Socket ) : Client {
		return null;
	}

	public dynamic function clientDisconnected( c : Client ) {
	}

	public dynamic function readClientMessage( c : Client, buf : Bytes, pos : Int, len : Int ) : { msg : Message, bytes : Int } {
		return {
			msg : null,
			bytes : len,
		};
	}

	public dynamic function clientMessage( c : Client, msg : Message ) {
	}

	public dynamic function update() {
	}

	public dynamic function afterEvent() {
	}

}
