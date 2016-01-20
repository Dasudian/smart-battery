-module(erlang_tcp_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    {ok, Port} = application:get_env(smartBattery_tcp, ranch_port),
    {ok, _} = ranch:start_listener(tcp_handler, 100,
        ranch_tcp, [{port, Port}], tcp_protocol, []),

    erlang_tcp_sup:start_link().

stop(_State) ->
    ok.
