/* SQL Notebook
 * Copyright (C) 2018 Brian Luft
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 * OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <linenoise.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "NativeCommandPrompt.h"

struct CommandPrompt {
    int unused;
};

CommandPrompt* command_prompt_create(void) {
    CommandPrompt* self = NULL;

    self = calloc(1, sizeof(CommandPrompt));

    linenoiseInstallWindowChangeHandler();

    return self;
}

void command_prompt_delete(CommandPrompt* self) {
    free(self);
}

char* command_prompt_get_line(CommandPrompt* self) {
    return linenoise("sqlnotebook> ");
}

void command_prompt_add_history(CommandPrompt* self, const char* line) {
    linenoiseHistoryAdd(line);
}