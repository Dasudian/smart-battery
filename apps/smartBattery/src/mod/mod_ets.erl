%%%-------------------------------------------------------------------
%%% @author dasudian
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. Jul 2015 2:12 PM
%%%-------------------------------------------------------------------
-module(mod_ets).
-author("dasudian").

-include_lib("stdlib/include/ms_transform.hrl").

-include("common.hrl").

%% API
-export([
    init/0,
    connect/1,
    get_connection/1,
    disconnected/1
]).

init() ->
    ets:new(?ConnectTable, [public, named_table, set, {keypos, #connetInfo.id}]).

connect(R) ->
    ets:insert(?ConnectTable, R).

get_connection(ID) ->
    case ets:lookup(?ConnectTable, ID) of
        [] -> #connetInfo{};
        [R] -> R
    end.

disconnected(ID) ->
    ets:delete(?ConnectTable, ID).

%% app_connect(R) ->
%%     ets:insert(?AppConnectTable, R).
%%
%% device_connect(R) ->
%%     ets:insert(?DeviceConnectTable, R).
%%
%% check_app_connection(ID) ->
%%     ets:lookup(?AppConnectTable, ID).
%%
%% check_device_connection(ID) ->
%%     case ets:lookup(?DeviceConnectTable, ID) of
%%         [] -> #connetInfo{};
%%         [R] -> R
%%     end.