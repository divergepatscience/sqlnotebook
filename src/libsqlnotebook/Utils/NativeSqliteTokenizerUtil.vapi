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

[CCode(cheader_filename = "sqlite3.h")]
namespace SqlNotebook.Utils.NativeSqliteTokenizerUtil {
    // void sqlite3_tokenizer_start(const char* z);
    [CCode(cname = "sqlite3_tokenizer_start")]
    int start(string z);

    // int sqlite3_tokenizer_next();
    [CCode(cname = "sqlite3_tokenizer_next")]
    int next();

    // int sqlite3_tokenizer_get_token_type();
    [CCode(cname = "sqlite3_tokenizer_get_token_type")]
    int get_token_type();

    // int sqlite3_tokenizer_get_token_char_offset();
    [CCode(cname = "sqlite3_tokenizer_get_token_char_offset")]
    int get_token_char_offset();

    // int sqlite3_tokenizer_get_token_char_length();
    [CCode(cname = "sqlite3_tokenizer_get_token_char_length")]
    int get_token_char_length();

    // void sqlite3_tokenizer_end();
    [CCode(cname = "sqlite3_tokenizer_end")]
    void end();
}
