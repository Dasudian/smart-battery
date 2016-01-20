-module(smartBattery_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    ok = mod_config:init(),
    %%maybe new a gen_logger
    application:start(gen_logger),
    %%logger:info("++++++hello+++++"),
    smartBattery_sup:start_link().

stop(_State) ->
    ok.
