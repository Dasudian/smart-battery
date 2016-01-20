%%%-------------------------------------------------------------------
%%% @author dsd
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十月 2015 7:52 PM
%%%-------------------------------------------------------------------
-module(app_conn_sup).
-author("dsd").

-include("../include/common.hrl").

%% API
-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    mod_ets:init(),
    Restart_strategy = {simple_one_for_one, 5, 10},
    Childspec = [{?SMARTBATTERYMAIN, {?SMARTBATTERYMAIN, start_link, []}, transient, 5000, worker, [?SMARTBATTERYMAIN]}],
    {ok, {Restart_strategy, Childspec}}.
