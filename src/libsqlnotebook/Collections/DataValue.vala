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
using SqlNotebook.Utils;

namespace SqlNotebook.Collections {
    public class DataValue : Object {
        public DataValueKind kind;
        public int64 integer_value;
        public double real_value;
        public string? text_value;
        public DataValueBlob? blob_value;

        public static DataValue for_null() {
            var x = new DataValue() {
                kind = DataValueKind.NULL
            };
            return x;
        }

        public static DataValue for_integer(int64 value) {
            var x = new DataValue() {
                kind = DataValueKind.INTEGER,
                integer_value = value
            };
            return x;
        }

        public static DataValue for_real(double value) {
            var x = new DataValue() {
                kind = DataValueKind.REAL,
                real_value = value
            };
            return x;
        }

        public static DataValue for_text(string value) {
            var x = new DataValue() {
                kind = DataValueKind.TEXT,
                text_value = value
            };
            return x;
        }

        public static DataValue for_blob(DataValueBlob value) {
            var x = new DataValue() {
                kind = DataValueKind.BLOB,
                blob_value = value
            };
            return x;
        }

        /**
         * Converts the value into a "raw" string suitable for concatenation or other operations.
         * @return String representation of the value
         */
        public string to_literal_string() {
            switch (kind) {
                case DataValueKind.NULL:
                    return "";

                case DataValueKind.INTEGER:
                    return @"$integer_value";

                case DataValueKind.REAL:
                    return @"$real_value";

                case DataValueKind.TEXT:
                    return text_value;

                case DataValueKind.BLOB:
                    return "";

                default:
                    assert(false);
                    return "";
            }
        }

        /**
         * Converts the value into a descriptive string suitable for display in a grid.
         * @return String representation of the value
         */
        public string to_string() {
            switch (kind) {
                case DataValueKind.NULL:
                    return "(null)";

                case DataValueKind.INTEGER:
                    return @"$integer_value";

                case DataValueKind.REAL:
                    return @"$real_value";

                case DataValueKind.TEXT:
                    return text_value.replace("\r\n", " ").replace("\r", " ").replace("\n", " ");

                case DataValueKind.BLOB:
                    return blob_to_string();

                default:
                    assert(false);
                    return "(unknown kind)";
            }
        }

        private string blob_to_string() {
            if (SqlArrayUtil.is_sql_array(blob_value)) {
                return "[%s]".printf(SqlArrayUtil.string_join(blob_value, ", "));
            } else {
                return "(blob of %d bytes)".printf(blob_value.bytes.length);
            }
        }

        public string get_kind_name() {
            switch (kind) {
                case DataValueKind.INTEGER:
                    return "INTEGER";

                case DataValueKind.REAL:
                    return "REAL";

                case DataValueKind.TEXT:
                    return "TEXT";

                case DataValueKind.NULL:
                    return "NULL";

                case DataValueKind.BLOB:
                    return "BLOB";

                default:
                    assert(false);
                    return "(unknown kind)";
            }
        }

        internal static DataValue for_sqlite_value(Sqlite.Value x) {
            switch (x.to_type()) {
                case Sqlite.INTEGER:
                    return for_integer(x.to_int64());

                case Sqlite.FLOAT:
                    return for_real(x.to_double());

                case Sqlite.TEXT:
                    return for_text(x.to_text());

                case Sqlite.BLOB:
                    var blob_length = x.to_bytes();
                    var blob = new DataValueBlob() {
                        bytes = new uint8[blob_length]
                    };
                    Posix.memcpy(blob.bytes, x.to_blob(), blob_length);
                    return for_blob(blob);

                case Sqlite.NULL:
                    return for_null();

                default:
                    assert(false);
                    return for_null();
            }
        }

        internal void set_as_sqlite_result(Sqlite.Context context) {
            switch (kind) {
                case DataValueKind.INTEGER:
                    context.result_int64(integer_value);
                    break;

                case DataValueKind.REAL:
                    context.result_double(real_value);
                    break;

                case DataValueKind.TEXT:
                    context.result_text(text_value);
                    break;

                case DataValueKind.NULL:
                    context.result_null();
                    break;

                case DataValueKind.BLOB:
                    context.result_blob(blob_value.bytes);
                    break;

                default:
                    assert(false);
                    break;
            }
        }
    }
}
