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

namespace SqlNotebook.Tests {
    public class Test_Scripts : TestModule {
        private ArrayList<TestScript> _scripts;

        private class TestScript : Object {
            public string name;
            public string expected_output;
            public string code;
        }

        private LibraryFactory _library_factory;
        private ScriptEnvironment _script_environment;
        private ScriptParser _script_parser;
        private Notebook _notebook;
        private NotebookLockToken _token;

        public override string get_name() {
            return "Scripts";
        }

        public override void module_pre() throws Error {
            var dir = "/source/src/tests/scripts";
            var scripts_dir_file = File.new_for_path(dir);
            var children_enumerator = scripts_dir_file.enumerate_children("standard::*",
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS);

            _scripts = new ArrayList<TestScript>();
            FileInfo dir_info;
            while ((dir_info = children_enumerator.next_file()) != null) {
                if (dir_info.get_file_type() == FileType.REGULAR) {
                    var script_file_path = Path.build_filename(dir, dir_info.get_name());
                    var script_file = File.new_for_path(script_file_path);
                    var stream = new DataInputStream(script_file.read());
                    size_t length;
                    var script_text = stream.read_upto("", 0, out length);
                    var script = new TestScript() {
                        name = script_file.get_basename(),
                        expected_output = parse_expected_output(script_text),
                        code = script_text
                    };
                    _scripts.add(script);
                }
            }
        }

        public override void module_post() {
            _scripts = null;
        }

        public override void test_pre() throws Error {
            _library_factory = LibraryFactory.create();
            _script_environment = _library_factory.get_script_environment();
            _script_parser = _library_factory.get_script_parser();
            _notebook = _library_factory.new_notebook();
            _token = _notebook.enter();
        }

        public override void test_post() {
            if (_notebook != null && _token != null) {
                _notebook.exit(_token);
            }
            _library_factory = null;
            _script_environment = null;
            _script_parser = null;
            _notebook = null;
            _token = null;
        }

        public override void go() {
            foreach (var script in _scripts) {
                test(script.name, () => {
                    var script_node = _script_parser.parse(script.code);
                    var script_runner = _library_factory.get_script_runner(_notebook, _token);
                    var args = new HashMap<string, DataValue>();
                    var expected = script.expected_output.strip();

                    try {
                        var script_output = script_runner.execute(script_node, args, _script_environment);
                        var actual = StringUtil.join_strings("\n", script_output.text_output).strip();

                        if (actual != expected) {
                            var indented_actual = indent(actual);
                            var indented_expected = indent(expected);
                            throw new TestError.FAILED(@"actual:\n$indented_actual\n\texpected:\n$indented_expected");
                        }
                    } catch (RuntimeError e) {
                        if (expected == "error") {
                            // we expected this to fail
                        } else {
                            throw e;
                        }
                    }
                });
            }
        }

        private string parse_expected_output(string input) {
            var stripped_input = input.strip();

            // the expected output is in a C-style comment at the top.
            if (!stripped_input.has_prefix("/*")) {
                return "";
            } else {
                var end_index = stripped_input.index_of("*/");
                if (end_index == -1) {
                    return "";
                } else {
                    return stripped_input.substring(2, end_index - 2);
                }
            }
        }

        private string indent(string a) {
            return "\t" + a.replace("\n", "\n\t");
        }
    }
}
