%%%-------------------------------------------------------------------
%%% @author dasudian
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十月 2015 下午3:01
%%%-------------------------------------------------------------------
-author("dasudian").

-record(conninfo, {imei, state = 0, socket, tcp_pid}).
-define(TAB_CONNINFO, conninfo).
-record(state, {socket, transport, loginState = 0}).


-define(CMD_LOGIN, 1).
-define(CMD_GPS, 2).
-define(CMD_CELL, 3).
-define(CMD_PING, 4).
-define(CMD_ALARM, 5).
-define(CMD_SMS, 6).
-define(CMD_433, 7).
-define(CMD_DEFEND, 8).
-define(CMD_SEEK, 9).
-define(CMD_LOCATION, 10).
-define(CMD_SERVER, 11).
-define(CMD_TIMER, 12).


-define(ERR_SUCCESS, 0).
-define(ERR_INTERNAL, 100).
-define(ERR_WAITING, 101).
-define(ERR_OFFLINE, 102).


-define(CMD_aAp_WILD, 0).
-define(CMD_aAp_FENCE_ON, 1).
-define(CMD_aAp_FENCE_OFF, 2).
-define(CMD_aAp_FENCE_GET, 3).
-define(CMD_aAp_SEEK_ON, 4).
-define(CMD_aAp_SEEK_OFF, 5).
-define(CMD_aAp_LOCATION, 6).

