%%%-------------------------------------------------------------------
%%% @author dsd
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 十月 2015 下午2:29
%%%-------------------------------------------------------------------
-module(smartBattery_main).
-author("dsd").

-behaviour(gen_server).
-include("/home/dasudian/Proj/smart_battery/apps/smartBattery/include/common.hrl").
-include("/home/dasudian/Proj/smart_battery/apps/smartBattery/include/msg_code.hrl").
-include("/home/dasudian/Proj/smart_battery/apps/smartBattery/include/protocol_aAp.hrl").
-include("/home/dasudian/Proj/smart_battery/apps/smartBattery/include/protocol_pAd.hrl").

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-define(SERVER, ?MODULE).
-define(HEARTTIMEOUT, 600 * 1000).


%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link(any()) ->
    {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link([Imei, TopicList, From]) ->
    RigisterName = lib_util:to_atom(From ++ Imei),
    {ok,Pid} = gen_server:start_link({local, RigisterName}, ?MODULE, [Imei, TopicList, From], []),
    {ok,Pid}.

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
    {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term()} | ignore).

init([Client_id, List, From]) ->
%%    io:format("++++++MAIN init~n"),
%%    Host = mod_config:get(mqtt_host),
%%    io:format("++++++++++++++++++MAIN Host~n"),
%%    Port = mod_config:get(mqtt_port),
%%    User = mod_config:get(mqtt_username),
%%    Password = mod_config:get(mqtt_password),
    Config = conf:get_mqtt_server(Client_id),
%%    io:format("Config===~p~n",[Config]),
    Host = proplists:get_value(mqtt_host, Config),
    Port = proplists:get_value(mqtt_port, Config),
    User = proplists:get_value(mqtt_username, Config),
    Password = proplists:get_value(mqtt_password, Config),

    {ok, C} = emqttc:start_link([
        {host, Host},
        {port, Port},
        {username, lib_util:to_binary(User)},
        {password, lib_util:to_binary(Password)},
        {client_id, lib_util:to_binary(From ++ Client_id)},
        {clean_sess, false},
        {reconnect, 3},
        {logger, {console, info}}]),
    MyConnectInfo = #connetInfo{id = From ++ Client_id, pid = self(), state = 1},
    mod_ets:connect(MyConnectInfo),
    Oppo = get_oppo(From),
    OtherConnectInfo = mod_ets:get_connection(Oppo ++ Client_id),
    update_info(From, Oppo, Client_id),
    {ok, #state{mqttc = C, client_id = Client_id, subscription = List, from = From,
        loginState = OtherConnectInfo#connetInfo.state}}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
    {reply, Reply :: term(), NewState :: #state{}} |
    {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
    {stop, Reason :: term(), NewState :: #state{}}).

handle_call(stop, _From, State) ->
    {stop, normal, ok, State};

handle_call(state, _From, State) ->
    {reply, State, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).


handle_cast(stop, State) ->
    {stop, normal, State};

handle_cast(_Request, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).

%% Publish Messages
handle_info({pubMsg, Topic, Payload}, State = #state{mqttc = C, msg_cnt_sent = I, loginState = _S, from = _F}) ->
    %%io:format("+++Main pubMsg,Topic=~p,Payload=~p~n",[Topic,Payload]),
    logger:info("publish Topic ~p",[Topic]),
    emqttc:publish(C, Topic, Payload, [{qos, 1}]),
    {noreply, State#state{msg_cnt_sent = I + 1}};

%% Receive Messages
handle_info({publish, Topic, Payload}, State = #state{client_id = _Imei, msg_cnt_cvd = I}) ->
    %%io:format("+++Main publish,Topic=~p,Payload=~p~n",[Topic,Payload]),
    NewState = do_msg(Topic, Payload, State),
    {noreply, NewState#state{msg_cnt_cvd = I + 1}};

%% Client connected
handle_info({mqttc, C, connected}, State = #state{mqttc = C, subscription = List}) ->
    logger:info("subscribe Topic ~p",[List]),
    [emqttc:subscribe(C, Topic, 1) || Topic <- List],
    {noreply, State};

%% Client disconnected
handle_info({mqttc, C, disconnected}, State = #state{mqttc = C}) ->
    {noreply, State};

handle_info({update, ID}, State) ->
    OtherConnectInfo = mod_ets:get_connection(ID),
    {noreply, State#state{loginState = OtherConnectInfo#connetInfo.state}};

handle_info(heartBeatTimeout, State) ->
    {stop, noheartBeat, State};

handle_info(heartBeatUpdate, State = #state{ref = Ref}) ->
    timer:cancel(Ref),
    {ok, NewRef} = timer:send_after(?HEARTTIMEOUT, heartBeatTimeout),
    {noreply, State#state{ref = NewRef}};

handle_info({exit}, State) ->
    {stop, normal, State};

handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State = #state{client_id = Imei, from = F}) ->
    mod_ets:disconnected(F ++ Imei),
    Oppo = get_oppo(F),
    update_info(F, Oppo, Imei),
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
    {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

get_oppo(F) ->
    case F of
        ?AppConnect ->
            ?DeviceConnet;
        ?DeviceConnet ->
            ?AppConnect
    end.

update_info(From, Oppo, Client_id) ->
    Pid = lib_util:to_atom(Oppo ++ Client_id),
    case whereis(Pid) of
        undefined ->
            skip;
        _ ->
            Pid ! {update, From ++ Client_id}
    end.


do_msg(Topic, Payload, State = #state{client_id = ID, from = From}) ->

    %% storage return data into riak
    Data = lib_json:from_json(Payload),
    Cmd = proplists:get_value(<<"cmd">>, Data),
    %%sb_riak:put_cmdstatus(Cmd, ID, Payload),
    filter_from_and_storage(From, Cmd, ID, Payload),

    case From of
        ?DeviceConnet ->
            TopicCmd = lib_topic:get_cmd_topic_a2p(ID),
            TopicPing = lib_topic:get_ping_topic_a2p(ID),
            case Topic of
                TopicCmd ->
                    smartBattery_a2p:command_cmd_a2p(Payload, State),
                    State;
                TopicPing ->
                    State#state{loginState = 1}
            end;
        ?AppConnect ->
            TopicCMD = lib_topic:get_cmd_topic_p2a(ID),
            TopicGPS = lib_topic:get_gps_topic_p2a(ID),

            Topic433 = lib_topic:get_433_topic_p2a(ID),

            TopicPing = lib_topic:get_ping_topic_p2a(ID),

            case Topic of
                TopicCMD ->
                    smartBattery_p2a:get_cmd_msg_p2a(Payload, State),
                    State;
                TopicGPS ->
                    smartBattery_p2a:get_gps_msg_p2a(Payload, State),
                    State;
                Topic433 ->
                    smartBattery_p2a:get_433_msg_p2a(Payload, State),
                    State;
                TopicPing ->
                    State#state{loginState = 1}
            end
    end.

filter_from_and_storage(From, Cmd, Id, Payload) ->
    case From of
        ?AppConnect ->
            filter_cmd_and_storage(Cmd, Id, Payload);
        _ ->
            skip
    end.
filter_cmd_and_storage(Cmd, Id, Payload) ->
    case Cmd of
        ?CMD_aAp_FENCE_ON ->
            sb_riak:put_cmdstatus(lib_util:to_binary(Cmd), lib_util:to_binary(Id), Payload);
        ?CMD_aAp_FENCE_OFF ->
            sb_riak:put_cmdstatus(lib_util:to_binary(Cmd), lib_util:to_binary(Id), Payload);
        ?CMD_aAp_FENCE_GET ->
            sb_riak:put_cmdstatus(lib_util:to_binary(Cmd), lib_util:to_binary(Id), Payload);
        ?CMD_aAp_SEEK_ON ->
            sb_riak:put_cmdstatus(lib_util:to_binary(Cmd), lib_util:to_binary(Id), Payload);
        ?CMD_aAp_SEEK_OFF ->
            sb_riak:put_cmdstatus(lib_util:to_binary(Cmd), lib_util:to_binary(Id), Payload);
        ?CMD_aAp_LOCATION ->
            sb_riak:put_cmdstatus(lib_util:to_binary(Cmd), lib_util:to_binary(Id), Payload);
        _ ->
            skip
    end.
