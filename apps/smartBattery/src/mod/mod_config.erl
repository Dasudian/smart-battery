%%%-------------------------------------------------------------------
%%% @author dsd
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 十月 2015 下午4:15
%%%-------------------------------------------------------------------
-module(mod_config).
-author("dsd").

-include("common.hrl").

%% API
-export([init/0]).
-export([get/1]).

init() ->
    db_init(),
    create_table(),
    insert(),
    ok.

create_table() ->
    mnesia:create_table(?TABLE,
        [{ram_copies, [node()]},
            {storage_properties,
                [{ets, [{read_concurrency, true}]}]},
            {attributes, record_info(fields, config)}]),
    mnesia:add_table_copy(config, node(), ram_copies).

db_init() ->
    case mnesia:system_info(extra_db_nodes) of
        [] ->
            application:stop(mnesia),
            mnesia:create_schema([node()]),
            application:start(mnesia, permanent);
        _ ->
            ok
    end,
    mnesia:wait_for_tables(mnesia:system_info(local_tables), infinity).


insert() ->
    GlobalConfig = conf:get_section(global_config),
    Fun = fun() ->
        lists:foreach(fun({Key, Value}) ->
            mnesia:write(?TABLE, #config{key = Key, value = Value}, write)
        end, GlobalConfig)
    end,
    {atomic, _} = mnesia:transaction(Fun).

-spec get(any()) -> undefined|any().
get(Key) ->
    case mnesia:dirty_read(?TABLE, Key) of
        [] ->
            throw("{mod_config get} not found key:" ++ Key);
        [{config, Key, Value}] ->
            Value
    end.
