%%%-------------------------------------------------------------------
%%% @author dasudian
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 十一月 2015 下午5:02
%%%-------------------------------------------------------------------
-module(logger).
-author("dasudian").

%% API
-export([info/1,info/2,error/1,error/2]).

info(Content) ->
  Logger = gen_logger:new(lager,info),
  Logger:info(Content).
info(Format,Args) ->
  Logger = gen_logger:new(lager,info),
  Logger:info(Format,Args).
error(Content) ->
  Logger = gen_logger:new(lager,info),
  Logger:error(Content).
error(Format,Args) ->
  Logger = gen_logger:new(lager,info),
  Logger:error(Format,Args).