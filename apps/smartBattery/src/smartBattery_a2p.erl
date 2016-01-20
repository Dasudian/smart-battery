%%%-------------------------------------------------------------------
%%% @author dsd
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 十月 2015 下午2:51
%%%-------------------------------------------------------------------
-module(smartBattery_a2p).
-author("dsd").

-include("common.hrl").
-include("msg_code.hrl").
-include("protocol_pAd.hrl").
-include("protocol_aAp.hrl").
%% API

-export([connect/1, command/2, command_cmd_a2p/2]).

-define(MAIN, app_conn_sup).

connect(Imei) ->
    TopicCMD = lib_topic:get_cmd_topic_p2a(Imei),
    TopicGPS = lib_topic:get_gps_topic_p2a(Imei),
    Topic433 = lib_topic:get_433_topic_p2a(Imei),
    TopicPing = lib_topic:get_ping_topic_p2a(Imei),
    Args = [Imei, [TopicCMD, TopicGPS, Topic433, TopicPing], ?AppConnect],
    _Res = supervisor:start_child(?MAIN, [Args]),
    logger:info("App connect").

-spec command(string(),integer())->boolean().
%% apis for app
command(ID, Cmd) ->
    Pid = lib_util:to_atom("a2p" ++ ID),
    TopicCMD = lib_topic:get_cmd_topic_a2p(ID),
    Msg = lib_json:to_json([{cmd, Cmd}]),
    Pid ! {pubMsg, TopicCMD, Msg}.

%%ping(ID) ->
%%    Pid = lib_util:to_atom("a2p" ++ ID),
%%    TopicPing = lib_topic:get_ping_topic_a2p(ID),
%%    Pid ! {pubMsg, TopicPing, <<"ping">>}.

%% interface from tcp
send_cmd_to_device_by_tcp(ID, Info) ->
    tcp_protocol:do_cmd_to_device(ID, Info),
    ok.


%% get app msg
command_cmd_a2p(Payload, State) ->
    ID = State#state.client_id,
    %%Login = State#state.loginState,
    Data = lib_json:from_json(Payload),
    Cmd = proplists:get_value(<<"cmd">>, Data),
    do_cmd_a2p(Cmd, ID).

do_cmd_a2p(Cmd, ID) ->
    Info = switch(Cmd),
    case Info of
        skip ->
            skip;
        _ ->
            send_cmd_to_device_by_tcp(ID, Info)
    end.

switch(R) ->
    case R of
        ?CMD_aAp_FENCE_ON ->
            {?CMD_pAd_DEFEND, 1};       %% "DEFEND_ON"
        ?CMD_aAp_FENCE_OFF ->
            {?CMD_pAd_DEFEND, 0};       %% "DEFEND_OFF"
        ?CMD_aAp_FENCE_GET ->
            {?CMD_pAd_DEFEND, 2};       %% "DEFEND_GET"
        ?CMD_aAp_SEEK_ON ->
            {?CMD_pAd_SEEK, 1};         %% "SEEK_ON"
        ?CMD_aAp_SEEK_OFF ->
            {?CMD_pAd_SEEK, 0};         %% "SEEK_OFF"
        ?CMD_aAp_LOCATION ->
            {?CMD_pAd_LOCATION, 0};
        _ ->
            skip
    end.


