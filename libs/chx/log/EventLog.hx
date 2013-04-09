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

package chx.log;

import chx.log.LogLevel;
import haxe.PosInfos;
import haxe.Stack;

/**
* This is the system EventLog. Multiple loggers can be added to the chain
* using the add() method. If a default logger is not created, one will be
* created automatically, based on the target platform, during the first
* call to any logging function.
**/
class EventLog {
	/** The list of loggers that will record events */
	public static var loggers : List<IEventLog> = new List<IEventLog>();
	/** The default service name used for any logger that is created */
	public static var defaultServiceName : String = "Haxe App";
	/** the minimum log level that will be logged */
	public static var defaultLevel : LogLevel = NOTICE;

	/**
	 * Adds an IEventLog instance to the logging chain
	 * @param	l
	 */
	public static function add(l:IEventLog) {
		var found = false;
		for (i in loggers) {
			if (i == l) {
				found = true;
				break;
			}
		}
		if (!found)
			loggers.add(l);		
	}
	
	/**
	 * Close all open loggers, removing them from the list
	 */
	public static function close() : Void {
		for (i in loggers) {
			i.close();
			loggers.remove(i);
		}
	}
	
	public static function debug(s:String, ?pos:PosInfos) : Void { log(s,DEBUG, pos); }
	public static function info(s:String, ?pos:PosInfos) : Void { log(s,INFO, pos); }
	public static function notice(s : String, ?pos:PosInfos) : Void { log(s,NOTICE, pos); }
	public static function warn(s : String, ?pos:PosInfos) : Void { log(s,WARN, pos); }
	public static function error(s : String, ?pos:PosInfos) : Void { log(s,ERROR, pos); }
	public static function critical(s : String, ?pos:PosInfos) : Void { log(s,CRITICAL, pos); }
	public static function alert(s : String, ?pos:PosInfos) : Void { log(s,ALERT, pos); }
	public static function emerg(s : String, ?pos:PosInfos) : Void { log(s,EMERG, pos); }

	/**
		Logs to the default logger, at the error level specified by
		[lvl]. If [lvl] is not specified, the level NOTICE will be used.
	**/
	public static function log(s : String, ?lvl:LogLevel, ?pos:PosInfos) {
		if(lvl == null)
			lvl = NOTICE;
		if(loggers.length == 0) {
			#if (neko||php||cpp)
				new File(defaultServiceName, defaultLevel, null).addToLogChain();
			#else
				new TraceLog(defaultServiceName, defaultLevel).addToLogChain();
			#end
		}
		for (i in loggers) {
			i.log(s, lvl, pos);
		}
	}

	/**
	 * Log an exception, which will also log the exception stack. This method is
	 * dynamic, so it may be replace with a custom handler.
	 * @param	e The exception
	 * @param	lvl The log level will default to WARN if not set
	 * @param	?pos Automatic haxe position information
	 */
	public static dynamic function logException(e:Dynamic, lvl:LogLevel=null, ?pos:PosInfos) : Void {
		if (lvl == null)
			lvl = WARN;
		log("Exception: " + Std.string(e), lvl);
		var a:Array<haxe.StackItem> = Stack.exceptionStack();
		for (i in a) {
			log("    " + i, lvl);
		}
	}
}