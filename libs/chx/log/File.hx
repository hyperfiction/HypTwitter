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

import chx.io.StringOutput;
import chx.log.LogLevel;
import haxe.PosInfos;

/**
	Log to a text file. The class is started with a logging level
**/

#if (neko || cpp || php)

class File extends BaseLogger, implements IEventLog {
	/** the default format for File type loggers */
	public static var defaultFormat : LogFormat = new LogFormat(LogFormat.formatLong);
	var STDOUT 		: chx.io.FileOutput;
	var mutex		: chx.vm.Mutex;

	/**
	*  Logs to the provided file handle. If the handle is null, logging will go
	*  to STDOUT
	**/
	public function new(service: String,  ?level:LogLevel, ?hndFile : chx.io.FileOutput ) {
		super(service, level);
		if(hndFile == null)
			STDOUT = chx.io.File.stdout();
		else
			STDOUT = hndFile;
		this.format = defaultFormat.clone();
		mutex = new chx.vm.Mutex();
		mutex.release();
	}

	override public function log(s : String, ?lvl : LogLevel, ?pos:PosInfos) {
		if(lvl == null)
			lvl = EventLog.defaultLevel;
		if(Type.enumIndex(lvl) >= Type.enumIndex(level)) {
			mutex.acquire();
			var so : StringOutput = new StringOutput();
			format.writeLogMessage(so, this.serviceName, lvl, s, pos);
			try {
				STDOUT.writeString(so.toString() + "\n");
				//STDOUT.write(Bytes.ofString("["+Date.now().toString()+"] " +serviceName + " : "+Std.string(lvl)+" : "+ s + "\n"));
				STDOUT.flush();
			} catch(e:Dynamic) {
				trace(e);
			}
			mutex.release();
		}
	}
	
	override public function close() : Void {
		try {
			STDOUT.close();
		} catch(e:Dynamic) {}
	}
}

#end
