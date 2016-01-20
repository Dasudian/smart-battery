-module(tcp_protocol).
-behaviour(gen_server).
-behaviour(ranch_protocol).
-include("../include/mod_d2p.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% API
-export([start_link/0]).
-export([start_link/4]).

%% APIs For App
-export([do_cmd_to_device/2]).
-export([check_device_login_state/1]).

%% gen_server
-export([init/1]).
-export([init/4]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([terminate/2]).
-export([code_change/3]).

-define(TIMEOUT, 10 * 60 * 1000).


%%% ==================================================================
%%% API
%%% ==================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link(Ref, Socket, Transport, Opts) ->
    proc_lib:start_link(?MODULE, init, [Ref, Socket, Transport, Opts]).

%%% ==================================================================
%%% GEN_SERVER CALLBACKS
%%% ==================================================================
% --------------------------------------------------------------------
% Function: init(_Args) -> 
% 		{ok, State} | {ok, State, Timeout} | ignore | {stop, Reason}
% Description: Initiates the server.
% --------------------------------------------------------------------
%% This function is never called. We only define it so that
%% we can use the -behaviour(gen_server) attribute.
init([]) -> {ok, undefined}.

init(Ref, Socket, Transport, _Opts = []) ->
    ok = proc_lib:init_ack({ok, self()}),
    ok = ranch:accept_ack(Ref),
    ok = Transport:setopts(Socket, [binary, {active, true}]),
    gen_server:enter_loop(?MODULE, [],
        #state{socket = Socket, transport = Transport},
        ?TIMEOUT).

% --------------------------------------------------------------------
% Function: handle_call(Request, From, State) ->
% 				{reply, Reply, State} | 
%               {reply, Reply, State, Timeout} |
%               {noreply, State} | 
% 				{noreply, State, Timeout} |
%               {stop, Reason, Reply, State} | 
% 				{stop, Reason, State}
% Description: Handling call messages.
% --------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    {reply, ok, State, ?TIMEOUT}.

% --------------------------------------------------------------------
% Function: handle_cast(Msg, State) -> 
% 				{noreply, State} | 
% 				{noreply, State, Timeout} | 
% 				{stop, Reason, State}
% Description: Handling cast messages.
% --------------------------------------------------------------------
handle_cast({from_app, Info}, State = #state{socket = Socket, transport = Transport}) ->
    {CMD, Token} = Info,
    Operator = Token,
    Switch = Token,
    case CMD of
        ?CMD_DEFEND ->
            BinMsg = <<16#aa55:16, CMD:16, 1:16, 8:16, Token:32, Operator:8>>;
        ?CMD_SEEK ->
            BinMsg = <<16#aa55:16, CMD:16, 1:16, 8:16, Token:32, Switch:8>>;
        _ ->
            BinMsg = <<16#aa55:16, CMD:16, 1:16, 8:16>>
    end,
    Transport:send(Socket, BinMsg),
    {noreply, State, ?TIMEOUT};

handle_cast(_Msg, State) ->
    {noreply, State, ?TIMEOUT}.

% --------------------------------------------------------------------
% Function: handle_info(Info, State) -> 
% 				{noreply, State} | 
% 				{noreply, State, Timeout} | 
% 				{stop, Reason, State}
% Description: Handling all non call/cast messages.
% --------------------------------------------------------------------
handle_info({tcp, Socket, Data}, State = #state{
    socket = Socket, transport = Transport, loginState = S}) ->
    Transport:setopts(Socket, [{active, true}]),
    Pid = self(),
    Imei = get_imei_by_pid(Pid),
    [Magic, Command, Seq, Length, Message] =
        tcp_parse:parse_packet(Data),
    NewState =
        case Magic of
            16#aa55 ->
                case Command of
                    ?CMD_LOGIN ->
                        mod_d2p:do_login(Message, State),
                        BinMsg = <<Magic:16,Command:16,Seq:16,Length:16>>,
                        %%io:format("Socket====~p,BinMsg=~p~n",[Socket,BinMsg]),
                        gen_tcp:send(Socket,BinMsg);
                    _ ->
                        case S of
                            1 ->
                                mod_d2p:do_msg(Command, Message, Imei),
                                State;
                            0 ->
                                State
                        end
                end;
            _ ->
                State
        end,
    {noreply, NewState, ?TIMEOUT};

handle_info({publish, _Topic, _Command}, State) ->
    %%handle info from MQTTD Server
    {noreply, State, ?TIMEOUT};

handle_info({tcp_closed, _Socket}, State) ->
    {stop, normal, State};
handle_info({tcp_error, _, Reason}, State) ->
    {stop, Reason, State};
handle_info(timeout, State) ->
    {stop, normal, State};
handle_info(_Info, State) ->
    {stop, normal, State}.

% --------------------------------------------------------------------
% Function: terminate(Reason, State) -> void()
% Description: This function is called by a gen_server when it is 
% about to terminate. When it returns,
% the gen_server terminates with Reason. The return value is ignored.
% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    Pid = self(),
    Imei = get_imei_by_pid(Pid),
    case Imei of
        [] ->
            skip;
        _ ->
            P = lib_util:to_atom("p2a" ++ Imei),
            P ! {exit},
            ets:delete(?TAB_CONNINFO, Imei)
    end,
    ok.


% --------------------------------------------------------------------
% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
% Description: Convert process state when code is changed.
% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%% ==================================================================
%%% API for Apps
%%% ==================================================================
do_cmd_to_device(IMEI, Info) ->
    R = get_pid_by_imei(IMEI),
    {Cmd, _} = Info,
    case R of
        {ok, Tcp_Pid} ->
            Msg = lib_json:to_json([{cmd, Cmd}, {result, ?ERR_WAITING}]),
            smartBattery_p2a:cmd_info_from_device(IMEI, Cmd, Msg),
            gen_server:cast(Tcp_Pid, {from_app, Info}),
            ok;
        {error} ->
            Msg = [{cmd, Cmd}, {result, ?ERR_OFFLINE}],
            NMsg = lib_json:to_json(Msg),
            smartBattery_p2a:cmd_info_from_device(IMEI, Cmd, NMsg),
            notonline
    end.

get_imei_by_pid(Pid) ->
    Ms = ets:fun2ms(fun(#conninfo{tcp_pid = EPid, imei = EIMEI} = _R) when EPid == Pid -> EIMEI end),
    Result = ets:select(?TAB_CONNINFO, Ms),
    case Result of
        [] -> [];
        [IMEI | _] -> IMEI
    end.

get_pid_by_imei(IMEI) ->
    Lookup = ets:lookup(?TAB_CONNINFO, IMEI),
    case Lookup of
        [] ->
            {error};
        [R | _] ->
            {ok, R#conninfo.tcp_pid}
    end.

check_device_login_state(IMEI) ->
    case get_pid_by_imei(IMEI) of
        {ok, _} -> 1;
        {error} -> 0
    end.
