%% Copyright (c) 2018 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(emqx_lua_hook_cli).

-export([load/0, cmd/1, unload/0]).

load() ->
    emqx_ctl:register_cmd(luahook, {?MODULE, cmd}, []).

unload() ->
    emqx_ctl:unregister_cmd(luahook).

cmd(["load", Script]) ->
    case emqx_lua_hook:load_script(fullname(Script)) of
        ok -> emqx_cli:print("Load ~p successfully~n", [Script]);
        error -> emqx_cli:print("Load ~p error~n", [Script])
    end;

cmd(["reload", Script]) ->
    FullName = fullname(Script),
    emqx_lua_hook:unload_script(FullName),
    case emqx_lua_hook:load_script(FullName) of
        ok -> emqx_cli:print("Reload ~p successfully~n", [Script]);
        error -> emqx_cli:print("Reload ~p error~n", [Script])
    end;

cmd(["unload", Script]) ->
    emqx_lua_hook:unload_script(fullname(Script)),
    emqx_cli:print("Unload ~p successfully~n", [Script]);

cmd(["enable", Script]) ->
    FullName = fullname(Script),
    case file:rename(fullnamedisable(Script), FullName) of
        ok -> case emqx_lua_hook:load_script(FullName) of
                  ok ->
                      emqx_cli:print("Enable ~p successfully~n", [Script]);
                  error ->
                      emqx_cli:print("Fail to enable ~p~n", [Script])
              end;
        {error, Reason} ->
            emqx_cli:print("Fail to enable ~p due to ~p~n", [Script, Reason])
    end;

cmd(["disable", Script]) ->
    FullName = fullname(Script),
    emqx_lua_hook:unload_script(FullName),
    case file:rename(FullName, fullnamedisable(Script)) of
        ok ->
            emqx_cli:print("Disable ~p successfully~n", [Script]);
        {error, Reason} ->
            emqx_cli:print("Fail to disable ~p due to ~p~n", [Script, Reason])
    end;

cmd(_) ->
    emqx_cli:usage([{"luahook load <Script>",    "load lua script into hook"},
                    {"luahook unload <Script>",  "unload lua script from hook"},
                    {"luahook reload <Script>",  "reload lua script into hook"},
                    {"luahook enable <Script>",  "enable lua script and load it into hook"},
                    {"luahook disable <Script>", "unload lua script out of hook and disable it"}]).

