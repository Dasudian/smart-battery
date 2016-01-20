%%%-------------------------------------------------------------------
%%% @author dsd
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十月 2015 6:27 PM
%%%-------------------------------------------------------------------
-module(default_handler).
-author("dsd").

-include("msg_code.hrl").


%% API
-export([
    init/2,
    allowed_methods/2,
    content_types_accepted/2,
    process_post/2,
    to_html/2]).

init(Req, Opts) ->
    {cowboy_rest, Req, Opts}.

to_html(Req, State) ->
    Body = <<"
<html>
<head>
    <script type=\"text/javascript\">
        var ws = new Object;

        function send() {
            ws.send(\" From web brower \");
            console.log('sent');
        }

        function open() {
            if (!(\"WebSocket\" in window)) {
                alert(\"WebSocket NOT supported by your Browser!\");
                return;
            }

            console.log('open');
            ws = new WebSocket(\"wss://\"+window.location.host+\"/status_notice\");
            ws.onopen = function() {
                console.log('connected');
            };

            ws.onmessage = function (evt) {
                var received_msg = evt.data;
                console.log(\"Received: \" + received_msg);
                var txt = document.createTextNode(\"Got from server: \" + received_msg);
                document.getElementById('messages').appendChild(txt);
            };

            ws.onclose = function() {
                // websocket is closed.
                console.log('close');
            };
        }
    </script>
</head>
<body>
<div id=\"sse\">
   <a href=\"javascript:open()\">Press Me to Open WebSocket</a><br/>
   <a href=\"javascript:send()\">Press Me to Send hi Message</a>
</div>
<div id=\"messages\">
</div>
</body>
</html>
	">>,
    {Body, Req, State}.

allowed_methods(Req, Opts) ->
    {[<<"GET">>, <<"POST">>], Req, Opts}.

content_types_accepted(Req, Opts) ->
    {[
        {<<"application/json">>, process_post},
        {{<<"multipart">>,<<"form-data">>,'*'}, process_post}
    ], Req, Opts}.

process_post(Req, Opt) ->
    verify(Req, Opt).


verify(Req, State) ->
    try
        {ok, Data, Req2} = cowboy_req:body(Req),
        Qs = lib_json:from_json(Data),
        AppID = proplists:get_value(<<"appid">>, Qs),
        Token = proplists:get_value(<<"appSec">>, Qs),
        IMEI = proplists:get_value(<<"imei">>, Qs),
%%        io:format("AppID=~p~n", [AppID]),
%%        io:format("Token=~p~n", [Token]),
%%        io:format("IMEI=~p~n", [IMEI]),
        case verify_app_key(AppID, IMEI, Token) of
            false ->
                {ok, cowboy_req:reply(401, Req), State};
            _ ->
                Config = conf:get_mqtt_server(IMEI),
                Host = proplists:get_value(mqtt_host, Config),
                Port = proplists:get_value(mqtt_port, Config),
                User = proplists:get_value(mqtt_username, Config),
                Password = proplists:get_value(mqtt_password, Config),
                Reply = [{result, 0},
                    {mqtt_host, lib_util:to_binary(Host)},
                    {mqtt_port, Port},
                    {mqtt_username, lib_util:to_binary(User)},
                    {mqtt_password, lib_util:to_binary(Password)}],
                Response = lib_json:to_json(Reply),
                Req3 = cowboy_req:set_resp_header(<<"content-type">>, <<"application/json">>, Req2),
                Req4 = cowboy_req:set_resp_body(Response,Req3),
                smartBattery_p2a:connect(lib_util:to_list(IMEI)),
                {true, Req4, State}
        end

    catch
        _:Why ->
            io:format("Error: ~p ~n, tracy :~p", [Why, erlang:get_stacktrace()]),
            Replyc = [{status, 1}, {reason, ?ERR_INTERNAL}],
            Responsec = lib_json:to_json(Replyc),
            {Responsec, Req, State}
    end.


%% verify appID
verify_app_key(AppID, ID, Token) ->
    try
        Url = mod_config:get(authticate_server),
%%        io:format("Url==============~p~n", [Url]),
        Data = lib_json:to_json([{<<"appid">>, lib_util:to_binary(AppID)}, {<<"sessionid">>, ID}, {<<"token">>, Token}]),
%%        io:format("Data=============~p~n", [Data]),
        Result = httpc:request(post, {Url, [], "application/json", Data}, [{ssl, [{verify, 0}]}], []),
%%        io:format("Result ==========~p~n", [Result]),
        case Result of
            {ok, {_, _, Body}} ->
                Qs = lib_json:from_json(lib_util:to_binary(Body)),
                <<"success">> == proplists:get_value(<<"result">>, Qs);
            {error, _R} ->
                false
        end
    catch
        _:Why ->
            io:format("  ====vverify fail :~p~n  ~p ~n", [Why, erlang:get_stacktrace()]),
            false
    end.
