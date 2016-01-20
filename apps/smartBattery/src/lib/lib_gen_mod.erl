%% @author Barco You <barco@dasudian.com>
%% @copyright 2015 Dasudian
%%
-module(lib_gen_mod).

-export([
         get_opt/2,
         get_opt/3,
         set_opt/3]).

get_opt(Opt, Opts) ->
    case lists:keysearch(Opt, 1, Opts) of
        false ->
            % TODO: replace with more appropriate function
            throw({undefined_option, Opt});
        {value, {_, Val}} ->
            Val
    end.

get_opt(Opt, Opts, Default) ->
    case lists:keysearch(Opt, 1, Opts) of
        false ->
            Default;
        {value, {_, Val}} ->
            Val
    end.


-spec set_opt(_,[tuple()],_) -> [tuple(),...].
set_opt(Opt, Opts, Value) ->
    lists:keystore(Opt, 1, Opts, {Opt, Value}).

