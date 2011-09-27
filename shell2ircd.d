/**
 * Shell to IRC redirector. 
*/ 


import std.stdio;
import std.socket;
import std.string;
import std.algorithm : remove;
import std.getopt;

import frozenidea2;



class ShellToIRC : IRCbot{
	private Socket listener;
	
	this(string nickname){
		super(nickname);
	}
	
	public void connect_shell(ushort local_port, string server, ushort irc_port = 6667){
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
					// local queue :S - ta to fixne
					
					try{
						this.sendMsg("#testchan", local_msg);
					}catch(Exception){
						this.join("#testchan");
						this.sendMsg("#testchan", local_msg);
					}
					
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
}


void printHelp(string progname, ref File o = stderr){
	o.writeln("Usage:");
	o.writeln(
		"\t" ~ progname ~ " [-h, -n, --nick] LOCAL_PORT IRC_SERVER IRC_PORT\n\n"
		"\t-n, --nick\n"
		"\t\tBot nick. Default is FrozenIdea2.\n\n"
		"\tLOCAL_PORT\n"
		"\t\tLocal port where daemon wait for commands.\n\n"
		"\tIRC_SERVER\n"
		"\t\tIRC server. SSL is not supported.\n\n"
		"\tIRC_PORT\n"
		"\t\tIRC port.\n\n"
	);
}



int main(string[] args){
	bool help;
	string nick = "FrozenIdea2";
	ushort local_port, irc_port;
	string server;
	
	// parse options
	try{
		getopt(
			args,
			std.getopt.config.bundling,
			"help|h", &help,
			"nick|n", &nick
		);
	}catch(Exception e){
		writeln(e.msg);
		return -1;
	}
	if (help){
		writeln("Shell to IRC redirector Daemon by Bystroushaak (bystrousak@kitakitsune.org)\n");
		printHelp(args[0], stdout);
		writeln(args);
		return 0;
	}	
	if (args.length != 4){
		stderr.writeln("You have to specify all position arguments!");
		return 1;
	}
	try{
		local_port = std.conv.to!ushort(args[1]);
		
		if (local_port < 1 || local_port > 65535)
			throw new Exception("");
	}catch(Exception){
		stderr.writeln("LOCAL_PORT must be number from 1 to 65535 and not '" ~ args[1] ~ "'!");
		return 2;
	}
	try{
		irc_port = std.conv.to!ushort(args[3]);
		
		if (irc_port < 1 || irc_port > 65535)
			throw new Exception("");
	}catch(Exception){
		stderr.writeln("IRC_PORT must be number from 1 to 65535 and not '" ~ args[3] ~ "'!");
		return 3;
	}
	
	ShellToIRC s = new ShellToIRC(nick);
	
	try{
		s.connect_shell(local_port, args[2], irc_port);
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