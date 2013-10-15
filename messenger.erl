% Please do not put debug codes unceremonious, cause this is erlang, and if you do things like that, you will get    bitten
-module(messenger).                                                             
-export([start_svr/0, svr/0, logon/1, logoff/0, message/2, client/2]).          
                                                                                
svr_node() ->                                                                   
    messenger@QBHadoop1.                                                           
                                                                                   
svr() ->                                                                           
    process_flag(trap_exit, true),                                                 
    svr([]).                                                                       
                                                                                   
svr(User_List) ->                                                                  
    receive                                                                        
        {From, logon, Name} ->                                                     
            New_User_List = svr_logon(From, Name, User_List),                      
            svr(New_User_List);                                                    
        {'EXIT', From, _} ->                                                       
            New_User_List = svr_logoff(From, User_List),                           
            svr(New_User_List);                                                    
        %{From, logoff} ->                                                         
        %    New_User_List = svr_logoff(From, User_List),                          
        %    svr(New_User_List);                                                   
        {From, message_to, To, Message} ->                                         
            svr_transfer(From, To, Message, User_List),                            
            io:format("list is now: ~p~n", [User_List]),                           
            svr(User_List)                                                         
    end.                                                                           
                                                                                   
start_svr() ->                                                                     
    register(messenger, spawn(messenger, svr, [])).                                
                                                                                   
svr_logon(From, Name, User_List) ->                                                
    case lists:keymember(Name, 2, User_List) of                                    
        true ->                                                                    
            From ! {messenger, stop, user_exists_at_other_node},                   
            User_List;                                                             
        false ->                                                                   
            From ! {messenger, logged_on},                                         
            link(From),                                                            
            io:format("~w login ~n", [Name]),                                      
            [{From, Name} | User_List]                                             
    end.                                                                           
                                                                                   
svr_logoff(From, User_List) ->                                                     
    io:format("~w logoff~n", [From]),                                              
    lists:keydelete(From, 1, User_List).                                           
                                                                                   
svr_transfer(From, To, Message, User_List) ->                                      
    %io:format("~w, ~w~n", [From, lists:keysearch(From, 1, User_List)]),           
    case lists:keysearch(From, 1, User_List) of                                    
            false ->                                                               
                From ! {messenger, stop, you_are_offline};                         
            {value, {From, Name}} ->                                               
                svr_transfer(From, Name, To, Message, User_List)                   
        end.                                                                       
                                                                                   
svr_transfer(From, Name, To, Message, User_List) ->                                
    %io:format("from ~w, to ~w, ~w~n", [From, To, lists:keysearch(To, 2, User_List)]),
    case lists:keysearch(To, 2, User_List) of                                      
        false ->                                                                   
            From ! {messenger, receiver_not_found};                                
                                                                                   
        {value, {ToPid, To}} ->                                                    
            ToPid ! {message_from, Name, Message},                                 
            From ! {messenger, sent}                                               
    end.                                                                           
                                                                                   
logon(Name) ->                                                                     
    case whereis(mess_client) of                                                   
        undefined ->                                                               
            register(mess_client,                                                  
                spawn(messenger, client, [svr_node(), Name]));                     
            _ ->                                                                   
                already_logged_on                                                  
        end.                                                                       
                                                                                   
logoff() ->                                                                        
    mess_client ! logoff.                                                          
                                                                                   
message(ToName, Message) ->                                                        
    case whereis(mess_client) of                                                   
        undefined ->                                                               
            not_logged_on;                                                         
        _ ->                                                                       
            mess_client ! {message_to, ToName, Message},                           
            ok                                                                     
    end.                                                                           
                                                                                   
client(Server_Node, Name) ->                                                       
    % open it to listen server's exit message                                      
    process_flag(trap_exit, true),                                                 
    {messenger, Server_Node} ! {self(), logon, Name},                              
    await_result(),                                                                
    client(Server_Node).                                                           
                                                                                   
client(Server_Node) ->                                                             
    receive                                                                        
        logoff ->                                                                  
            %{messenger, Server_Node} ! {self(), logoff},                          
            exit(normal);                                                          
        {message_to, ToName, Message} ->                                           
            {messenger, Server_Node} ! {self(), message_to, ToName, Message},   
            await_result();                                                        
        {message_from, FromName, Message} ->                                       
            io:format("Messag from ~p: ~p~n", [FromName, Message]);                
        {'EXIT', From, _} ->                                                       
            io:format("svr offline now!~n", []),                                   
            exit(normal)                                                           
    end,                                                                           
    client(Server_Node).  
    
  await_result() ->                                                                  
    receive                                                                        
        {messenger, stop, Why} ->                                                  
            io:format("~p~n", [Why]),                                              
            exit(normal);                                                          
        {messenger, What} ->                                                       
            io:format("~p~n", [What])                                           
    after 5000 ->                                                               
            io:format("No response from server~n", []),                         
            exit(timeout)                                                       
    end. 
