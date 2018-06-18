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

namespace SqlNotebook.Interpreter.Tokens {
    public class Tokenizer : Object {
        private static Mutex _lock = Mutex();

        public ArrayList<Token> tokenize(string input) {
            var list = new ArrayList<Token>();

            _lock.@lock();
            try {
                NativeSqliteTokenizerUtil.start(input);

                while (NativeSqliteTokenizerUtil.next() != 0) {
                    var token_type = NativeSqliteTokenizerUtil.get_token_type();
                    var char_offset = NativeSqliteTokenizerUtil.get_token_char_offset();
                    var char_length = NativeSqliteTokenizerUtil.get_token_char_length();
                    var text = input.substring(char_offset, char_length);
                    var token = Token.for_token((TokenKind)token_type, text, char_offset, char_length);
                    list.add(token);
                }

                NativeSqliteTokenizerUtil.end();
            } finally {
                _lock.unlock();
            }
            return list;
        }
    }
}
