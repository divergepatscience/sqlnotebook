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

using SqlNotebook.Collections;
using SqlNotebook.Errors;
using SqlNotebook.Utils;

namespace SqlNotebook.Interpreter.ScalarFunctions.ArrayFunctions {
    public class ArrayAppendFunction : ScalarFunction {
        public override string get_name() {
            return "array_append";
        }

        public override int get_parameter_count() {
            return -1;
        }

        public override bool is_deterministic() {
            return true;
        }

        public override DataValue execute(Gee.ArrayList<DataValue> args) throws RuntimeError {
            var name = get_name();

            if (args.size < 2) {
                throw new RuntimeError.WRONG_ARGUMENT_COUNT(@"$name: At least 2 arguments are required.");
            }

            var blob = ArgUtil.get_blob_array_arg(args[0], "array", name);
            var old_count = SqlArrayUtil.get_count(blob);
            var insert_count = args.size - 1;
            var new_count = old_count + insert_count;

            var elements = new DataValue[new_count];
            var index = 0;

            for (var i = 0; i < old_count; i++) {
                elements[index++] = SqlArrayUtil.get_element(blob, i);
            }

            for (var i = 0; i < insert_count; i++) {
                elements[index++] = args[1 + i];
            }

            return SqlArrayUtil.create_sql_array(new Gee.ArrayList<DataValue>.wrap(elements));
        }
    }
}
