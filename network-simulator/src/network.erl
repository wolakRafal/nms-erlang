%%%-------------------------------------------------------------------
%%% @author Rafal Wolak
%%% @copyright (C) 2016, robo
%%% @doc
%%% Simulator Application. Simulates many network devices.
%%% Can simulate cluster of devices for one single Management Domain (MD)
%%% @end
%%% Created : 12. sty 2016 19:50
%%%-------------------------------------------------------------------
-module(network).
-author("Rafal Wolak").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% Application API
-export([list_all/0, count/0, get/1, add/1, remove/1, stop_ne/1]).

-define(NET_SUP, network_sup).


%%%===================================================================
%%% Application callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application is started using
%% application:start/[1,2], and should start the processes of the
%% application. If the application is structured according to the OTP
%% design principles as a supervision tree, this means starting the
%% top supervisor of the tree.
%% -------
%% Starts single management domain with set of devices configured in
%% 'simulator.app'.
%% New devices can be added by CLI client or REST.
%%
%% @end
%%--------------------------------------------------------------------
-spec(start(StartType :: normal | {takeover, node()} | {failover, node()},
    StartArgs :: term()) ->
  {ok, pid()} |
  {ok, pid(), State :: term()} |
  {error, Reason :: term()}).
start(normal, StartArgs) ->
  network_sup:start_link(StartArgs).


%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application has stopped. It
%% is intended to be the opposite of Module:start/2 and should do
%% any necessary cleaning up. The return value is ignored.
%%
%% @end
%%--------------------------------------------------------------------
-spec(stop(State :: term()) -> term()).
stop(_State) ->
  ok.

%%%===================================================================
%%% API for tests and CLI
%%%===================================================================

list_all() ->
  supervisor:which_children(?NET_SUP).

count() ->
  supervisor:count_children(?NET_SUP).

get(NeId) ->
  {ok, lists:keyfind(NeId, 1, supervisor:which_children(?NET_SUP))}.

add(ChildSpec) ->
  supervisor:start_child(?NET_SUP, ChildSpec).

stop_ne(NeId) ->
  supervisor:terminate_child(?NET_SUP, NeId).

remove(NeId) ->
  supervisor:delete_child(?NET_SUP, NeId).

%%%===================================================================
%%% Internal functions
%%%===================================================================