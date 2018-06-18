// SQL Notebook
// Copyright (C) 2018 Brian Luft
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
// OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

using Gee;
using SqlNotebook;
using SqlNotebook.Collections;
using SqlNotebook.Errors;
using SqlNotebook.Interpreter.Ast;

namespace SqlNotebook.Interpreter {
    public class ScriptRunner : Object {
        private weak Notebook _notebook;
        private NotebookLockToken _token;

        // lock token must be valid for the duration of the ScriptRunner's life
        public ScriptRunner(Notebook notebook, NotebookLockToken token) {
            _notebook = notebook;
            _token = token;
        }

        public ScriptOutput execute(ScriptNode script, HashMap<string, DataValue> args, ScriptEnvironment? env = null)
        throws RuntimeError {
            env = env ?? new ScriptEnvironment();

            foreach (var arg in args.entries) {
                var lowercase_key = arg.key.down();
                env.variables.set(lowercase_key, arg.value);
            }

            execute_script(script, env);

            return env.output;
        }

        private void execute_script(ScriptNode node, ScriptEnvironment env) throws RuntimeError {
            execute_block(node.block, env);

            if (env.did_break) {
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(
                        "The script attempted to BREAK without an enclosing loop.");
            } else if (env.did_continue) {
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(
                        "The script attempted to CONTINUE without an enclosing loop.");
            } else if (env.did_throw) {
                throw new RuntimeError.UNCAUGHT_SCRIPT_ERROR(env.error_message.to_string());
            }
        }

        private void execute_block(BlockNode node, ScriptEnvironment env) throws RuntimeError {
            foreach (var statement in node.statements) {
                execute_statement(statement, env);
                if (env.did_return || env.did_break || env.did_continue || env.did_throw) {
                    return;
                }
            }
        }

        private void execute_statement(StatementNode node, ScriptEnvironment env) throws RuntimeError {
            switch (node.statement_type) {
                case StatementType.BLOCK:
                    execute_block_statement((BlockStatementNode)node, env);
                    break;

                case StatementType.BREAK:
                    execute_break_statement((BreakStatementNode)node, env);
                    break;

                case StatementType.CONTINUE:
                    execute_continue_statement((ContinueStatementNode)node, env);
                    break;

                case StatementType.DECLARE:
                    execute_declare_statement((DeclareAssignmentStatementNode)node, env);
                    break;

                case StatementType.EXECUTE:
                    execute_execute_statement((ExecuteStatementNode)node, env);
                    break;

                case StatementType.EXPORT_TXT:
                    execute_export_txt_statement((ExportTxtStatementNode)node, env);
                    break;

                case StatementType.FOR:
                    execute_for_statement((ForStatementNode)node, env);
                    break;

                case StatementType.IF:
                    execute_if_statement((IfStatementNode)node, env);
                    break;

                case StatementType.IMPORT_CSV:
                    execute_import_csv_statement((ImportCsvStatementNode)node, env);
                    break;

                case StatementType.IMPORT_TXT:
                    execute_import_txt_statement((ImportTxtStatementNode)node, env);
                    break;

                case StatementType.IMPORT_XLS:
                    execute_import_xls_statement((ImportXlsStatementNode)node, env);
                    break;

                case StatementType.PRINT:
                    execute_print_statement((PrintStatementNode)node, env);
                    break;

                case StatementType.RETHROW:
                    execute_rethrow_statement((RethrowStatementNode)node, env);
                    break;

                case StatementType.RETURN:
                    execute_return_statement((ReturnStatementNode)node, env);
                    break;

                case StatementType.SET:
                    execute_set_statement((SetAssignmentStatementNode)node, env);
                    break;

                case StatementType.SQL:
                    execute_sql_statement((SqlStatementNode)node, env);
                    break;

                case StatementType.THROW:
                    execute_throw_statement((ThrowStatementNode)node, env);
                    break;

                case StatementType.TRY_CATCH:
                    execute_try_catch_statement((TryCatchStatementNode)node, env);
                    break;

                case StatementType.WHILE:
                    execute_while_statement((WhileStatementNode)node, env);
                    break;

                default:
                    assert(false);
                    break;
            }
        }

        private void execute_sql_statement(SqlStatementNode node, ScriptEnvironment env) throws RuntimeError {
            foreach (var pre_statement in node.pre_statements) {
                execute_statement(pre_statement, env);
                if (env.did_throw) {
                    return;
                }
            }

            try {
                var data_table = _notebook.sqlite_query_with_named_args(node.sql, env.variables, _token);
                if (data_table.column_count > 0) {
                    env.output.data_tables.add(data_table);
                }
            } finally {
                foreach (var post_statement in node.post_statements) {
                    try {
                        execute_statement(post_statement, env);
                    } catch {
                    }
                    if (env.did_throw) {
                        break;
                    }
                }
            }
        }

        private void execute_declare_statement(DeclareAssignmentStatementNode node, ScriptEnvironment env) throws RuntimeError {
            var name = node.variable_name;
            var lowercase_name = name.down();
            var declaration_exists = env.variables.has_key(lowercase_name);

            var initial_value =
                node.initial_value == null
                ? DataValue.for_null()
                : evaluate_expression(node.initial_value, env);

            if (node.is_parameter) {
                if (env.parameter_names.contains(lowercase_name)) {
                    throw new RuntimeError.INVALID_SCRIPT_OPERATION(@"Duplicate DECLARE for parameter \"$name\".");
                } else {
                    env.parameter_names.add(lowercase_name);
                }

                if (declaration_exists) {
                    // do nothing; the parameter value was specified by the caller
                } else if (node.initial_value != null) {
                    // the caller did not specify a value, but there is an initial value in the DECLARE statement.
                    env.variables.set(lowercase_name, initial_value);
                } else {
                    throw new RuntimeError.INVALID_SCRIPT_OPERATION(
                            @"An argument value was not provided for parameter \"$name\".");
                }
            } else if (declaration_exists) {
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(@"Duplicate DECLARE for variable \"$name\".");
            } else {
                env.variables.set(lowercase_name, initial_value);
            }
        }

        private void execute_set_statement(SetAssignmentStatementNode node, ScriptEnvironment env) throws RuntimeError {
            var lowercase_name = node.variable_name.down();

            if (env.variables.has_key(lowercase_name)) {
                assert(node.initial_value != null);
                var initial_value = evaluate_expression(node.initial_value, env);
                env.variables.set(lowercase_name, initial_value);
            } else {
                var name = node.variable_name;
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(@"Attempted to SET the undeclared variable \"$name\".");
            }
        }

        private void execute_if_statement(IfStatementNode node, ScriptEnvironment env) throws RuntimeError {
            var condition = evaluate_expression_integer(node.condition, env);
            if (condition == 0) {
                if (node.else_block != null) {
                    execute_block(node.else_block, env);
                }
            } else if (condition == 1) {
                execute_block(node.block, env);
            } else {
                var sql = node.condition.sql;
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(
                        @"Evaluation of expression \"$sql\" produced a value of $condition instead of the expected 0 or 1.");
            }
        }

        private void execute_while_statement(WhileStatementNode node, ScriptEnvironment env) throws RuntimeError {
            while (true) {
                var condition = evaluate_expression_integer(node.condition, env);
                if (condition == 1) {
                    execute_block(node.block, env);
                    if (env.did_return || env.did_throw) {
                        break;
                    } else if (env.did_break) {
                        env.did_break = false;
                        break;
                    } else if (env.did_continue) {
                        env.did_continue = false;
                    }
                } else if (condition == 0) {
                    break;
                } else {
                    var sql = node.condition.sql;
                    throw new RuntimeError.INVALID_SCRIPT_OPERATION(
                            @"Evaluation of expression \"$sql\" produced a value of $condition instead of the expected 0 or 1.");
                }
            }
        }

        private void execute_for_statement(ForStatementNode node, ScriptEnvironment env) throws RuntimeError {
            var first_number = evaluate_expression_integer(node.first_number, env);
            var last_number = evaluate_expression_integer(node.last_number, env);

            int64 step = first_number <= last_number ? 1 : -1;
            if (node.step != null) {
                step = evaluate_expression_integer(node.step, env);
            }

            if (step == 0) {
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(
                        "The STEP value in a FOR statement must not be zero.");
            } else if (step < 0 && first_number < last_number) {
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(
                        "The STEP value in a FOR statement must be positive if \"first-number\" < \"last-number\".");
            } else if (step > 0 && first_number > last_number) {
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(
                        "The STEP value in a FOR statement must be negative if \"first-number\" > \"last-number\".");
            }

            var is_upward = step > 0;
            var counter = first_number;
            var lowercase_variable_name = node.variable_name.down();

            while ((is_upward && counter <= last_number) || (!is_upward && counter >= last_number)) {
                env.variables.set(lowercase_variable_name, DataValue.for_integer(counter));

                execute_block(node.block, env);
                if (env.did_return || env.did_throw) {
                    break;
                } else if (env.did_break) {
                    env.did_break = false;
                    break;
                } else if (env.did_continue) {
                    env.did_continue = false;
                }

                counter += step;
            }
        }

        private void execute_block_statement(BlockStatementNode node, ScriptEnvironment env) throws RuntimeError {
            execute_block(node.block, env);
        }

        private void execute_break_statement(BreakStatementNode node, ScriptEnvironment env) throws RuntimeError {
            env.did_break = true;
        }

        private void execute_continue_statement(ContinueStatementNode node, ScriptEnvironment env) throws RuntimeError {
            env.did_continue = true;
        }

        private void execute_print_statement(PrintStatementNode node, ScriptEnvironment env) throws RuntimeError {
            var value = evaluate_expression(node.value, env);
            var text = value.to_string();
            env.output.text_output.add(text);
        }

        private void execute_execute_statement(ExecuteStatementNode node, ScriptEnvironment env) throws RuntimeError {
            throw new RuntimeError.NOT_IMPLEMENTED("not implemented");
        }

        private void execute_return_statement(ReturnStatementNode node, ScriptEnvironment env) throws RuntimeError {
            if (node.value != null) {
                env.output.scalar_result = evaluate_expression(node.value, env);
            }

            env.did_return = true;
        }

        private void execute_throw_statement(ThrowStatementNode node, ScriptEnvironment env) throws RuntimeError {
            var error_message = evaluate_expression(node.message, env);
            throw_error(error_message, env);
        }

        private void execute_rethrow_statement(RethrowStatementNode node, ScriptEnvironment env) throws RuntimeError {
            env.did_throw = true;
        }

        private void execute_try_catch_statement(TryCatchStatementNode node, ScriptEnvironment env) throws RuntimeError {
            execute_block(node.try_block, env);
            if (env.did_throw) {
                env.did_throw = false;
                execute_block(node.catch_block, env);
            }
        }

        private void execute_import_csv_statement(ImportCsvStatementNode node, ScriptEnvironment env) throws RuntimeError {
            throw new RuntimeError.NOT_IMPLEMENTED("not implemented");
        }

        private void execute_import_xls_statement(ImportXlsStatementNode node, ScriptEnvironment env) throws RuntimeError {
            throw new RuntimeError.NOT_IMPLEMENTED("not implemented");
        }

        private void execute_import_txt_statement(ImportTxtStatementNode node, ScriptEnvironment env) throws RuntimeError {
            throw new RuntimeError.NOT_IMPLEMENTED("not implemented");
        }

        private void execute_export_txt_statement(ExportTxtStatementNode node, ScriptEnvironment env) throws RuntimeError {
            throw new RuntimeError.NOT_IMPLEMENTED("not implemented");
        }

        public int64 evaluate_expression_integer(ExpressionNode node, ScriptEnvironment env) throws RuntimeError {
            var value = evaluate_expression(node, env);
            var expected_kind = DataValueKind.INTEGER;
            if (value.kind == expected_kind) {
                return value.integer_value;
            } else {
                var message = get_expression_type_mismatch_message(node.sql, value.kind, expected_kind);
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(message);
            }
        }

        public double evaluate_expression_real(ExpressionNode node, ScriptEnvironment env) throws RuntimeError {
            var value = evaluate_expression(node, env);
            var expected_kind = DataValueKind.REAL;
            if (value.kind == expected_kind) {
                return value.real_value;
            } else {
                var message = get_expression_type_mismatch_message(node.sql, value.kind, expected_kind);
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(message);
            }
        }

        public string evaluate_expression_text(ExpressionNode node, ScriptEnvironment env) throws RuntimeError {
            var value = evaluate_expression(node, env);
            var expected_kind = DataValueKind.TEXT;
            if (value.kind == expected_kind) {
                return value.text_value;
            } else {
                var message = get_expression_type_mismatch_message(node.sql, value.kind, expected_kind);
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(message);
            }
        }

        private static string get_expression_type_mismatch_message(string sql, DataValueKind actual_kind,
                DataValueKind expected_kind) {
            var actual_kind_str = actual_kind.to_string();
            var expected_kind_str = expected_kind.to_string();
            return
                @"Evaluation of expression \"$sql\" produced a value of type $actual_kind_str instead of the " +
                @"expected $expected_kind_str.";
        }

        public DataValue evaluate_expression(ExpressionNode node, ScriptEnvironment env) throws RuntimeError {
            var sql = "SELECT (" + node.sql + ")";
            var dt = _notebook.sqlite_query_with_named_args(sql, env.variables, _token);
            if (dt.column_count == 1 && dt.row_count == 1) {
                return dt.get_value(0, 0);
            } else {
                var message = "Evaluation of expression \"" + node.sql + "\" did not produce a value.";
                throw new RuntimeError.INVALID_SCRIPT_OPERATION(message);
            }
        }

        private void throw_error(DataValue error_message, ScriptEnvironment env) {
            env.error_message = error_message;
            env.did_throw = true;
        }
    }
}
