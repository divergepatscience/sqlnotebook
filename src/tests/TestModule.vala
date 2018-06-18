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

namespace SqlNotebook.Tests {
    public abstract class TestModule : Object {
        public delegate void TestAction() throws Error;

        public abstract void go();
        public abstract string get_name();

        public virtual void module_pre() throws Error {
        }

        public virtual void module_post() {
        }

        public virtual void test_pre() throws Error {
        }

        public virtual void test_post() {
        }

        public int failures = 0;
        public int successes = 0;
        public string? single_test = null;

        protected void test(string name, TestAction action) {
            if (single_test != null && single_test != name) {
                return;
            }

            try {
                test_pre();
                action();
                successes++;
            } catch (Error e) {
                stderr.printf("FAIL: %s/%s\n", get_name(), name);
                stderr.printf("\t%s\n", e.message);
                failures++;
            } finally {
                test_post();
            }
        }

        protected void assert_true(bool actual, string description) throws TestError {
            if (actual != true) {
                throw new TestError.FAILED(@"$description, actual=false, expected=true");
            }
        }

        protected void assert_false(bool actual, string description) throws TestError {
            if (actual != false) {
                throw new TestError.FAILED(@"$description, actual=true, expected=false");
            }
        }

        protected void assert_eq_int(int actual, int expected, string description) throws TestError {
            if (actual != expected) {
                throw new TestError.FAILED(@"$description, actual=$actual, expected=$expected");
            }
        }

        protected void assert_eq_string(string actual, string expected, string description) throws TestError {
            if (actual != expected) {
                throw new TestError.FAILED(@"$description, actual=\"$actual\", expected=\"$expected\"");
            }
        }
    }
}
