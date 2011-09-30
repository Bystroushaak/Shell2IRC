/**
 * Shell to IRC (daemon).
 * 
 * This program listen on selected port and wait for commands. Every command is
 * send to IRC.
 * 
 * Command format:
 *    for msg\n
 * 
 *    'for' could be channel name, or IRC username.
 *    'msg' ends with \n
 * 
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
import std.socket;
import std.string;
import std.algorithm : remove;
import std.getopt;

import frozenidea2; /// https://github.com/Bystroushaak/FrozenIdea2
import read_configuration;


class ShellToIRC : IRCbot{
	private Socket listener;
	private string[][string] on_join_queue;
	
	///
	this(string nickname = "Shell2IRC"){
		super(nickname);
	}
	
	///
	this(string nickname, ushort local_port, string server, ushort irc_port = 6667){
		this(nickname);
		this.connect_shell(local_port, server, irc_port);
	}
	
	/**
	 * Connects server to local port and bot to IRC.
	*/ 
	public void connect_shell(ushort local_port, string server, ushort irc_port = 6667){
		// local connection
		this.listener = new TcpSocket();
		this.listener.blocking = false;
		this.listener.bind(new InternetAddress(local_port));
		listener.listen(10);
		
		this.connect(server, irc_port);
	}
	
	/**
	 * Rewrited run().
	 * 
	 * Now, in run are handled irc and local socket. 
	*/ 
	override public void run(){
		Socket[] local_connections;
		SocketSet chk = new SocketSet();
		
		int read, local_read;
		char buff[1024];
		char local_buff[1024];
		
		int io_endl;
		string msg;
		string msg_queue;
		
		// connection loop
		for (;;chk.reset()){
			chk.add(this.connection);
			chk.add(this.listener);
			foreach(c; local_connections)
				chk.add(c);
			
			// block until change
			Socket.select(chk, null, null);
			
			// new local connections
			if (chk.isSet(this.listener)){
				local_connections ~= listener.accept();
				local_connections[$-1].blocking = false;
			}
			
			// handle local connections
			for (int i = local_connections.length - 1; i >= 0; i--){
				if (!chk.isSet(local_connections[i]))
					continue;
				
				local_read = local_connections[i].receive(local_buff);
				if (local_read != 0 && local_read != Socket.ERROR){
					string local_msg = std.conv.to!string(local_buff[0 .. local_read]);
					
					// parse msg/chan
					string chan = local_msg[0 .. local_msg.indexOf(" ")];
					local_msg = local_msg[chan.length + 1 .. $];
					
					// chan or private msg
					if (chan.startsWith("#")){
						try{
							this.sendMsg(chan, local_msg);
						}catch(Exception){
							this.join(chan);
							this.on_join_queue[chan] ~= local_msg;
						}
					}else
						this.sendPrivateMsg(chan, local_msg);
					
					local_buff.clear();
				}
				
				// close connection or error
				if (local_read == 0 || local_read == Socket.ERROR){
					local_connections[i].close();
					local_connections = local_connections.remove(i);
				}
			}
			
			// irc connection
			if (chk.isSet(this.connection)){
				read = this.connection.receive(buff);
				
				if (read != 0 && read != Socket.ERROR){
					msg_queue ~= cast(string) buff[0 .. read];
					
					// handle messages in queue
					while ((io_endl = msg_queue.indexOf(ENDL)) > 0){
						msg = msg_queue[0 .. io_endl + ENDL.length];
						
						// ping handling
						if (msg.startsWith("PING"))
							this.socketSendLine("PONG " ~ msg.split()[1].strip());
						else{
							this.logic(parseMsg(msg));
						}
						
						// remove message from queue
						if (msg.length <= msg_queue.length - 1)
							msg_queue = msg_queue[msg.length .. $];
						else
							msg_queue = "";
					}
					
					buff.clear();
				}else{
					this.connection.close();
					this.onConnectionClose();
					break;
				}
			}
		}
	}
	
	override public void onServerConnected(){
		writeln("Connected to server.");
	}
	
	override public void onChannelJoin(string chan){
		if (chan in this.on_join_queue)
			foreach(msg; this.on_join_queue[chan])
				this.sendMsg(chan, msg);
	}
}


void printHelp(string progname, ref File o = stderr){
	o.writeln("Usage:");
	o.writeln(
		"\t" ~ progname ~ " [-h, --help, -c, --config]\n\n"
		"\t-c, --config\n"
		"\t\tConfiguration file path.\n\n"
	);
}



int main(string[] args){
	bool help;
	string config;
	Config c;
	
	// parse options
	try{
		getopt(
			args,
			std.getopt.config.bundling,
			"help|h", &help,
			"config|c", &config
		);
	}catch(Exception e){
		writeln(e.msg);
		return -1;
	}
	if (help){
		writeln("Shell to IRC redirector (daemon) by Bystroushaak (bystrousak@kitakitsune.org)\n");
		printHelp(args[0], stdout);
		writeln(args);
		return 0;
	}
	
	
	try{
		if (config != "")
			c = readConfig(config);
		else
			c = readConfig();
	}catch(Exception e){
		stderr.writeln(e.msg);
		return 30;
	}
	
	ShellToIRC s = new ShellToIRC(c.nick);
	
	try{
		s.connect_shell(c.local_port, c.server, c.irc_port);
	}catch(std.socket.AddressException e){
		stderr.writeln(e.msg);
		return 10;
	}catch(std.socket.SocketException e){
		stderr.writeln(e.msg);
		return 20;
	}
	
	s.run();
	
	return 0;
}