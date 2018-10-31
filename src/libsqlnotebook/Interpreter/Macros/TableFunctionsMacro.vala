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

using SqlNotebook.Errors;
using SqlNotebook.Interpreter.Ast;
using SqlNotebook.Utils;

namespace SqlNotebook.Interpreter.Macros {
    public class TableFunctionsMacro : Macro {
        private Gee.HashMap<string, TableFunction> _table_functions = new Gee.HashMap<string, TableFunction>();

        public TableFunctionsMacro(Gee.List<TableFunction> table_functions) {
            foreach (var table_function in table_functions) {
                _table_functions.set(table_function.get_name().down(), table_function);
            }
        }

        public override bool apply(SqlStatementNode statement) throws RuntimeError {
            var did_change = false;
            
            foreach (var call_node in statement.find_nodes_bottom_up(is_table_function_call_node)) {
                var name_node = call_node.get_child_at(0);
                if (name_node == null) {
                    continue; // shouldn't happen
                }
                
                var name = ((SqliteSyntaxProductionNode)name_node).text.down();
                
                if (!_table_functions.has_key(name)) {
                    continue; // the user's program probably contains an error; not our problem
                }
                
                var table_function = _table_functions.get(name);
                var args = new Gee.ArrayList<SqliteSyntaxProductionNode>();
                //TODO: find the args, validate the number of args, pass arg list to table_function.apply()                
                
                table_function.apply(statement, (SqliteSyntaxProductionNode)call_node);
                did_change = true;
            }
            
            return did_change;
        }

        private bool is_table_function_call_node(AstNode node) {
            var call = node as SqliteSyntaxProductionNode;
            return call != null && call.name == "table-or-subquery.table-function-call";
        }
        
        private bool is_table_function_name_node(AstNode node) {
            var call = node as SqliteSyntaxProductionNode;
            return call != null && call.name == "table-or-subquery.table-function-name";
        }
    }
}
