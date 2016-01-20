-module(smartBattery_sup).

-behaviour(supervisor).

-include("common.hrl").

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1, stop/0]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

%% init([]) ->
%%     mod_ets:init(),
%%     Restart_strategy = {simple_one_for_one, 5, 10},
%%     Childspec = [{?SMARTBATTERYMAIN, {?SMARTBATTERYMAIN, start_link, []}, transient, 5000, worker, [?SMARTBATTERYMAIN]}],
%%     {ok, {Restart_strategy, Childspec}}.


init([]) ->
    WebConfig = conf:get_section(web),
    Ip = lib_gen_mod:get_opt(ip, WebConfig),
    HTTP_Port = lib_gen_mod:get_opt(http_port, WebConfig),
    SSL_Port = lib_gen_mod:get_opt(ssl_port, WebConfig),
    Cacertfile = lib_gen_mod:get_opt(cacertfile, WebConfig, undefined),
    Certfile = lib_gen_mod:get_opt(certfile, WebConfig, undefined),
    Keyfile = lib_gen_mod:get_opt(keyfile, WebConfig, undefined),
    NumAcceptors = lib_gen_mod:get_opt(num_acceptors, WebConfig, 100),
    Middlewares = [],
    Disp = lib_gen_mod:get_opt(dispatch, WebConfig),
    Dispatch = cowboy_router:compile(Disp),
    PrivPath = code:priv_dir(smartBattery),
    {M, F, A} =
        case {Certfile, Keyfile} of
            {undefined, undefined} ->
                {cowboy, start_http, [cowboy_ref(integer_to_list(HTTP_Port)), NumAcceptors,
                    [{port, HTTP_Port}, {ip, Ip}],
                    [{env, [{dispatch, Dispatch}]} | Middlewares]]
                };
            _ ->
                {cowboy, start_https, [cowboy_ref(integer_to_list(SSL_Port)), NumAcceptors,
                    [{port, SSL_Port}, {ip, Ip},
                        {cacertfile, PrivPath ++ Cacertfile}, {certfile,PrivPath ++ Certfile},
                        {keyfile,PrivPath ++ Keyfile}],
                    [{env, [{dispatch, Dispatch}]} | Middlewares]]
                }
        end,
    Web = {cowboy,
        {M, F, A},
        permanent, 5000, worker, dynamic},
    T = {app_conn_sup, {app_conn_sup, start_link, []}, permanent, 5000, supervisor, [app_conn_sup]},
    Processes = [Web, T],
    {ok, {{one_for_one, 10, 10}, Processes}}.

cowboy_ref(Ref) ->
    ModRef = [?MODULE_STRING, "_", Ref],
    list_to_atom(binary_to_list(iolist_to_binary(ModRef))).


stop() ->
    stop_web().


stop_web() ->
    WebConfig = conf:get_section(web),
    HTTP_Port = lib_gen_mod:get_opt(http_port, WebConfig),
    SSL_Port = lib_gen_mod:get_opt(ssl_port, WebConfig),
    Certfile = lib_gen_mod:get_opt(certfile, WebConfig, undefined),
    Keyfile = lib_gen_mod:get_opt(keyfile, WebConfig, undefined),
    Ref =
        case {Certfile, Keyfile} of
            {undefined, undefined} ->
                cowboy_ref(integer_to_list(HTTP_Port));
            _ ->
                cowboy_ref(integer_to_list(SSL_Port))
        end,
    cowboy:stop_listener(Ref).
