/*
 * Copyright (c) 2010, The Caffeine-hx project contributors
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

package chx.log;
import chx.io.Output;
import chx.text.CallbackPrintf;
import haxe.FastList;
import haxe.PosInfos;

/**
 * Creates a log format from a string.
 * <pre>
 * 
 * %c Class name (short)
 * %C Class name (long)
 * %d Date
 * %e Debug log level
 * %f File name
 * %i Log message
 * %l Line number
 * %m Method name
 * %s Service name
 * </pre>
 * @author Russell Weir
 */
class LogFormat 
{
	inline public static var formatShort : String = "%s:%e: %i (%c:%m:%l)";
	inline public static var formatLong : String = "[%d] %s : %e : %i (%C:%m:%l)"; //"["+Date.now().toString()+"] " +serviceName + " : "+Std.string(lvl)+" : "+ s + "
	inline public static var formatSyslog : String = "%i (%C:%m:%l)";
	
	public var formatString(getFormatString, setFormatString) : String;
	var cbpf : CallbackPrintf;
	
	var service:String;
	var level : LogLevel;
	var msg : String;
	var pos : PosInfos;
	
	public function new(fmt:String=null) 
	{
		cbpf = new CallbackPrintf();
		cbpf.registerCallback("c", writeClassShort);
		cbpf.registerCallback("C", writeClassLong);
		cbpf.registerCallback("d", writeDate);
		cbpf.registerCallback("e", writeLevel);
		cbpf.registerCallback("f", writeFileName);
		cbpf.registerCallback("i", writeMessage);
		cbpf.registerCallback("l", writeLineNumber);
		cbpf.registerCallback("m", writeMethodName);
		cbpf.registerCallback("s", writeServiceName);
		setFormatString(fmt);
	}
	
	public function clone() : LogFormat {
		return new LogFormat(this.getFormatString());
	}
	
	public function writeLogMessage(out:Output, service:String, lvl:LogLevel, msg:String, pos:PosInfos) : Void {
		this.service = service;
		this.level = lvl;
		this.msg = msg;
		this.pos = pos;
		return cbpf.write(out, formatString, []);
	}
	
	public function setFormatString(fmtString:String) : String {
		this.formatString = fmtString;
		return this.formatString;
	}
	
	public function getFormatString() : String {
		return this.formatString;
	}
	
	function writeClassShort(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		if (pos == null || pos.className == null || pos.className.length == 0)
			out.writeString("(null)");
		else {
			var parts = pos.className.split(".");
			out.writeString(parts.pop());
		}
	}
	
	function writeClassLong(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		if (pos == null || pos.className == null || pos.className.length == 0)
			out.writeString("(null)");
		else {
			out.writeString(pos.className);
		}
	}
	
	function writeLineNumber(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		if (pos == null)
			out.writeString("(unknown)");
		else {
			out.writeString(Std.string(pos.lineNumber));
		}
	}
	
	function writeFileName(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		if (pos == null)
			out.writeString("(unknown file)");
		else {
			out.writeString(pos.fileName);
		}
	}
	
	function writeMethodName(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		if (pos == null)
			out.writeString("(unknown method)");
		else {
			out.writeString(pos.methodName);
		}
	}
		
	function writeLevel(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		if (this.level == null)
			out.writeString("(unknown log level)");
		else {
			out.writeString(Std.string(this.level));
		}
	}
	
	function writeServiceName(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		if (service == null)
			out.writeString("(unknown service)");
		else {
			out.writeString(service);
		}
	}
	
	function writeMessage(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		if (this.msg == null)
			out.writeString("(null)");
		else {
			out.writeString(this.msg);
		}
	}
	
	function writeDate(out:Output, arg : Dynamic, props:Int, len:Null<Int>, precision:Null<Int>) : Void {
		out.writeString(Date.now().toString());
	}
}