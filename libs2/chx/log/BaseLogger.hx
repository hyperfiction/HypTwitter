package chx.log;

import chx.log.LogLevel;
import haxe.PosInfos;

class BaseLogger implements IEventLog {
	public var format : LogFormat;
	public var serviceName : String;
	public var level : LogLevel;
	
	/**
		Create a logger under the program name [service], which
		will only log events that are greater than or equal to
		LogLevel [level]
	**/
	public function new(service : String, level : LogLevel) {
		if(EventLog.defaultServiceName == null)
			EventLog.defaultServiceName = service;
		if(EventLog.defaultLevel == null)
			EventLog.defaultLevel = LogLevel.NOTICE;
		this.serviceName = service;
		this.level = level;
		this.format = new LogFormat(LogFormat.formatLong);
	}
	
	/**
	 * Adds this logger to the chain of event loggers, only if it does not
	 * yet exist.
	 */
	public function addToLogChain():Void {
		EventLog.add(this);
	}
	
	/**
	 * Closes this logger
	 */
	public function close():Void {
	}
	
	public inline function debug(s:String, ?pos:PosInfos) : Void { log(s,DEBUG, pos); }
	public inline function info(s:String, ?pos:PosInfos) : Void { log(s,INFO, pos); }
	public inline function notice(s : String, ?pos:PosInfos) : Void { log(s,NOTICE, pos); }
	public inline function warn(s : String, ?pos:PosInfos) : Void { log(s,WARN, pos); }
	public inline function error(s : String, ?pos:PosInfos) : Void { log(s,ERROR, pos); }
	public inline function critical(s : String, ?pos:PosInfos) : Void { log(s,CRITICAL, pos); }
	public inline function alert(s : String, ?pos:PosInfos) : Void { log(s,ALERT, pos); }
	public inline function emerg(s : String, ?pos:PosInfos) : Void { log(s, EMERG, pos); }
	
	
	public function log(s : String, ?lvl:LogLevel, ?pos:PosInfos) : Void {
		throw "Override";
	}
}