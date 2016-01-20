-module(erlang_tcp_sup).


-behaviour(supervisor).

-include("mod_d2p.hrl").
%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

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

init([]) ->
	ets:new(?TAB_CONNINFO,[set,named_table,public,{keypos,#conninfo.imei}]),
	TcpProtocol = ?CHILD(tcp_protocol, worker),
%% 	ModD2p = ?CHILD(mod_d2p, worker),
	Childs = [TcpProtocol],
    {ok, {{one_for_one, 5, 10}, Childs}}.

