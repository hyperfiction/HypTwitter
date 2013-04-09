package system;

#if php
typedef Sys = php.Sys;
#elseif neko
typedef Sys = neko.Sys;
#end