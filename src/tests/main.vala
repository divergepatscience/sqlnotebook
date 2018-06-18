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

using SqlNotebook.Tests;

void main(string[] args) {
    var modules = new TestModule[] {
        new Test_ScriptParser(),
        new Test_Tokenizer(),
        new Test_TokenQueue(),
        new Test_Scripts(),
        new Test_Sanity()
    };

    // change these values to run a single test rather than the whole suite
    var run_single_test = false;
    var single_module = "ScriptParser";
    var single_test = "simple_print";
    // ---

    var failures = 0;
    var successes = 0;
    foreach (var module in modules) {
        if (run_single_test) {
            if (module.get_name() == single_module) {
                module.single_test = single_test;
            } else {
                continue;
            }
        }

        try {
            module.module_pre();
            module.go();
            failures += module.failures;
            successes += module.successes;
        } catch (Error e) {
            stderr.printf("Uncaught error in test harness. %s\n", e.message);
        } finally {
            module.module_post();
        }
    }

    stderr.printf("Passed tests: %d\n", successes);
    if (failures > 0) {
        stderr.printf("Failed tests: %d\n", failures);
    }
}
