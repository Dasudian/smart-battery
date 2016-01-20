-module(mod_d2p).
-define(DEFEND_ON, 0).
-define(DEFEND_OFF, 1).
-define(DEFEND_GET, 2).
-define(SEEK_ON, 1).
-define(SEEK_OFF, 0).

-include("../include/mod_d2p.hrl").

%% API
-export([
    process_login/2,
    process_gps/2,
    process_cell/2,
    process_ping/2,
    process_alarm/2,
    process_sms/2,
    process_433/2,
    process_defend/2,
    process_seek/2,
    process_location/2,
    process_server/2,
    process_timer/2,
    do_login/2,
    do_msg/3
]).
%%% ==================================================================
%%% API
%%% ==================================================================

do_login(Msg, State) ->
    mod_d2p:process_login(Msg, State).

do_msg(CMD, Msg, Imei) ->
    try
        case CMD of
            ?CMD_GPS ->
                mod_d2p:process_gps(Msg, Imei);
            ?CMD_CELL ->
                mod_d2p:process_cell(Msg, Imei);
            ?CMD_PING ->
                mod_d2p:process_ping(Msg, Imei);
            ?CMD_ALARM ->
                mod_d2p:process_alarm(Msg, Imei);
            ?CMD_SMS ->
                mod_d2p:process_sms(Msg, Imei);
            ?CMD_433 ->
                mod_d2p:process_433(Msg, Imei);
            ?CMD_DEFEND ->
                mod_d2p:process_defend(Msg, Imei);
            ?CMD_SEEK ->
                mod_d2p:process_seek(Msg, Imei);
            ?CMD_LOCATION ->
                mod_d2p:process_location(Msg, Imei);
            ?CMD_SERVER ->
                mod_d2p:process_server(Msg, Imei);
            ?CMD_TIMER ->
                mod_d2p:process_timer(Msg, Imei);
            _ ->
                skip
        end
    catch
        _:Why ->
            io:format("module mod_d2p crash reason :~p  tracy:~p ~n", [Why, erlang:get_stacktrace()])
    end.


%% ------------------   device to platform    ------------------------

process_login(Msg, State) ->
    IMEI = lib_util:to_list(Msg),
    ListOfResult = ets:lookup(?TAB_CONNINFO, IMEI),
    if ListOfResult =:= [] ->
        %% set device state online in the ets table.
        %% 0-offline   1-online
        ets:insert(?TAB_CONNINFO, #conninfo{imei = IMEI, state = 1, tcp_pid = self(), socket = State#state.socket}),
        smartBattery_p2a:connect(IMEI);
        true ->
            skip
    end,
    State#state{loginState = 1}.

process_gps(Msg, Imei) ->
    [Lat, Lng] = tcp_parse:unpack_gps(Msg),
    Data = [{timestamp, timestamp()}, {lat, Lat}, {lng, Lng}],

    %% call sb_riak:put_location().
    Data2riak = {Lat,Lng},
    ID = lib_util:to_binary(Imei),
    sb_riak:put_location(ID,Data2riak),

    Message = lib_json:to_json(Data),
    smartBattery_p2a:gps_info_from_device(Imei, ?CMD_GPS, Message).


process_cell(Msg, Imei) ->
    Data2riak = tcp_parse:unpack_cell_binary(Msg),
    ID = lib_util:to_binary(Imei),
    %% call sb_riak:put_location().
    sb_riak:put_location(ID,Data2riak).

process_ping(_Msg, _Imei) ->
    ok.

process_alarm(_Msg, _Imei) ->
    ok.
    %% do process with alarm type
%%    smartBattery_p2a:cmd_info_from_device(Imei, ?CMD_ALARM, Msg).

process_sms(_Msg, _Imei) ->
    ok.

process_433(Msg, Imei) ->
    <<S/integer>> = Msg,
    Data = [{timestamp, timestamp()}, {intensity, S}],
    Message = lib_json:to_json(Data),
    smartBattery_p2a:ftt_info_from_device(Imei, ?CMD_433, Message).

process_defend(Msg, Imei) ->
    <<Token:32, Result:8>> = Msg,
    Data =
        case Token of
            ?DEFEND_ON ->
                [{cmd, ?CMD_aAp_FENCE_ON}, {result, Result}];
            ?DEFEND_OFF ->
                [{cmd, ?CMD_aAp_FENCE_OFF}, {result, Result}];
            ?DEFEND_GET ->
                [{cmd, ?CMD_aAp_FENCE_GET, {result, Result}}]
        end,
    Message = lib_json:to_json(Data),
    smartBattery_p2a:cmd_info_from_device(Imei, ?CMD_DEFEND, Message).

process_seek(Msg, Imei) ->
    <<Token:32, Result:8>> = Msg,
    Data =
        case Token of
            ?SEEK_OFF ->
                [{cmd, ?CMD_aAp_SEEK_OFF}, {result, Result}];
            ?SEEK_ON ->
                [{cmd, ?CMD_aAp_SEEK_ON}, {result, Result}]
        end,
    Message = lib_json:to_json(Data),
    smartBattery_p2a:cmd_info_from_device(Imei, ?CMD_SEEK, Message).

process_location(Msg, Imei) ->
    [Lat, Lng] = tcp_parse:unpack_location(Msg),
    Data = [{timestamp, timestamp()}, {lat, Lat}, {lng, Lng}],
    %% call sb_riak:put_location().
    Data2riak = {Lat,Lng},
    sb_riak:put_location(Imei,Data2riak),

    Message = lib_json:to_json(Data),
    %% send location info to app
    smartBattery_p2a:gps_info_from_device(Imei, ?CMD_GPS, Message).

process_server(Msg, Imei) ->
    {_Port, _Server} = Msg,
    _Imei = Imei.

process_timer(Msg, Imei) ->
    _Timer = Msg,
    _Imei = Imei.
%%% ==================================================================
%%% INTERNAL FUNCTIONS
%%% ==================================================================

timestamp() ->
    {M, S, _} = os:timestamp(),
    M * 1000000 + S.


