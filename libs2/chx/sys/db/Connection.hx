package chx.sys.db;

interface Connection {

	function request( s : String ) : ResultSet;
	function close() : Void;
	function escape( s : String ) : String;
	function quote( s : String ) : String;
	function addValue( s : StringBuf, v : Dynamic ) : Void;
	function lastInsertId() : Int;
	function dbName() : String;
	function startTransaction() : Void;
	function commit() : Void;
	function rollback() : Void;

}
