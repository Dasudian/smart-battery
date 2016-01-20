-module(tcp_parse).

-define(UINT, 32 / unsigned - integer).
-define(INT, 32 / signed - integer).
-define(USHORT, 16 / unsigned - integer).
-define(SHORT, 16).
-define(UBYTE, 8 / unsigned - integer).
-define(BYTE, 8 / signed - integer).
-define(CHAR, 1 / binary - unit:8).

-export([
    parse_packet/1,
    unpack_defend/1,
    unpack_gps/1,
    unpack_location/1,
    %unpack_cell/1,
    unpack_cell_binary/1
]).

parse_packet(Data) ->
    <<MagicNum:?SHORT,
    Command:?SHORT,
    Seq:?SHORT,
    Length:?SHORT,
    Message/binary>> = Data,
    [MagicNum, Command, Seq, Length, Message].

unpack_defend(Msg) ->
    <<Token:?INT, Operator:?CHAR, Result:?CHAR>> = Msg,
    [Token, Operator, Result].

unpack_gps(Msg) ->
    <<Lat/float, Lng/float>> = Msg,
    [Lat, Lng].

unpack_location(Msg) ->
    <<Lat/float, Lng/float>> = Msg,
    [Lat, Lng].

%% unpack_cell([Mcc,Mnc,Cellcounter|T])->
%%     io:format("Mcc=~p,Mnc=~p~n",[Mcc, Mnc]),
%%     F = fetch_max_strength(Cellcounter,T,{0,0,0},1),
%%     io:format("Mcc=~p,Mnc=~p,F=~p~n",[Mcc, Mnc, F]),
%%     {Lac, Cellid, _Rxl} = F,
%%     [Mcc, Mnc, Lac, Cellid].
%%
%% fetch_max_strength(0,_L,Maxvalue,_Cnt)->
%%     Maxvalue;
%% fetch_max_strength(N,L,{Lac,Cellid,Str},Cnt)->
%%     S = lists:nth(3*Cnt, L),
%%     case S >= Str of
%%         true ->
%%             C = 3*Cnt,
%%             MaxValue = {lists:nth(C-2, L),lists:nth(C-1, L),S};
%%         false ->
%%             MaxValue = {Lac, Cellid, Str}
%%     end,
%%     fetch_max_strength(N-1, L, MaxValue, Cnt+1).

unpack_cell_binary(Msg) ->
    <<Mcc:16,Mnc:16,Cellcounter:8,M/binary>> = Msg,
    F = fetch_max_str(Cellcounter, M, {0,0,0}),
    {Lac, Cellid, _Rxl} = F,
    {Mcc, Mnc, Lac, Cellid}.

fetch_max_str(0, _M, Maxvalue) ->
    Maxvalue;
fetch_max_str(Cellcounter, M, {Lac,Cellid,Str}) ->
    <<Lac1:16, Cellid1:16, Str1:16, M1/binary>> = M,
    case Str1 >= Str of
        true ->
            MaxValue = {Lac1, Cellid1, Str1};
        false ->
            MaxValue = {Lac, Cellid, Str}
    end,
    fetch_max_str(Cellcounter-1, M1, MaxValue).
