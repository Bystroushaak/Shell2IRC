/**
 * Shell to IRC (client).
 * 
 * Author:  Bystroushaak (bystrousak@kitakitsune.org)
 * Version: 0.0.1
 * Date:    29.09.2011
 * 
 * Copyright: 
 *     This work is licensed under a CC BY.
 *     http://creativecommons.org/licenses/by/3.0/
*/
import std.stdio;
import std.getopt;
import std.socket;



void printHelp(string progname, ref File o = stderr){
	o.writeln(
		"Usage:\n"
		"\t" ~ progname ~ " [-h, --help, -m, --msg] -t TO\n\n"
		"\t-t, --to\n"
		"\t\tMessage recipient. Could be chan or user (sent as PM).\n\n"
		"Optional parameters:\n"
		"\t-m, --msg\n"
		"\t\tMessage. If not set, message is readed from stdin.\n\n"
		"\t-h, --help\n"
		"\t\tPrint this help.\n"
	);
}


int main(string[] args){
	bool help;
	string to;
	string msg;
	
	try{
		getopt(
			args,
			std.getopt.config.bundling,
			"help|h", &help,
			"to|t", &to,
			"msg|m", &msg
		);
	}catch(Exception e){
		printHelp(args[0]);
		return 1;
	}
	if (help){
		writeln("Shell to IRC redirector (client) by Bystroushaak (bystrousak@kitakitsune.org)\n");
		printHelp(args[0], stdout);
		return 0;
	}
	if (to == ""){
		stderr.writeln("TO parameter must be set!");
		return 2;
	}
	
	// read message from stdin
	if (msg == ""){
	}
	
	return 0;
}