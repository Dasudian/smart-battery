-module(client).

-include("mod_d2p.hrl").

-export([
	connect/1,
	send/0
	]).

connect(Imei) ->
	Host = "localhost",
	B = list_to_binary(Imei),
	BinMsg = <<16#aa55:16,1:16,1:16,8:16,B/binary>>,
    {ok, Sock} =
    	gen_tcp:connect(Host, 8008, [binary]),
    ok = gen_tcp:send(Sock, BinMsg),
    io:format("  client socket :~p ~n",[Sock]),
    receive
    	{tcp, Socket, String} ->
        	io:format("Client received = ~p  socket :~p ~n",[String, Socket])
%%             B = <<16#aa55:16,2:16,1:16,8:16,"123345">>,
%%             gen_tcp:send(Sock, B)
      	after 16000 ->
            exit
   	end.

send() ->
    BinMsg = <<16#aa55:16,7:16,1:16,8:16, 123>>,
    S = ets:lookup_element(?TAB_CONNINFO, "100", #conninfo.socket),
    ranch_tcp:send(S, BinMsg).


%% <<170,85,0,2,0,1,0,8,64,94,217,153,153,153,153,154,64,69,153,153,153,153,153,154>>  gpsinfo