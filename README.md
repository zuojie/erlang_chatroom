erlang_chatroom
===============

This is a chat room example from  ***Erlang/OTP R11B documentation***.    
It is executable totally.    
The step comes follows if you want to hack it:   
* compile the messenger.erl(**c(mesenger).**), and copy the messenger.beam to all of the nodes you own
* choose one node as your chat room server, type command **messenger:start_svr().**
* type the command **messenger:logon(node_a).** on the other nodes to login
* if you want to send message to node_b, type **messenger:message(node_b, "Hi node b, how are you").**
* if you want to log off, just type **messenger:logoff().**
* Remeber that you have to put the same .erlang.cookie file in all of the nodes above, 
it  have to be put into your home directory.

Happy hack.


