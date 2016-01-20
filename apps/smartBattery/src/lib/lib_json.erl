%% @author Barco You <barco@dasudian.com>
%% @copyright 2015 Dasudian
%%
-module(lib_json).
-export([
	from_json/1, 
	to_json/1
	]).

to_json(PropList) ->
	jsonx:encode(PropList).

from_json(Json) ->
	jsonx:decode(Json, [{format, proplist}]).
