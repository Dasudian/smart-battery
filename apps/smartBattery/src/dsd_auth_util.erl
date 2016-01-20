%%%-------------------------------------------------------------------
%%% @author dasudian
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 十月 2015 下午5:23
%%%-------------------------------------------------------------------
%% @author Barco You <barco@dasudian.com>
%% @copyright 2015 Dasudian
%%
-module(dsd_auth_util).

-define(EPOCH_DIFF, 62167219200).

%% --------------------------------------------------------------------------------------
%% API Function Exports
%% --------------------------------------------------------------------------------------


-export([unique_key/0, hash_to_string/1]).
-export([to_atom/1, to_binary/1, to_integer/1, to_list/1]).



%% --------------------------------------------------------------------------------------
%% API Function Definitions
%% --------------------------------------------------------------------------------------



to_atom(X) when is_list(X) ->
    list_to_atom(X);
to_atom(X) when is_float(X) ->
    to_atom(float_to_list(X));
to_atom(X) when is_binary(X) ->
    to_atom(binary_to_list(X));
to_atom(X) when is_integer(X) ->
    to_atom(integer_to_list(X));
to_atom(X) when is_atom(X) ->
    X.

to_binary(X) when is_atom(X) ->
    to_binary(atom_to_list(X));
to_binary(X) when is_integer(X) ->
    to_binary(integer_to_list(X));
to_binary(X) when is_float(X) ->
    float_to_binary(X);
to_binary(X) when is_list(X) ->
    list_to_binary(X);
to_binary(X) when is_binary(X) ->
    X.

to_integer(X) when is_atom(X) ->
    to_integer(atom_to_list(X));
to_integer(X) when is_list(X) ->
    list_to_integer(X);
to_integer(X) when is_float(X) ->
    to_integer(float_to_binary(X));
to_integer(X) when is_binary(X) ->
    binary_to_integer(X);
to_integer(X) when is_integer(X) ->
    X.


to_list(X) when is_atom(X) ->
    atom_to_list(X);
to_list(X) when is_binary(X) ->
    binary_to_list(X);
to_list(X) when is_integer(X) ->
    integer_to_list(X);
to_list(X) when is_float(X) ->
    float_to_list(X);
to_list(X) when is_list(X) ->
    X.

unique_key() ->
    {ok, Key} = flake_server:id(62),
    Key.

hash_to_string(HashBin) when is_binary(HashBin) ->
    lists:flatten(lists:map(
        fun(X) -> io_lib:format("~2.16.0b", [X]) end,
        binary_to_list(HashBin))).
