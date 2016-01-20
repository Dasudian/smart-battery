%% -------------------------------------------------------------------
%% @author Barco You <barco@dasudian.com>
%% @copyright 2015 Dasudian
%%
%% -------------------------------------------------------------------
-module(lib_util).

-define(EPOCH_DIFF, 62167219200).

%% --------------------------------------------------------------------------------------
%% API Function Exports
%% --------------------------------------------------------------------------------------

-export([utc_now/0, utc/1, epoch_utc_now/0, epoch_utc/1]).
-export([unique_key/0, hash_to_string/1,md5_hex/1]).
-export([to_atom/1,to_binary/1,to_integer/1,to_list/1]).
-export([proplists_delete/2,proplists_get/2]).
-export([replace_dot/1]).
%% --------------------------------------------------------------------------------------
%% API Function Definitions
%% --------------------------------------------------------------------------------------

utc_now() ->
  utc(erlang:now()).

utc(Now = {_, _, Micro}) ->
  {{Y, M, D}, {H, MM, S}} = calendar:now_to_universal_time(Now),
  iolist_to_binary(io_lib:format("~4.4.0w-~2.2.0w-~2.2.0wT~2.2.0w:~2.2.0w:~2.2.0w.~3.3.0wZ", [Y, M, D, H, MM, S, trunc(Micro / 1000)])).

epoch_utc_now() ->
  erlang:now().

epoch_utc(Now) ->
  calendar:datetime_to_gregorian_seconds(calendar:now_to_universal_time(Now)) - ?EPOCH_DIFF.

to_atom(X) when is_list(X)->
	list_to_atom(X);
to_atom(X) when is_float(X)->
	to_atom(float_to_list(X));
to_atom(X) when is_binary(X)->
	to_atom(binary_to_list(X));
to_atom(X) when is_integer(X)->
	to_atom(integer_to_list(X));
to_atom(X) when is_atom(X)->
	X.

to_binary(X) when is_atom(X) ->
  to_binary(atom_to_list(X));
to_binary(X) when is_integer(X) ->
  to_binary(integer_to_list(X));
to_binary(X) when is_float(X)->
	float_to_binary(X);
to_binary(X) when is_list(X) ->
  list_to_binary(X);
to_binary(X) when is_binary(X) ->
  X.

to_integer(X) when is_atom(X)->
  to_integer(atom_to_list(X));
to_integer(X) when is_list(X)->
  list_to_integer(X);
to_integer(X) when is_float(X)->
  to_integer(float_to_binary(X));
to_integer(X) when is_binary(X)->
  binary_to_integer(X);
to_integer(X) when is_integer(X)->
  X.


to_list(X) when is_atom(X)->
  atom_to_list(X);
to_list(X) when is_binary(X)->
  binary_to_list(X);
to_list(X) when is_integer(X)->
  integer_to_list(X);
to_list(X) when is_float(X)->
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

md5_hex(S) ->
  Md5_bin = erlang:md5(S),
  Md5_list = binary_to_list(Md5_bin),
  lists:flatten(list_to_hex(Md5_list)).

list_to_hex(L) ->
	lists:map(fun(X) -> int_to_hex(X) end, L).

int_to_hex(N) when N < 256 ->
	[hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
	$0 + N;
hex(N) when N >= 10, N < 16 ->
	$a + (N - 10).


proplists_delete(Key, Proplists) when is_atom(Key) ->
  proplists:delete(Key, Proplists);
proplists_delete([], Proplists) ->
  Proplists;
proplists_delete([Key | KeyList], Proplists) ->
  proplists_delete(KeyList, proplists:delete(Key, Proplists)).


proplists_get(Key,Proplists) when is_atom(Key)->
  proplists_get([Key],Proplists);
proplists_get(Keylist,Proplists) when is_list(Keylist) ->
  proplists_get(Keylist,Proplists,[]).

proplists_get([],_Proplists,Results) ->
  Results;
proplists_get([Key|KeyList],Proplists,Results) ->
  case proplists:get_value(Key,Proplists) of
    undefined->
        proplists_get(KeyList,Proplists,Results);
    Value->
      proplists_get(KeyList,proplists:delete(Key,Proplists),[{Key,Value}|Results])
  end.

%% @doc for replace dot from riak
-spec replace_dot(list()) ->list().
replace_dot(Input) ->
  lists:map(fun({Key,Value}) ->
    Key_List = lib_util:to_list(Key),
    Key_Output = re:replace(Key_List,"\\.","_",[{return,list}]),
    {lib_util:to_binary(Key_Output),Value} end,Input).
