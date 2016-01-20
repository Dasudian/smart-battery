%%%-------------------------------------------------------------------
%%% @author dsd
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 十月 2015 下午2:26
%%%-------------------------------------------------------------------
-author("dsd").

-define(SMARTBATTERYMAIN, smartBattery_main).
-record(state, {mqttc, client_id, subscription, msg_cnt_sent = 0, msg_cnt_cvd = 0, loginState = 0, from, ref}).

-define(AppConnectTable, appConnectTable).

-define(DeviceConnectTable, deviceConnectTable).

-define(ConnectTable, connectTable).

-record(connetInfo, {id, pid, state = 0}).

-define(TABLE, config).
-record(config, {key, value}).

-define(AppConnect, "a2p").
-define(DeviceConnet, "p2a").

-define(MQTTGROUP, mqtt_group).