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

namespace SqlNotebook.Utils.ArgUtil {
    public int64 get_int_arg(DataValue arg, string param_name, string function_name) throws RuntimeError {
        if (arg.kind == DataValueKind.INTEGER) {
            return arg.integer_value;
        } else {
            var actual_kind = arg.get_kind_name();
            throw new RuntimeError.WRONG_ARGUMENT_KIND(
                    @"$function_name: The \"$param_name\" argument must be an INTEGER value, but type $actual_kind " +
                    @"was provided.");
        }
    }

    public int32 get_int32_arg(DataValue arg, string param_name, string function_name) throws RuntimeError {
        var value64 = get_int_arg(arg, param_name, function_name);
        if (value64 < int32.MIN || value64 > int32.MAX) {
            throw new RuntimeError.WRONG_ARGUMENT_KIND(
                    @"$function_name: The \"$param_name\" argument is out of range.  A 32-bit INTEGER value " +
                    @"is required.");
        }

        return (int32)value64;
    }

    public double get_real_arg(DataValue arg, string param_name, string function_name) throws RuntimeError {
        if (arg.kind == DataValueKind.REAL) {
            return arg.real_value;
        } else if (arg.kind == DataValueKind.INTEGER) {
            return arg.integer_value;
        } else {
            var actual_kind = arg.get_kind_name();
            throw new RuntimeError.WRONG_ARGUMENT_KIND(
                    @"$function_name: The \"$param_name\" argument must be a REAL value, but type $actual_kind was " +
                    @"provided.");
        }
    }

    public DataValueBlob get_blob_arg(DataValue arg, string param_name, string function_name) throws RuntimeError {
        if (arg.kind == DataValueKind.BLOB) {
            return arg.blob_value;
        } else {
            var actual_kind = arg.get_kind_name();
            throw new RuntimeError.WRONG_ARGUMENT_KIND(
                    @"$function_name: The \"$param_name\" argument must be a BLOB value, but type $actual_kind " +
                    @"was provided.");
        }
    }

    public DataValueBlob get_blob_array_arg(DataValue arg, string param_name, string function_name) throws RuntimeError {
        var blob = get_blob_arg(arg, param_name, function_name);
        if (SqlArrayUtil.is_sql_array(blob)) {
            return blob;
        } else {
            throw new RuntimeError.WRONG_ARGUMENT_KIND(
                    @"$function_name: The \"$param_name\" argument must be an array value, but a non-array BLOB " +
                    @"was provided.");
        }
    }

    public string get_text_arg(DataValue arg, string param_name, string function_name) throws RuntimeError {
        if (arg.kind == DataValueKind.TEXT) {
            return arg.text_value;
        } else {
            var actual_kind = arg.get_kind_name();
            throw new RuntimeError.WRONG_ARGUMENT_KIND(
                    @"$function_name: The \"$param_name\" argument must be a TEXT value, but type $actual_kind " +
                    @"was provided.");
        }
    }
}
