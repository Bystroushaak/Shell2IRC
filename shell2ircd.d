import std.stdio;
import std.socket;
import std.string;
import std.algorithm : remove;

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
					// local queue :S
					
					this.sendMsg("#testchan", local_msg);
					
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
	
	public void onServerConnected(){
		this.join("#testchan");
	}
}

void main(){
	ShellToIRC s = new ShellToIRC("FrozenIdea2");
	s.connect_shell(2222, "irc.2600.net");
	s.run();
}