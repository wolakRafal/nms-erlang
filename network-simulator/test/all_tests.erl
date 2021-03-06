%%%-------------------------------------------------------------------
%%% @author Rafal Wolak
%%% @copyright (C) 2016, robo
%%% @doc
%%%
%%% @end
%%% Created : 04. Mar 2016 17:12
%%%-------------------------------------------------------------------
-module(all_tests).
-author("Rafal Wolak").

-include_lib("eunit/include/eunit.hrl").
-include("network.hrl").

-define(NE_NAME, "test_ne_name").
-define(setup(F), {setup, fun start/0, fun stop/1, F}).
-define(APP_NAME, network).
-define(REG_NAME, network_sup).
-define(BULK_SIZE, 100).

%% Adding NE process Performance.
%% Test Starts network , add N == ?BULK_SIZE Processes, remove all process and stop network process.
%%
%% Performance on DELL LATITUDE E6530 - 11/03/2016: 8 Cores i7-3740QM CPU 2,70 GHz (16 GB RAM but free ~2GB)
%%                                                  N = 100  [done in 0.047 s]
%%                                                  N = 1'000 [done in 0.140 s]
%%                                                  N = 10'000 [done in 0.890 s] without logging all_tests: bulk_remove_network_elements_test_...[0.187 s] ok
%%                                                  N = 100'000 without logging all_tests: bulk_remove_network_elements_test_...[2.231 s] ok
%%                                                  N = 1'000'000 CRASHES! ->
%%                                Crash dump is being written to: erl_crash.dump...done
%%                                eheap_alloc: Cannot allocate 529782288 bytes of memory (of type "heap").
%%
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TESTS DESCRIPTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
start_stop_test_() ->
  {
    "The simulated optical network can be started, stopped and should have a registered name: optical_network ",
    ?setup(fun is_registered/1)
  }.

start_stop_preset_test_() ->
  {
    "The simulated optical network can be started with preset configuration of Network Elements (in network.app)",
    ?setup(fun is_configured/0)
  }.

single_network_element_CRUD_test_() ->
  { "Network should support CRUD operations on NEs",
    {setup,
      fun start/0,
      fun stop/1,
      fun () ->
          { "Single Network Element process can be added, retreived, updated stopped and removed from network",
            {setup, fun add_NE/0, fun remove_NE/1, [fun get_NE/1, fun update_NE/1]}
          }
        end
    }
  }.

bulk_add_network_elements_test_() ->
  {
    "Many (1000) Network Element processes can be added to network",
    ?setup(fun add_bulk/0)
  }.

bulk_remove_network_elements_test_() ->
  {
    "Many (1000) Network Element processes can be removed by one call",
    ?setup({timeout, 10*60, fun remove_bulk/0})
  }.


durability_test() ->
  {"Network shoud be persisted in remote storage. Should recover from restarts and crushes"}.

ne_connection_test() ->
  {"Two NEs can be connected to each other. And can detect loss of connection between them."}.

ne_message_passing_test() ->
  {"After channel configuration, Two NEs should be able to send payloads to specific ports"}.

simple_traffic_test() ->
  {"After configuration, 3 NEs should be able to transfer payload through the network"}.


alarm_test() ->
  {"NE should generate alarm on connection loss to other connected NE"}.

audit_event_test() ->
  {"NE should generate event on any change in the equipment tree"}.


%%%%%%%%%%%%%%%%%%%%%%%
%%% SETUP FUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%
start() ->
  ok = application:start(?APP_NAME),
  whereis(?REG_NAME).

stop(_) ->
  application:stop(?APP_NAME).

%%%%%%%%%%%%%%%%%%%%
%%% ACTUAL TESTS %%%
%%%%%%%%%%%%%%%%%%%%
is_registered(Pid)  ->
  [ ?_assert(erlang:is_process_alive(Pid)),
    ?_assertEqual(Pid, whereis(?REG_NAME))].

is_configured() ->
  [
    ?_assertEqual(0, network:count_ne())
  ].

add_NE() ->
  {ok, Pid} = network:add_ne(create_NE(?NE_NAME)),
  Pid.

remove_NE(NePid) ->
%%  ok = network:stop_ne(NePid), TODO stoping NE?
  ok = network:remove_ne(NePid),
  ok.

get_NE(Pid) ->
  {ok, List} = network:get(Pid),
  ?_assertEqual(1, size(List)).

update_NE(NePid) ->
  ne_device_tests:test_attributes(NePid).

add_bulk() ->
  [
    ?_assertNotException(error, function_clause, network:add_ne(generate_NEs(?BULK_SIZE))),
    ?_assertEqual(?BULK_SIZE, network:count_ne())
  ].

remove_bulk() ->
  NePids = lists:map(fun({ok, Pid}) -> Pid end, network:add_ne(generate_NEs(?BULK_SIZE))),
  [
    ?_assertEqual(ok, network:remove_ne(hd(NePids))),
    ?_assertEqual(?BULK_SIZE - 2, network:count_ne()),
    ?_assertEqual(ok, network:remove_ne(NePids)),
    ?_assertEqual(0, network:count_ne())
  ].


%%create_ne_with_equipment() ->
  
%%%%%%%%%%%%%%%%%%%%%%%%
%%% HELPER FUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%

%% Creates The simplest NE instance
create_NE(NeName)->
  #state{attr = #{ne_name => NeName}}.

create_ne_with_eq(NeName, Equipment) ->
  NE = create_NE(NeName),
  NE#state{equipment = Equipment}.

generate_NEs(N) ->
  [create_NE("ne_process_" ++ integer_to_list(No)) || No <- lists:seq(1, N)].


