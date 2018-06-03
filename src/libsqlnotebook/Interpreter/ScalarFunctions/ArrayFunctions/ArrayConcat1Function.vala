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
    public class ArrayConcat1Function : ScalarFunction {
        public override string get_name() {
            return "array_concat";
        }

        public override int get_parameter_count() {
            return 1;
        }

        public override bool is_deterministic() {
            return true;
        }

        public override DataValue execute(Gee.ArrayList<DataValue> args) throws RuntimeError {
            var name = get_name();
            var blob = ArgUtil.get_blob_array_arg(args[0], "array", name);
            return DataValue.for_text(SqlArrayUtil.string_join(blob, null));
        }
    }
}
