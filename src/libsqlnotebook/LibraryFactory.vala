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
using SqlNotebook.Interpreter;
using SqlNotebook.Interpreter.ScalarFunctions;
using SqlNotebook.Interpreter.ScalarFunctions.ArrayFunctions;
using SqlNotebook.Interpreter.ScalarFunctions.DyadicMathFunctions;
using SqlNotebook.Interpreter.ScalarFunctions.MonadicMathFunctions;
using SqlNotebook.Interpreter.SqliteSyntax;
using SqlNotebook.Interpreter.Tokens;
using SqlNotebook.Persistence;
using SqlNotebook.Utils;

namespace SqlNotebook {
    /**
     * Generates objects for users of libsqlnotebook.  The application uses a single instance of this factory as the
     * root of the dependency tree.
     */
    public class LibraryFactory : Object {
        private NotebookSerializer _notebook_serializer;
        private ScriptParser _script_parser;
        private SqliteGrammar _sqlite_grammar;
        private SqliteParser _sqlite_parser;
        private TempFolder _temp_folder;
        private Tokenizer _tokenizer;
        private Gee.BidirList<ScalarFunction> _scalar_functions;

        private LibraryFactory() {
        }

        /**
         * Initializes the dependency tree.
         * @return New {@link LibraryFactory}
         */
        public static LibraryFactory create() throws RuntimeError {
            var f = new LibraryFactory();
            f._sqlite_grammar = new SqliteGrammar();
            f._sqlite_parser = new SqliteParser(f._sqlite_grammar);
            f._temp_folder = TempFolder.create();
            f._tokenizer = new Tokenizer();
            f._script_parser = new ScriptParser(f._tokenizer, f._sqlite_parser);
            f._notebook_serializer = new NotebookSerializer(f._temp_folder);

            var scalar_functions = new Gee.ArrayList<ScalarFunction>();
            // ArrayFunctions
            scalar_functions.add(new ArrayAppendFunction());
            scalar_functions.add(new ArrayConcat1Function());
            scalar_functions.add(new ArrayConcat2Function());
            scalar_functions.add(new ArrayCountFunction());
            scalar_functions.add(new ArrayFunction());
            scalar_functions.add(new ArrayGetFunction());
            scalar_functions.add(new ArrayInsertFunction());
            scalar_functions.add(new ArrayMergeFunction());
            scalar_functions.add(new ArraySetFunction());
            // MonadicMathFunctions
            scalar_functions.add(new AcosFunction());
            scalar_functions.add(new AsinFunction());
            scalar_functions.add(new AtanFunction());
            scalar_functions.add(new CeilingFunction());
            scalar_functions.add(new CosFunction());
            scalar_functions.add(new CoshFunction());
            scalar_functions.add(new ExpFunction());
            scalar_functions.add(new FloorFunction());
            scalar_functions.add(new LogFunction());
            scalar_functions.add(new Log10Function());
            scalar_functions.add(new RoundFunction());
            scalar_functions.add(new SignFunction());
            scalar_functions.add(new SinFunction());
            scalar_functions.add(new SinhFunction());
            scalar_functions.add(new SqrtFunction());
            scalar_functions.add(new TanFunction());
            scalar_functions.add(new TanhFunction());
            // DyadicMathFunctions
            scalar_functions.add(new Atan2Function());
            scalar_functions.add(new PowFunction());
            f._scalar_functions = scalar_functions.read_only_view;

            MatchResult.init();

            return f;
        }

        public string get_app_version() {
            return "1.0.0";
        }

        public Notebook new_notebook() throws RuntimeError {
            var file_path = _temp_folder.get_temp_file_path(".db");
            var session = new SqliteSession(file_path, true, _scalar_functions);
            var user_data = new NotebookUserData();
            var notebook = new Notebook(null, file_path, session, user_data, _notebook_serializer);
            session.open(notebook);
            return notebook;
        }

        public Notebook open_notebook(string notebook_file_path) throws RuntimeError {
            string sqlite_db_file_path;
            NotebookUserData user_data;
            _notebook_serializer.open_notebook(notebook_file_path, out sqlite_db_file_path, out user_data);

            var session = new SqliteSession(sqlite_db_file_path, false, _scalar_functions);
            var notebook = new Notebook(notebook_file_path, sqlite_db_file_path, session, user_data, _notebook_serializer);
            session.open(notebook);
            return notebook;
        }

        public ScriptEnvironment get_script_environment() {
            return new ScriptEnvironment();
        }

        public ScriptParser get_script_parser() {
            return _script_parser;
        }

        public ScriptRunner get_script_runner(Notebook notebook, NotebookLockToken token) {
            return new ScriptRunner(notebook, token);
        }

        public Gee.BidirList<ScalarFunction> get_scalar_functions() {
            return _scalar_functions;
        }
    }
}
