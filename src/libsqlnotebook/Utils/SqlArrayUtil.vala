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

namespace SqlNotebook.Utils.SqlArrayUtil {
    // the blob format for arrays is:
    //
    // - 4 bytes: sentinel bytes starting with NUL
    // - 32-bit integer: number of elements
    // - 9 bytes per element:
    // - 1 byte: DataValueKind
    // - for null: eight bytes of zeroes
    // - for integer: the 64-bit integer value
    // - for float: the 64-bit float value
    // - for text or blob: index into the blob where the data starts.  at that index is a 32-bit length (not
    // including the length value itself) followed by the string (NOT nul terminated) or binary data.
    // - (area where text and blob data goes if present)
    //
    // all integers and floating point values in the native encoding.

    private const uint8[] SENTINEL = { 0x00, 0xCE, 0x49, 0xA6 };
    private const int SENTINEL_LENGTH = 4;
    private const int COUNT_OFFSET = 4;
    private const int ELEMENTS_OFFSET = 8;
    private const int ELEMENT_LENGTH = 9;

    public bool is_sql_array(DataValueBlob blob) {
        if (blob.bytes.length < ELEMENTS_OFFSET) {
            return false;
        } else {
            return Posix.memcmp(blob.bytes, SENTINEL, SENTINEL_LENGTH) == 0;
        }
    }

    public DataValue create_sql_array(Gee.List<DataValue> values) {
        // first count exactly how many bytes we need
        var num_bytes = ELEMENTS_OFFSET + ELEMENT_LENGTH * values.size;
        foreach (var value in values) {
            if (value.kind == DataValueKind.BLOB) {
                num_bytes += (int)sizeof(int32); // for the size
                num_bytes += value.blob_value.bytes.length; // for the blob bytes
            } else if (value.kind == DataValueKind.TEXT) {
                num_bytes += (int)sizeof(int32); // for the size
                num_bytes += value.text_value.length; // for the text bytes
            }
        }

        // now build the array
        var blob = new DataValueBlob() {
            bytes = new uint8[num_bytes]
        };

        Posix.memset(blob.bytes, 0, num_bytes); // not necessary because we should write to every location

        var element_offset = 0;
        var data_offset = ELEMENTS_OFFSET + ELEMENT_LENGTH * values.size;

        write_bytes(blob.bytes, ref element_offset, SENTINEL);
        write_int32(blob.bytes, ref element_offset, values.size);

        foreach (var value in values) {
            write_int8(blob.bytes, ref element_offset, (int8)value.kind);

            switch (value.kind) {
                case DataValueKind.BLOB:
                    write_int64(blob.bytes, ref element_offset, data_offset);
                    write_int32(blob.bytes, ref data_offset, value.blob_value.bytes.length);
                    write_bytes(blob.bytes, ref data_offset, value.blob_value.bytes);
                    break;

                case DataValueKind.INTEGER:
                    write_int64(blob.bytes, ref element_offset, value.integer_value);
                    break;

                case DataValueKind.NULL:
                    write_int64(blob.bytes, ref element_offset, 0);
                    break;

                case DataValueKind.REAL:
                    write_double(blob.bytes, ref element_offset, value.real_value);
                    break;

                case DataValueKind.TEXT:
                    write_int64(blob.bytes, ref element_offset, data_offset);
                    write_int32(blob.bytes, ref data_offset, value.text_value.length);
                    write_text(blob.bytes, ref data_offset, value.text_value);
                    break;

                default:
                    assert(false);
                    break;
            }
        }

        return DataValue.for_blob(blob);
    }

    private void write_text(uint8[] dst, ref int dst_offset, string src) {
        Posix.memcpy(&dst[dst_offset], src, src.length);
        dst_offset += src.length;
    }

    private void write_bytes(uint8[] dst, ref int dst_offset, uint8[] src) {
        Posix.memcpy(&dst[dst_offset], src, src.length);
        dst_offset += src.length;
    }

    private void write_int8(uint8[] dst, ref int dst_offset, int8 src) {
        Posix.memcpy(&dst[dst_offset], &src, sizeof(int8));
        dst_offset += (int)sizeof(int8);
    }

    private void write_int32(uint8[] dst, ref int dst_offset, int32 src) {
        Posix.memcpy(&dst[dst_offset], &src, sizeof(int32));
        dst_offset += (int)sizeof(int);
    }

    private void write_int64(uint8[] dst, ref int dst_offset, int64 src) {
        Posix.memcpy(&dst[dst_offset], &src, sizeof(int64));
        dst_offset += (int)sizeof(int64);
    }

    private void write_double(uint8[] dst, ref int dst_offset, double src) {
        Posix.memcpy(&dst[dst_offset], &src, sizeof(double));
        dst_offset += (int)sizeof(double);
    }

    public int get_count(DataValueBlob blob) {
        int32 count = 0;
        Posix.memcpy(&count, &blob.bytes[COUNT_OFFSET], sizeof(int32));
        return (int)count;
    }

    public DataValue get_element(DataValueBlob blob, int index) {
        var element_offset = ELEMENTS_OFFSET + index * ELEMENT_LENGTH;

        // read the element type
        int8 kind_byte = 0;
        Posix.memcpy(&kind_byte, &blob.bytes[element_offset], sizeof(int8));
        var kind = (DataValueKind)kind_byte;
        element_offset++;

        // read the element value
        switch (kind) {
            case DataValueKind.BLOB:
                return get_element_blob(blob, element_offset);

            case DataValueKind.INTEGER:
                int64 integer_value = 0;
                Posix.memcpy(&integer_value, &blob.bytes[element_offset], sizeof(int64));
                return DataValue.for_integer(integer_value);

            case DataValueKind.NULL:
                return DataValue.for_null();

            case DataValueKind.REAL:
                double real_value = 0;
                Posix.memcpy(&real_value, &blob.bytes[element_offset], sizeof(double));
                return DataValue.for_real(real_value);

            case DataValueKind.TEXT:
                return get_element_text(blob, element_offset);

            default:
                assert(false);
                return DataValue.for_null();
        }
    }

    private DataValue get_element_blob(DataValueBlob blob, int element_offset) {
        int64 data_offset = 0;
        Posix.memcpy(&data_offset, &blob.bytes[element_offset], sizeof(int64));

        int32 length = 0;
        Posix.memcpy(&length, &blob.bytes[data_offset], sizeof(int32));
        data_offset += (int)sizeof(int32);

        var element_blob = new DataValueBlob() {
            bytes = new uint8[length]
        };

        Posix.memcpy(element_blob.bytes, &blob.bytes[data_offset], length);

        return DataValue.for_blob(element_blob);
    }

    private DataValue get_element_text(DataValueBlob blob, int element_offset) {
        int64 data_offset = 0;
        Posix.memcpy(&data_offset, &blob.bytes[element_offset], sizeof(int64));

        int32 length = 0;
        Posix.memcpy(&length, &blob.bytes[data_offset], sizeof(int32));
        data_offset += (int)sizeof(int32);

        var buffer = new StringBuilder.sized(length + 1);
        Posix.memcpy(buffer.data, &blob.bytes[data_offset], length);
        buffer.data[length] = 0;

        return DataValue.for_text(buffer.str);
    }

    public string string_join(DataValueBlob blob, string? separator) {
        var count = SqlArrayUtil.get_count(blob);
        var sb = new StringBuilder();

        for (var i = 0; i < count; i++) {
            if (separator != null && i > 0) {
                sb.append(separator);
            }

            var element = get_element(blob, i);
            sb.append(element.to_literal_string());
        }

        return sb.str;
    }
}
