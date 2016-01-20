%%%-------------------------------------------------------------------
%%% @author dsd
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 十月 2015 10:54 AM
%%%-------------------------------------------------------------------
-module(lib_topic).
-author("dsd").

%% API
-export([
    get_cmd_topic_a2p/1,
    get_ping_topic_a2p/1,
    get_cmd_topic_p2a/1,
    get_gps_topic_p2a/1,
    get_433_topic_p2a/1,
    get_ping_topic_p2a/1
]).

get_cmd_topic_a2p(ID) ->
    String = "app2dev/" ++ ID ++ "/cmd",
    lib_util:to_binary(String).

get_ping_topic_a2p(ID) ->
    String = "app2dev/" ++ ID ++ "/ping",
    lib_util:to_binary(String).

get_cmd_topic_p2a(ID) ->
    String = "dev2app/" ++ ID ++ "/cmd",
    lib_util:to_binary(String).

get_gps_topic_p2a(ID) ->
    String = "dev2app/" ++ ID ++ "/gps",
    lib_util:to_binary(String).

get_433_topic_p2a(ID) ->
    String = "dev2app/" ++ ID ++ "/433",
    lib_util:to_binary(String).

get_ping_topic_p2a(ID) ->
    String = "dev2app/" ++ ID ++ "/ping",
    lib_util:to_binary(String).
