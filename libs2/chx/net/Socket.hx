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

package chx.net;

interface Socket {
	var __handle(default, null) : Dynamic;
	var bigEndian(default,setEndian) : Bool;
	var input(default,null) : chx.io.Input;
	var output(default,null) : chx.io.Output;
	var custom : Dynamic;

	/**
	 * Accept an incoming connection
	 * @throws chx.lang.BlockedException if the socket is non-blocking and there is no connection to accept
	 */
	function accept() : Socket;

	/**
	 * For event driven architectures like Flash, adds a listener class
	 * @param l IEventDrivenSocketListener instance
	 */
	function addEventListener( l : IEventDrivenSocketListener ) : Void;

	/**
	 * Bind to a host/port to accept incoming connections
	 * @throws chx.lang.IOException if unable to bind to host/port combination
	 */
	function bind(host : String, port : Int) : Void;

	/**
	 * Connect to a remote host/port
	 * @param host Host ip address or hostname.
	 * @param port Port number to connect to.
	 * @throws chx.lang.IOException - Connection failed
	 * @throws chx.lang.Exception - Other errors
	 */
	function connect(host : String, port : Int) : Void;

	/**
	 * Closes the socket.
	 * @param errCondition Condition that caused the closure
	 */
	function close(errCondition:Dynamic=null) : Void;

	/**
	 * Returns information on the local portion of the socket
	 */
	function host() : { host : Host, port : Int };

	function listen(connections : Int) : Void;

	/**
	 * Returns information about the remot host
	 **/
	function peer() : { host : Host, port : Int };

	/**
		Read whatever data is available on the socket.
		@throws chx.lang.EOFException if socket is closed
		@throws chx.lang.BlockedException if socket would block
	**/
	function read() : Bytes;

	/**
	 * For event driven architectures like Flash, removes a listener class
	 * @param l And IEventDrivenSocketListener instance
	 */
	function removeEventListener( l : IEventDrivenSocketListener ) : Void;

	/**
	 * Sets if reads and writes will block. Event driven socket listeners like flash
	 * will not allow for blocking.
	 * @param b True to set blocking, false for non-blocking
	 */
	function setBlocking( b : Bool ) : Void;

	/**
	 * Sets the endianess of the socket connection
	 * @param bigEndian True to set big endian, false for little endian
	 * @return Input value
	 */
	function setEndian(bigEndian : Bool) : Bool;

	/**
	 *
	 */
	function setTimeout( timeout : Float ) : Void;

	/**
	 * Returns the function that is used for select() calls for the socket type.
	 */
	function selectFunction() : Array<Socket> -> Array<Socket> ->  Array<Socket> -> Float -> {read: Array<Socket>,write: Array<Socket>,others: Array<Socket>};

	/**
	 * Shutdown (close) either part of a socket connection.
	 */
	function shutdown( read : Bool, write : Bool ) : Void;

	/**
	 * Block until a read occurs. Not available on event driven architectures.
	 */
	function waitForRead() : Void;

    /**
     * Write the contents of Bytes to the socket.
     * @param content A Bytes value
     * @throws chx.lang.BlockedException If socket blocks.
	 * @throws chx.lang.IOException For other error conditions including socket closed
     */
	function write( content : Bytes ) : Void;

}
