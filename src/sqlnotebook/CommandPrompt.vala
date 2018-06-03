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
using SqlNotebook.Interpreter;
using SqlNotebook.Utils;

namespace SqlNotebook.Cli {
    /**
     * Text mode REPL for SQL Notebook.
     */
    public class CommandPrompt : Object {
        private NativeCommandPrompt _native; // readonly
        private LibraryFactory _library_factory; // readonly
        private ScriptParser _script_parser; // readonly
        private ScriptEnvironment _script_environment; // readonly
        private Notebook? _notebook = null; // mutable

        public CommandPrompt(LibraryFactory library_factory, ScriptParser script_parser,
                ScriptEnvironment script_environment) {
            _library_factory = library_factory;
            _native = NativeCommandPrompt.create();
            _script_parser = script_parser;
            _script_environment = script_environment;
        }

        /**
         * Runs the REPL until the user exits.
         */
        public void run() {
            try {
                _notebook = _library_factory.new_notebook();
            } catch (Error e) {
                stderr.printf("Fatal error: %s\n", e.message);
                return;
            }

            while (true) {
                var line = _native.get_line();
                if (line == null) {
                    stdout.printf("\n");
                    return;
                }

                line = line.strip();
                var line_down = line.down();
                if (line != "") {
                    _native.add_history(line);
                }

                try {
                    if (line_down == "exit" || line_down == ".exit") {
                        return;
                    } else if (line_down == ".help") {
                        do_help();
                    } else if (line_down == ".new") {
                        do_new();
                    } else if (line_down.has_prefix(".open ")) {
                        do_open(line.substring(6));
                    } else if (line_down == ".save") {
                        do_save();
                    } else if (line_down.has_prefix(".saveas ")) {
                        do_saveas(line.substring(8));
                    } else if (line_down.has_prefix(".")) {
                        stderr.printf("Unknown command. Enter \".help\" for usage hints.\n");
                    } else {
                        do_sql(line);
                    }
                } catch (Error e) {
                    stderr.printf("%s\n\n", e.message);
                }
            }
        }

        private void do_help() {
            var format = "%-22s %s\n";
            stdout.printf(format, ".exit", "Exit this program");
            stdout.printf(format, ".help", "Show this message");
            stdout.printf(format, ".new", "Discard the current notebook and start a blank one");
            stdout.printf(format, ".open FILENAME", "Open the notebook file called FILENAME");
            stdout.printf(format, ".save", "Save the notebook to its original file");
            stdout.printf(format, ".saveas FILENAME", "Save the notebook to FILENAME");
            stdout.printf("\n");
        }

        private void do_new() throws RuntimeError {
            _notebook = _library_factory.new_notebook();
        }

        private void do_open(string filename) throws RuntimeError {
            _notebook = _library_factory.open_notebook(filename);
        }

        private void do_save() throws RuntimeError {
            var token = _notebook.enter();
            try {
                var file_path = _notebook.get_notebook_file_path(token);
                if (file_path == null) {
                    stdout.printf("Use the .saveas command to specify a filename for this untitled notebook.\n\n");
                } else {
                    _notebook.save(file_path, token);
                }
            } finally {
                _notebook.exit(token);
            }
        }

        private void do_saveas(string file_path) throws RuntimeError {
            var token = _notebook.enter();
            try {
                _notebook.save(file_path, token);
            } finally {
                _notebook.exit(token);
            }
        }

        private void do_sql(string command) throws CompileError, RuntimeError {
            var token = _notebook.enter();
            try {
                // run the command
                var script_node = _script_parser.parse(command);
                var script_runner = _library_factory.get_script_runner(_notebook, token);
                var args = new HashMap<string, DataValue>();
                _script_environment.output = new ScriptOutput();
                var script_output = script_runner.execute(script_node, args, _script_environment);

                // print the output
                if (script_output.text_output.size > 0) {
                    foreach (var text in script_output.text_output) {
                        stdout.printf("%s\n", text);
                    }
                    stdout.printf("\n");
                }

                for (var table_index = 0; table_index < script_output.data_tables.size; table_index++) {
                    print_table(script_output.data_tables[table_index]);
                    stdout.printf("\n");
                }

                if (script_output.scalar_result.kind != DataValueKind.NULL) {
                    stdout.printf("%s\n", script_output.scalar_result.to_string());
                    stdout.printf("\n");
                }

                _script_environment.output = null;
            } finally {
                _notebook.exit(token);
            }
        }

        private static void print_table(DataTable table) {
            var num_rows = table.row_count;
            var num_cols = table.column_count;

            // make each column at least as wide as its column name
            var column_widths = new int[table.column_count];
            for (var column_index = 0; column_index < num_cols; column_index++) {
                var name_len = table.get_column_name(column_index).length;
                column_widths[column_index] = name_len;
            }

            // scan the first 100 rows to get some reasonable column widths
            for (var row_index = 0; row_index < num_rows && row_index < 100; row_index++) {
                for (var column_index = 0; column_index < num_cols; column_index++) {
                    var str = table.get_value(row_index, column_index).to_string();
                    if (str.length > column_widths[column_index]) {
                        column_widths[column_index] = str.length;
                    }
                }
            }

            // add one character for the column separator, then cap each individual column at 40 characters
            for (var column_index = 0; column_index < num_cols; column_index++) {
                var w = column_widths[column_index] + 1;
                if (w > 40) {
                    w = 40;
                }
                column_widths[column_index] = w;
            }

            // print column header row
            for (var column_index = 0; column_index < num_cols; column_index++) {
                if (column_index > 0) {
                    stdout.printf(" ");
                }

                var name = table.get_column_name(column_index);
                stdout.printf(pad_string(name, column_widths[column_index] - 1));
            }
            stdout.printf("\n");

            // print row divider
            for (var column_index = 0; column_index < num_cols; column_index++) {
                if (column_index > 0) {
                    stdout.printf(" ");
                }

                stdout.printf(string.nfill(column_widths[column_index] - 1, '-'));
            }
            stdout.printf("\n");

            // print the rows
            var max_rows = 1000;
            for (var row_index = 0; row_index < num_rows && row_index < max_rows; row_index++) {
                if (row_index > 0) {
                    stdout.printf("\n");
                }

                for (var column_index = 0; column_index < num_cols; column_index++) {
                    if (column_index > 0) {
                        stdout.printf(" ");
                    }

                    var str = table.get_value(row_index, column_index).to_string();
                    stdout.printf(pad_string(str, column_widths[column_index] - 1));
                }
            }
            stdout.printf("\n");

            if (num_rows > max_rows) {
                stdout.printf("(%d rows; %d shown)\n", num_rows, max_rows);
            }
        }

        private static string pad_string(string s, int width) {
            if (s.length < width) {
                return s + string.nfill(width - s.length, ' ');
            } else if (s.length > width) {
                return s.substring(0, width - 3) + "...";
            } else {
                return s;
            }
        }
    }
}
