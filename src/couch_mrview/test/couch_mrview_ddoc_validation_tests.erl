% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(couch_mrview_ddoc_validation_tests).

-include_lib("couch/include/couch_eunit.hrl").
-include_lib("couch/include/couch_db.hrl").

-define(LIB, {[{<<"mylib">>, {[{<<"lib1">>, <<"x=42">>}]}}]}).

setup() ->
    DbName = ?tempdb(),
    erlang:put(io_priority, {view_update, DbName}),
    {ok, Db} = couch_mrview_test_util:init_db(DbName, map),
    Db.

teardown(Db) ->
    couch_db:close(Db),
    couch_server:delete(couch_db:name(Db), [?ADMIN_CTX]),
    ok.

ddoc_validation_test_() ->
    {
        "ddoc validation tests",
        {
            setup,
            fun test_util:start_couch/0, fun test_util:stop_couch/1,
            {
                foreach,
                fun setup/0, fun teardown/1,
                [
                    fun should_reject_invalid_js_map/1,
                    fun should_reject_invalid_js_reduce/1,
                    fun should_reject_invalid_builtin_reduce/1,
                    fun should_reject_non_object_options/1,
                    fun should_reject_non_object_filters/1,
                    fun should_accept_obj_in_filters/1,
                    fun should_reject_non_object_lists/1,
                    fun should_accept_obj_in_lists/1,
                    fun should_reject_non_object_shows/1,
                    fun should_accept_obj_in_shows/1,
                    fun should_reject_non_object_updates/1,
                    fun should_accept_obj_in_updates/1,
                    fun should_reject_non_object_views/1,
                    fun should_reject_non_string_language/1,
                    fun should_reject_non_string_validate_doc_update/1,
                    fun should_accept_string_rewrites/1,
                    fun should_reject_bad_rewrites/1,
                    fun should_accept_option/1,
                    fun should_accept_any_option/1,
                    fun should_accept_filter/1,
                    fun should_reject_non_string_or_obj_filter_function/1,
                    fun should_accept_list/1,
                    fun should_reject_non_string_or_obj_list_function/1,
                    fun should_accept_show/1,
                    fun should_reject_non_string_or_obj_show_function/1,
                    fun should_accept_update/1,
                    fun should_reject_non_string_or_obj_update_function/1,
                    fun should_accept_view/1,
                    fun should_accept_view_with_reduce/1,
                    fun should_accept_view_with_lib/1,
                    fun should_reject_view_that_is_not_an_object/1,
                    fun should_reject_view_without_map_function/1,
                    fun should_reject_view_with_non_string_map_function/1,
                    fun should_reject_view_with_non_string_reduce_function/1,
                    fun should_accept_any_in_lib/1,
                    fun should_accept_map_object_for_queries/1,
                    fun should_reject_map_non_objects_for_queries/1
                ]
            }
        }
    }.

should_reject_invalid_js_map(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_invalid_js_map">>},
        {<<"views">>, {[
            {<<"foo">>, {[
                {<<"map">>, <<"function(doc) }{">>}
            ]}}
        ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, compilation_error, _}, Res).

should_reject_invalid_js_reduce(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_invalid_js_reduce">>},
        {<<"views">>, {[
            {<<"foo">>, {[
                {<<"map">>, <<"function(doc) { emit(null); }">>},
                {<<"reduce">>, <<"function(k, v, r) }{}">>}
            ]}}
        ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, compilation_error, _}, Res).

should_reject_invalid_builtin_reduce(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_invalid_builtin_reduce">>},
        {<<"views">>, {[
            {<<"foo">>, {[
                {<<"map">>, <<"function(doc) { emit(null); }">>},
                {<<"reduce">>, <<"_foobar">>}
            ]}}
        ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_reject_non_object_options(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_object_options">>},
        {<<"options">>, <<"invalid">>}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_reject_non_object_filters(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_object_filters">>},
        {<<"filters">>, <<"invalid">>}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_obj_in_filters(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_obj_in_filters">>},
        {<<"filters">>, ?LIB}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_non_object_lists(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_object_lists">>},
        {<<"lists">>, <<"invalid">>}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_reject_non_object_shows(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_object_shows">>},
        {<<"shows">>, <<"invalid">>}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_obj_in_shows(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_obj_in_shows">>},
        {<<"shows">>, ?LIB}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_non_object_updates(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_object_updates">>},
        {<<"updates">>, <<"invalid">>}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_obj_in_updates(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_obj_in_updates">>},
        {<<"updates">>, ?LIB}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_non_object_views(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_object_views">>},
        {<<"views">>, <<"invalid">>}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_reject_non_string_language(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_string_language">>},
        {<<"language">>, 1}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_reject_non_string_validate_doc_update(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_string_vdu">>},
        {<<"validate_doc_update">>, 1}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_string_rewrites(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_array_rewrites">>},
        {<<"rewrites">>, <<"function(req){}">>}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_bad_rewrites(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_array_rewrites">>},
        {<<"rewrites">>, 42}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_option(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_options">>},
        {<<"options">>, {[ {<<"option1">>, <<"function(doc,req){}">>} ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_accept_any_option(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_any_option">>},
        {<<"options">>, {[ {<<"option1">>, true} ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_accept_filter(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_filters">>},
        {<<"filters">>, {[ {<<"filter1">>, <<"function(doc,req){}">>} ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_non_string_or_obj_filter_function(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_string_or_obj_filter_function">>},
        {<<"filters">>, {[ {<<"filter1">>, 1} ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_list(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_lists">>},
        {<<"lists">>, {[ {<<"list1">>, <<"function(doc,req){}">>} ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_non_string_or_obj_list_function(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_string_or_obj_list_function">>},
        {<<"lists">>, {[ {<<"list1">>, 1} ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_obj_in_lists(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_obj_in_lists">>},
        {<<"lists">>, ?LIB}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).


should_accept_show(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_shows">>},
        {<<"shows">>, {[ {<<"show1">>, <<"function(doc,req){}">>} ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_non_string_or_obj_show_function(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_string_or_obj_show_function">>},
        {<<"shows">>, {[ {<<"show1">>, 1} ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_update(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_updates">>},
        {<<"updates">>, {[ {<<"update1">>, <<"function(doc,req){}">>} ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_non_string_or_obj_update_function(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_string_or_obj_update_function">>},
        {<<"updates">>, {[ {<<"update1">>, 1} ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_view(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_view">>},
        {<<"views">>, {[
                         {<<"view1">>, {[{<<"map">>, <<"function(d){}">>}]}}
                       ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_accept_view_with_reduce(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_view_with_reduce">>},
        {<<"views">>, {[
                         {<<"view1">>, {[
                                         {<<"map">>, <<"function(d){}">>},
                                         {<<"reduce">>,<<"function(d){}">>}
                                        ]}}
                       ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_accept_view_with_lib(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_view_with_lib">>},
        {<<"views">>, {[
                         {<<"view1">>, {[
                                         {<<"map">>, <<"function(d){}">>}
                                        ]}},
                         {<<"lib">>, {[
                                         {<<"lib1">>, <<"x=42">>}
                                      ]}}
                       ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).

should_reject_view_that_is_not_an_object(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_non_object_view">>},
        {<<"views">>, {[{<<"view1">>, <<"thisisbad">>}]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_reject_view_without_map_function(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_view_without_map">>},
        {<<"views">>, {[
                         {<<"view1">>, {[]}}
                       ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).


should_reject_view_with_non_string_map_function(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_view_with_nonstr_map">>},
        {<<"views">>, {[
                         {<<"view1">>, {[
                                         {<<"map">>,{[]}}
                                        ]}}
                       ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_reject_view_with_non_string_reduce_function(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_view_with_nonstr_reduce">>},
        {<<"views">>, {[
                         {<<"view1">>, {[
                                         {<<"map">>,<<"function(d){}">>},
                                         {<<"reduce">>,1}
                                        ]}}
                       ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).

should_accept_any_in_lib(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_any_in_lib">>},
        {<<"views">>, {[
                         {<<"view1">>, {[
                                         {<<"map">>, <<"function(d){}">>}
                                        ]}},
                         {<<"lib">>, {[{<<"lib1">>, {[]}}]}}
                       ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).


should_accept_map_object_for_queries(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_accept_map_objects_for_queries">>},
        {<<"language">>, <<"query">>},
        {<<"views">>, {[
            {<<"view1">>, {[
                {<<"map">>, {[
                    {<<"x">>, <<"y">>}
                ]}}
           ]}}
        ]}}
    ]}),
    Res = couch_db:update_doc(Db, Doc, []),
    ?_assertMatch({ok, _}, Res).


should_reject_map_non_objects_for_queries(Db) ->
    Doc = couch_doc:from_json_obj({[
        {<<"_id">>, <<"_design/should_reject_map_non_objects__with_nonstr_reduce">>},
        {<<"language">>, <<"query">>},
        {<<"views">>, {[
            {<<"view1">>, {[
                {<<"map">>, <<"function(d){}">>}
            ]}}
        ]}}
    ]}),
    Res =
        try
            couch_db:update_doc(Db, Doc, []),
            ok
        catch _Error:Reason ->
            Reason
    end,
    ?_assertMatch({bad_request, invalid_design_doc, _}, Res).
