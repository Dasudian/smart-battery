%% @author Barco You <barco@dasudian.com>
%% @copyright 2015 Dasudian
%%
-module(conf).

%% --------------------------------------------------------------------------------------
%% API Function Exports
%% --------------------------------------------------------------------------------------

-export([get_section/1, get_section/2]).
-export([get_val/2, get_val/3, get_mqtt_server/1]).

%% --------------------------------------------------------------------------------------
%% API Function Definitions
%% -------------------------------------------,-------------------------------------------

get_section(Name) ->
    get_section(Name, undefined).

get_section(Name, Default) ->
    {ok, App} = application:get_application(?MODULE),
    %%io:format("App = ~p~n", [App]),
    case application:get_env(App, Name) of
        {ok, V} ->
            V;
        _ ->
            Default
    end.

get_val(SectionName, Name) ->
    get_val(SectionName, Name, undefined).

get_val(SectionName, Name, Default) ->
    {ok, App} = application:get_application(?MODULE),
    case application:get_env(App, SectionName) of
        {ok, Section} ->
            proplists:get_value(Name, Section, Default);
        _ ->
            Default
    end.


get_mqtt_server(Imei) ->
    ServerList = mod_config:get(mqtt_server),
    Len = erlang:length(ServerList),
    Index = erlang:phash(Imei, Len),
    lists:nth(Index, ServerList).