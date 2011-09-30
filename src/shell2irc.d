/**
 * Shell to IRC (client).
 * 
 * Author:  Bystroushaak (bystrousak@kitakitsune.org)
 * Version: 1.0.0
 * Date:    30.09.2011
 * 
 * Copyright: 
 *     This work is licensed under a CC BY.
 *     http://creativecommons.org/licenses/by/3.0/
*/
import std.stdio;
import std.getopt;
import std.string;
import std.socket;

import read_configuration;


void printHelp(string progname, ref File o = stderr){
	o.writeln(
		"Usage:\n"
		"\t" ~ progname ~ " [-h, --help, -m, --msg, -c, --config] -t TO\n\n"
		"\t-t, --to\n"
		"\t\tMessage recipient. Could be chan or user (sent as PM).\n\n"
		"Optional parameters:\n"
		"\t-m, --msg\n"
		"\t\tMessage. If not set, message is readed from stdin.\n\n"
		"\t-h, --help\n"
		"\t\tPrint this help.\n\n"
		"\t-c, --config\n"
		"\t\tConfiguration file. If not set, program expects shell2irc.cfg\n"
		"\t\tin ./, or in ~.\n"
	);
}


int main(string[] args){
	bool help;
	string to;
	string msg;
	string config;
	Config c;
	
	// parse options
	try{
		getopt(
			args,
			std.getopt.config.bundling,
			"help|h", &help,
			"to|t", &to,
			"msg|m", &msg,
			"config|c", &config
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
	
	// read configuration
	try{
		if (config != "")
			c = readConfig(config);
		else
			c = readConfig();
	}catch(Exception e){
		stderr.writeln(e.msg);
		return 30;
	}
	
	// Create connection to local server
	TcpSocket s;
	try{
		s = new TcpSocket(AddressFamily.INET);
		s.connect(new InternetAddress("127.0.0.1", c.local_port));
	}catch(Exception e){
		stderr.writeln(e.msg);
		stderr.writeln("You have to start shell2irc daemon first!");
		return 40;
	}
	
	// if message is not set as parameter, read it from stdin
	if (msg == ""){
		foreach(string line; lines(stdin))
			foreach(line_part; line.wrap(510).splitLines())
				s.send(to ~ " " ~ line_part.stripRight() ~ "\n");
	}else{
		foreach(line_part; msg.wrap(510).splitLines())
			s.send(to ~ " " ~ line_part.stripRight() ~ "\n");
	}
	
	s.close();
	
	return 0;
}