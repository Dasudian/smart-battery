%%%-------------------------------------------------------------------
%%% @author dsd
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 十月 2015 2:20 PM
%%%-------------------------------------------------------------------
-module(smartBattery_p2a).
-author("dsd").

-include("../include/common.hrl").
-include("../include/protocol_aAp.hrl").
-include("../include/protocol_pAd.hrl").

%% API
-export([
    connect/1,
    cmd_info_from_device/3,
    gps_info_from_db/1,
    gps_info_from_device/3,
    ftt_info_from_db/1,
    ftt_info_from_device/3,

    get_cmd_msg_p2a/2,
    get_gps_msg_p2a/2,
    get_433_msg_p2a/2
]).

-define(MAIN, app_conn_sup).

%% when device connected with tcp  then  it need to call this fuction to connect with mqtt
connect(Imei) ->
    %io:format("+++Device connect~n"),
    try
        TopicA = lib_topic:get_cmd_topic_a2p(Imei),
        TopicPing = lib_topic:get_ping_topic_a2p(Imei),
        Args = [Imei, [TopicA, TopicPing], ?DeviceConnet],
        _Res = supervisor:start_child(?MAIN, [Args]),
        %%io:format("Res = ~p~n",[Res]),
        logger:info("Device connect")
    catch
        _:Why ->
            logger:error("p2a connect error reason:~p tracy :~p",[Why, erlang:get_stacktrace()])
            %%io:format(" p2a connect error reason:~p tracy :~p ~n", [Why, erlang:get_stacktrace()])
    end.


%% device send msg(INFO) to platform then publish it
-spec(cmd_info_from_device(ID :: string(), CMD :: integer(), Info :: list()) -> ok).
cmd_info_from_device(ID, CMD, Info) ->
    case CMD of
        ?CMD_pAd_PING ->
            Pid = lib_util:to_atom("p2a" ++ ID),
            TopicPing = lib_topic:get_ping_topic_p2a(ID),
            Pid ! {pubMsg, TopicPing, <<"ping">>},
            Pid ! {hearBeatUpdate};
        _ ->
            Pid = lib_util:to_atom("p2a" ++ ID),
            Topic = lib_topic:get_cmd_topic_p2a(ID),
            Pid ! {pubMsg, Topic, Info},
            Pid ! {hearBeatUpdate}
    end.


gps_info_from_device(ID, _CMD, Info) ->
    Pid = lib_util:to_atom("p2a" ++ ID),
    TopicGPS = lib_topic:get_gps_topic_p2a(ID),
    Pid ! {pubMsg, TopicGPS, Info}.

ftt_info_from_device(ID, _CMD, Info) ->
    Pid = lib_util:to_atom("p2a" ++ ID),
    Topic433 = lib_topic:get_433_topic_p2a(ID),
    Pid ! {pubMsg, Topic433, Info}.


gps_info_from_db(ID) ->
    Pid = lib_util:to_atom("p2a" ++ ID),
    TopicGPS = lib_topic:get_gps_topic_p2a(ID),
    M = lib_gps:get_latest(ID),
    Msg = lib_json:to_json(M),
    Pid ! {pubMsg, TopicGPS, Msg}.


ftt_info_from_db(ID) ->
    Pid = lib_util:to_atom("p2a" ++ ID),
    Topic433 = lib_topic:get_433_topic_p2a(ID),
    Msg = lib_json:to_json([]),
    Pid ! {pubMsg, Topic433, Msg}.

%% apis for app get msg(send this message to app)
get_cmd_msg_p2a(Payload, State) ->
    io:format("app get msg :~p ~n", [Payload]),
    {State#state.client_id, Payload}.

get_gps_msg_p2a(Payload, State) ->
    io:format("app get gps msg :~p ~n", [Payload]),
    {State#state.client_id, Payload}.

get_433_msg_p2a(Payload, State) ->
    io:format("get 433 from device :~p ~n", [Payload]),
    {State#state.client_id, Payload}.

