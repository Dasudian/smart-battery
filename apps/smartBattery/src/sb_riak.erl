-module(sb_riak).
-export([put_location/2, put_cmdstatus/3]).
-define(LOCBUCK, <<"dsd_smartbattery_location">>).
-define(CMDBUCK, <<"dsd_smartbattery_commandstatus">>).

put_location(IMEI, Data) when is_binary(IMEI)->
    RiakData = case Data of
                   {_Latt,_Long}->
                       create_data(gps, Data);
                   {_Mcc,_Mnc,_Lac,_Cellid}->
                   %%{_Lac, _Cell, _Rxl}->
                       create_data(basestation, Data)
               end,
    {ts,TS} = lists:nth(1,RiakData),
    put_riak(?LOCBUCK, IMEI, TS, RiakData).

put_cmdstatus(Command, IMEI, ReturnCode) when is_binary(IMEI), is_binary(Command)->
    RiakData = create_data(commandstatus, ReturnCode),
    {ts,TS} = lists:nth(1,RiakData),
    K = binary_to_list(IMEI) ++ "_" ++ erlang:integer_to_list(TS),
    Key = list_to_binary(K),
    put_riak(?CMDBUCK, Command, Key, RiakData).



%%==================INTERNAL-FUNCTIONS===================

put_riak(BucketType,BucketName,Key,Value)->
    case dsd_riak:add({BucketType,BucketName},Key,Value) of
        ok ->
            logger:info("put_riak BucketType:~p,BucketName:~p,Key:~p,Value:~p",[BucketType,BucketName,Key,Value]),
            ok;
        Reason ->
            {error, Reason}
    end.


create_data(gps,{Latt, Long})->
    TS = erlang:list_to_integer(ts()),
    [{ts,TS},{lattitude, Latt}, {longitude, Long}];

create_data(basestation, {Mcc, Mnc, Lac, Cell})->
    TS = erlang:list_to_integer(ts()),
    [{ts,TS},{mcc, Mcc}, {mnc, Mnc}, {lac, Lac},{cellid, Cell}];

create_data(commandstatus, ReturnCode)->
    TS = erlang:list_to_integer(ts()),
    [{ts,TS},{return, ReturnCode}].


ts()->
    T1 = os:timestamp(),
    T2 = calendar:now_to_universal_time(T1),
    get_normalized_datetime(T2).

% returns date/time as a properly formatted string (e.g. "YYYYMMDDHHMMSS")
get_normalized_datetime( {{Y, M, D}, {H, Mi, S}}) ->
    L = lists:map(fun(X) ->
        X2=integer_to_list(X),
        return_2columns(X2)
    end,
        [M, D, H, Mi, S]
    ),
    [M2, D2, H2, Mi2, S2] = L,
    integer_to_list(Y) ++ "" ++ M2 ++ "" ++ D2 ++ "" ++ H2 ++ "" ++ Mi2 ++ "" ++ S2.

return_2columns(X) ->
    case length(X) of
        1 ->
            "0" ++ X;
        _ ->
            X
    end.
