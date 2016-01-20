%%%-------------------------------------------------------------------
%%% @author dasudian
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 十月 2015 下午9:00
%%%-------------------------------------------------------------------
-module(smartBattery_SUITE).
-author("dasudian").
-compile([export_all]).
%% API
-export([]).
-include_lib("common_test/include/ct.hrl").
-define(WEB_TIMEOUT,5000).
suite() ->
    [{timetrap,{minutes,10}}, {silent_connections,[telnet,ssh]}, {userdata,[{info,"This suite test smartBattery."}]}].

init_per_suite(Config)->
    code:add_path("/home/dasudian/Proj/smart_battery/apps/smartBattery_tcp/ebin/"),
    code:add_path("/home/dasudian/Proj/smart_battery/apps/smartBattery/ebin/"),
    application:ensure_all_started(ssl),
    application:ensure_all_started(inets),
    application:start(dsd_riak),
    Rusult = application:ensure_all_started(smartBattery),
    io:format("Rusult = ~p~n",[Rusult]),
    Config.

end_per_suite(_Config)->
    application:stop(ranch),
    application:stop(smartBattery),
    application:stop(smartBattery_tcp),
    application:stop(cowboy),
    application:stop(cowlib),
    application:stop(crypto),
    application:stop(emqttc),
    application:stop(jsonx),
    application:stop(pooler),
    application:stop(riakc),
    application:stop(riak_pb),
    application:stop(protobuffs),
    application:stop(dsd_riak),
    application:stop(lager),
    application:stop(goldrush),
    application:stop(compiler),
    application:stop(syntax_tools),
    application:stop(ssl),
    application:stop(inets),
    ok.
init_per_testcase(_Case,Config) ->
    Config.
end_per_testcase(_Case,_Config) ->
    ok.

init_per_group(Config) ->
    Config.
end_per_group(_Config) ->
    ok.

groups() ->
     %% Both app and dev conn,check the infomation.
    [{dev_app_conn,[parallel],[dev_connect,app_connect]},
     %% Both app and dev conn,app send cmd to dev.
     {app_send_cmd_to_dev,[sequence],[dev_online,app_connect_send_cmd]},
     %% Only app conn,try to send cmd to dev.
     {app_conn_send_cmd,[sequence],[app_connect_send_cmd]},
     %% Both app and dev online,app request GPS info.
     {app_request_gps_info,[sequence],[dev_online,app_connect,app_request_gps]},

     {app_send_cmd_all,[sequence],[dev_connect,app_connect,app_command_all]},
     %% dev timeout in 10*60*1000
     {device_timeout,[sequence],[app_connect,dev_timeout]},

     {app_dev_ping,[sequence],[dev_connect,app_ping]}
    ].

all()->
    %%[{group,app_dev_ping}].
    [
        {group,dev_app_conn},
        {group,app_send_cmd_to_dev},
        dev_send_gps,
        dev_send_433,
        %{group,app_conn_send_cmd},
        %{group,app_request_gps_info},
        {group,app_dev_ping},
        %dev_send_433,
        app_command_all
        %dev_send_gps
        %dev_online,
        %app_connect_send_cmd
    ].

dev_connect(Config) ->
    Imei = ct:get_config(imei,Config),
    smartBattery_p2a:connect(Imei).
app_connect(Config) ->
    Imei = ct:get_config(imei,Config),
    smartBattery_a2p:connect(Imei).
dev_online(Config) ->
    Imei = ct:get_config(imei,Config),
    Ip = ct:get_config(ip,Config),
    Port = ct:get_config(port,Config),
    B = list_to_binary(Imei),
    BinMsg = <<16#aa55:16,1:16,1:16,8:16,B/binary>>,
    {ok, Sock} = gen_tcp:connect(Ip, Port, [binary]),
    ok = gen_tcp:send(Sock, BinMsg).
    %%smartBattery_p2a:connect(Imei).

app_connect_use_http(Config)->
    io:format("self()==~p~n",[self()]),
    io:format("Inside app_connect~n",[]),
    Imei = ct:get_config(imei, Config),
    Id = ct:get_config(appid,Config),
    Key = ct:get_config(key,Config),
    Token  = dsd_auth_util:hash_to_string(crypto:hmac(sha, dsd_auth_util:to_list(Key),"DSD" ++ "Flying" ++ dsd_auth_util:to_list(Imei))),
    Data = [{appID,dsd_auth_util:to_binary(Id)},{token,dsd_auth_util:to_binary(Token)},{imei,dsd_auth_util:to_binary(Imei)}],
    Json = jsonx:encode({Data}),
    io:format("This is the configuration read from file with value=~p~n",[Imei]),
    Result =  httpc:request(post, {"https://localhost:8443/verify", [], "application/json", Json}, [{ssl, [{verify, 0}]}, {timeout, ?WEB_TIMEOUT}], []),
    io:format("R = ~p~n",[Result]).


app_connect_send_cmd(Config)->
    Imei = ct:get_config(imei, Config),
    smartBattery_a2p:connect(Imei),
    Cmd = ct:get_config(cmd_from_app, Config),
    smartBattery_a2p:command(Imei,dsd_auth_util:to_binary(Cmd)).

%%app_request_gps(Config) ->
%%    ID = ct:get_config(imei,Config),
%%    Cmd = ct:get_config(cmd_gps,Config),
%%    smartBattery_a2p:command(ID,Cmd).
%%
%%app_get_cell(Config) ->
%%    ID = ct:get_config(imei,Config),
%%    Cmd = ct:get_config(cmd_gps,Config),
%%    smartBattery_a2p:command(ID,Cmd),
%%    Message = "cell info",
%%    smartBattery_p2a:cmd_info_from_device(ID, Cmd, Message).

app_command_all(Config) ->
    Imei = ct:get_config(imei,Config),
    smartBattery_p2a:connect(Imei),
    io:format("1. Device connected~n",[]),
    smartBattery_a2p:connect(Imei),
    io:format("2. App connected~n",[]),
    %%%%%%%
    Cmd_wild = ct:get_config(cmd_wild,Config),
    smartBattery_a2p:command(Imei,Cmd_wild),
    io:format("3. App sends command to dev ~p~n",[Cmd_wild]),

    Cmd_fence_on = ct:get_config(cmd_fence_on,Config),
    smartBattery_a2p:command(Imei,Cmd_fence_on),
    io:format("4. App sends command to dev ~p~n",[Cmd_fence_on]),

    Cmd_fence_off = ct:get_config(cmd_fence_off,Config),
    smartBattery_a2p:command(Imei,Cmd_fence_off),

    Cmd_fence_get = ct:get_config(cmd_fence_get,Config),
    smartBattery_a2p:command(Imei,Cmd_fence_get),

    Cmd_seek_on = ct:get_config(cmd_seek_on,Config),
    smartBattery_a2p:command(Imei,Cmd_seek_on),

    Cmd_seek_off = ct:get_config(cmd_seek_off,Config),
    smartBattery_a2p:command(Imei,Cmd_seek_off),

    Cmd_location = ct:get_config(cmd_location,Config),
    smartBattery_a2p:command(Imei,Cmd_location).

dev_timeout(Config) ->
    Timeout = ct:get_config(timeout,Config),
    Imei = ct:get_config(imei,Config),
    Ip = ct:get_config(ip,Config),
    Port = ct:get_config(port,Config),
    B = list_to_binary(Imei),
    BinMsg = <<16#aa55:16,1:16,1:16,8:16,B/binary>>,
    {ok, Sock} = gen_tcp:connect(Ip, Port, [binary]),
    ok = gen_tcp:send(Sock, BinMsg),
    sleep(Timeout).


sleep(T) ->
    receive
    after T ->
        true
    end.

app_ping(Config) ->
    io:format("self()==~p~n",[self()]),
    Imei = ct:get_config(imei, Config),
    Id = ct:get_config(appid,Config),
    Key = ct:get_config(key,Config),
    Token  = dsd_auth_util:hash_to_string(crypto:hmac(sha, dsd_auth_util:to_list(Key),"DSD" ++ "Flying" ++ dsd_auth_util:to_list(Imei))),
    Data = [{appID,dsd_auth_util:to_binary(Id)},{token,dsd_auth_util:to_binary(Token)},{imei,dsd_auth_util:to_binary(Imei)}],
    io:format("Data=====~p~n",[Data]),
    Json = jsonx:encode({Data}),
    io:format("This is the configuration read from file with value=~p~n",[Imei]),
    Result =  httpc:request(post, {"https://localhost:8443/verify", [], "application/json", Json}, [{ssl, [{verify, 0}]}, {timeout, ?WEB_TIMEOUT}], []),
    io:format("R = ~p~n",[Result]),
    smartBattery_a2p:ping(Imei).

dev_send_gps(Config) ->
    Imei = ct:get_config(imei,Config),
    io:format("1. -------~n"),
    B = list_to_binary(Imei),
    BinMsg = <<16#aa55:16,1:16,1:16,8:16,B/binary>>,
    io:format("2. -------~n"),
    Ip = ct:get_config(ip,Config),
    Port = ct:get_config(port,Config),
    {ok,Sock} = gen_tcp:connect(Ip, Port, [binary]),
    ok = gen_tcp:send(Sock,BinMsg),
    smartBattery_a2p:connect(Imei),
    %smartBattery_a2p:command(Imei,)
    %M = lib_json:to_json([{lat, 99.99}, {lng, 88.78}]),
    Lat = 11.11,
    Lng = 22.22,
    M = <<16#aa55:16,2:16,1:16,8:16,Lat/float,Lng/float>>,
    io:format("3. -------~n"),
    ok = gen_tcp:send(Sock,M).

dev_send_433(Config) ->
    Imei = ct:get_config(imei,Config),
    io:format("1. -------~n"),
    B = list_to_binary(Imei),
    BinMsg = <<16#aa55:16,1:16,1:16,8:16,B/binary>>,
    io:format("2. -------~n"),
    Ip = ct:get_config(ip,Config),
    Port = ct:get_config(port,Config),
    {ok,Sock} = gen_tcp:connect(Ip, Port, [binary]),
    ok = gen_tcp:send(Sock,BinMsg),
    smartBattery_a2p:connect(Imei),
    Sigstr = 1,
    M = <<16#aa55:16,7:16,1:16,8:16,Sigstr:32>>,
    io:format("3. -------~n"),
    ok = gen_tcp:send(Sock, M).



