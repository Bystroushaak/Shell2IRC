/**
 * Configuration reader
 * 
 * Author:  Bystroushaak (bystrousak@kitakitsune.org)
 * Version: 1.0.0
 * Date:    29.09.2011
 * 
 * Copyright: 
 *     This work is licensed under a CC BY.
 *     http://creativecommons.org/licenses/by/3.0/
*/
import std.file;
import std.stdio;
import std.string;



class Config{
	///
	public ushort local_port;
	///
	public string server;
	///
	public ushort irc_port;
	///
	public string nick;
	
	///
	this(string filename){
		string[] varval;
		
		this.local_port = 2222;
		this.irc_port   = 6667;
		this.nick       = "Shell2IRC";
		
		foreach(string line; lines(File(filename, "r"))){
			if (line.indexOf("#") >= 0){
				if (line.indexOf("#") == 0)
					continue;
				
				line = line[0 .. line.indexOf("#")];
			}
			
			line = line.strip();
			
			if (line.indexOf("=") < 0 || line == "")
				continue;
			
			varval = line.split("=");
			varval[1] = varval[1].strip();
			
			switch(varval[0].toUpper().strip()){
				case "IRC_SERVER":
					this.server = varval[1];
					break;
				case "IRC_PORT":
					try{
						this.irc_port = std.conv.to!ushort(varval[1]);
						
						if (this.irc_port < 1 || this.irc_port > 65535)
							throw new Exception("");
					}catch(Exception){
						throw new Exception("IRC_PORT must be number from 1 to 65535 and not '" ~ varval[1] ~ "'!");
					}
				case "LOCAL_PORT":
					try{
						this.local_port = std.conv.to!ushort(varval[1]);
						
						if (this.local_port < 1 || this.local_port > 65535)
							throw new Exception("");
					}catch(Exception){
						throw new Exception("LOCAL_PORT must be number from 1 to 65535 and not '" ~ varval[1] ~ "'!");
					}
				case "NICK":
					this.nick = varval[1];
					break;
				default:
					break;
			}
		}
		
		if (this.server == "")
			throw new Exception("Variable SERVER must be set!");
	}
	
	string toString(){
		return "Local port: " ~ std.conv.to!string(this.local_port) ~ 
		       "\nServer: " ~ server ~ ":" ~ std.conv.to!string(this.irc_port) ~ "\n";
	}
}


/**
 * Read configuration and return it as instance of Config.
 * 
 * Function looks for FN in ./FN and ~/FN.
*/ 
Config readConfig(string FN = "shell2irc.cfg"){
	string filename;
	
	if (exists("./" ~ FN))
		filename = "./" ~ FN;
	else if (exists(std.path.expandTilde("~/" ~ FN)))
		filename = std.path.expandTilde("~/" ~ FN);
	else
		throw new Exception("Filename not found!");
	
	return new Config(filename);
}