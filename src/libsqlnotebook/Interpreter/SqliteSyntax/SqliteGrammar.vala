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
using SqlNotebook.Interpreter.Tokens;
using SqlNotebook.Utils;

namespace SqlNotebook.Interpreter.SqliteSyntax {
    public class SqliteGrammar : Object {
        public HashMap<string, SpecProd> prods { get; private set; }

        public SqliteGrammar() {
            string p;

            prods = new HashMap<string, SpecProd>();

            // sql-stmt ::= [ EXPLAIN [ QUERY PLAN ] ] ( <alter-table-stmt> | <analyze-stmt> | <attach-stmt> |
            // <begin-stmt> | <commit-stmt> | <create-index-stmt> | <create-table-stmt> | <create-trigger-stmt> |
            // <create-view-stmt> | <create-virtual-table-stmt> | <delete-stmt> |
            // <detach-stmt> | <drop-index-stmt> | <drop-table-stmt> | <drop-trigger-stmt> | <drop-view-stmt> |
            // <insert-stmt> | <pragma-stmt> | <reindex-stmt> | <release-stmt> | <rollback-stmt> |
            // <savepoint-stmt> | <select-stmt> | <update-stmt> | <update-stmt-limited> | <vacuum-stmt> )
            p = "sql-stmt";
            top_prod(p, 2, new SpecTerm[] {
                opt(1, new SpecTerm[] {
                    tok(TokenKind.EXPLAIN),
                    opt(1, new SpecTerm[] {
                        tok(TokenKind.QUERY),
                        tok(TokenKind.PLAN)
                    })
                }),
                or_terms(new SpecTerm[] {
                    sub_prod("select-stmt"),
                    sub_prod("update-stmt"),
                    sub_prod("insert-stmt"),
                    sub_prod("alter-table-stmt"),
                    sub_prod("analyze-stmt"),
                    sub_prod("attach-stmt"),
                    sub_prod("begin-stmt"),
                    sub_prod("commit-stmt"),
                    sub_prod("create-index-stmt"),
                    sub_prod("create-table-stmt"),
                    sub_prod("create-trigger-stmt"),
                    sub_prod("create-view-stmt"),
                    sub_prod("create-virtual-table-stmt"),
                    sub_prod("delete-stmt"),
                    sub_prod("detach-stmt"),
                    sub_prod("drop-index-stmt"),
                    sub_prod("drop-table-stmt"),
                    sub_prod("drop-trigger-stmt"),
                    sub_prod("drop-view-stmt"),
                    sub_prod("pragma-stmt"),
                    sub_prod("reindex-stmt"),
                    sub_prod("release-stmt"),
                    sub_prod("rollback-stmt"),
                    sub_prod("savepoint-stmt"),
                    sub_prod("vacuum-stmt")
                })
            });

            // alter-table-stmt ::=
            // ALTER TABLE [ database-name "." ] table-name
            // ( RENAME TO new-table-name ) | ( ADD [COLUMN] <column-def> )
            p = "alter-table-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.ALTER),
                tok(TokenKind.TABLE),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("table name"),
                or_prods(new SpecProd[] {
                    prod(@"$p.rename", 1, new SpecTerm[] {
                        tok(TokenKind.RENAME),
                        tok(TokenKind.TO),
                        id("new table name")
                    }),
                    prod(@"$p.add", 1, new SpecTerm[] {
                        tok(TokenKind.ADD),
                        opt_one(tok(TokenKind.COLUMNKW)),
                        sub_prod("column-def")
                    })
                })
            });

            // analyze-stmt ::= ANALYZE [ database-table-index-name [ "." table-or-index-name ] ]
            p = "analyze-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.ANALYZE),
                opt_all(new SpecTerm[] {
                    id("database, table, or index name"),
                    opt(1, new SpecTerm[] {
                        tok(TokenKind.DOT),
                        id("table or index name")
                    })
                })
            });

            // attach-stmt ::= ATTACH [ DATABASE ] <expr> AS database-name
            p = "attach-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.ATTACH),
                opt_one(tok(TokenKind.DATABASE)),
                sub_prod("expr"),
                tok(TokenKind.AS),
                id("database name")
            });

            // begin-stmt ::= BEGIN [ DEFERRED | IMMEDIATE | EXCLUSIVE ] [ TRANSACTION ]
            p = "begin-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.BEGIN),
                opt_all(new SpecTerm[] {
                    or_terms(new SpecTerm[] {
                        tok(TokenKind.DEFERRED),
                        tok(TokenKind.IMMEDIATE),
                        tok(TokenKind.EXCLUSIVE)
                    })
                }),
                opt_one(tok(TokenKind.TRANSACTION))
            });

            // commit-stmt ::= ( COMMIT | END ) [ TRANSACTION ]
            p = "commit-stmt";
            top_prod(p, 1, new SpecTerm[] {
                or_terms(new SpecTerm[] {
                    tok(TokenKind.COMMIT),
                    tok(TokenKind.END)
                }),
                opt_one(tok(TokenKind.TRANSACTION))
            });

            // rollback-stmt ::= ROLLBACK [ TRANSACTION ] [ TO [ SAVEPOINT ] savepoint-name ]
            p = "rollback-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.ROLLBACK),
                opt_one(tok(TokenKind.TRANSACTION)),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.TO),
                    opt_one(tok(TokenKind.SAVEPOINT)),
                    id("savepoint name")
                })
            });

            // savepoint-stmt ::= SAVEPOINT savepoint-name
            p = "savepoint-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.SAVEPOINT),
                id("savepoint name")
            });

            // release-stmt ::= RELEASE [ SAVEPOINT ] savepoint-name
            p = "release-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.RELEASE),
                opt_one(tok(TokenKind.SAVEPOINT)),
                id("savepoint name")
            });

            // create-index-stmt ::= CREATE [ UNIQUE ] INDEX [ IF NOT EXISTS ]
            // [ database-name "." ] index-name ON table-name "(" <indexed-column> [ "," <indexed-column> ]* ")"
            // [ WHERE <expr> ]
            p = "create-index-stmt";
            top_prod(p, 3, new SpecTerm[] {
                tok(TokenKind.CREATE),
                opt_one(tok(TokenKind.UNIQUE)),
                tok(TokenKind.INDEX),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.NOT),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("index name"),
                tok(TokenKind.ON),
                id("table name"),
                tok(TokenKind.LP),
                lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                    sub_prod("indexed-column")
                }),
                tok(TokenKind.RP),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.WHERE),
                    sub_prod("expr")
                })
            });

            // indexed-column ::= ( column-name | expr ) [ COLLATE collation-name ] [ ASC | DESC ]
            p = "indexed-column";
            top_prod(p, 1, new SpecTerm[] {
                or_terms(new SpecTerm[] {
                    sub_prod("expr"),
                    id("column name")
                }),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.COLLATE),
                    id("collation name")
                }),
                opt_all(new SpecTerm[] {
                    or_terms(new SpecTerm[] {
                        tok(TokenKind.ASC),
                        tok(TokenKind.DESC)
                    })
                })
            });

            // create-table-stmt ::= CREATE [ TEMP | TEMPORARY ] TABLE [ IF NOT EXISTS ]
            // [database-name "."] table-name
            // (
            // "(" <column-def> [ "," <column-def> ]* [ "," <table-constraint> ]* ")" [WITHOUT ROWID]
            // | AS <select-stmt>
            // )
            p = "create-table-stmt";
            top_prod(p, 3, new SpecTerm[] {
                tok(TokenKind.CREATE),
                opt_all(new SpecTerm[] {
                    or_terms(new SpecTerm[] {
                        tok(TokenKind.TEMP),
                        tok_str("temporary")
                    })
                }),
                tok(TokenKind.TABLE),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.NOT),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("table name"),
                or_prods(new SpecProd[] {
                    prod(@"$p.column-defs", 1, new SpecTerm[] {
                        tok(TokenKind.LP),
                        lst(@"$p.def", TokenKind.COMMA, 1, new SpecTerm[] {
                            or_terms(new SpecTerm[] {
                                sub_prod("table-constraint"),
                                sub_prod("column-def")
                            })
                        }),
                        // this definition allows column definitions to appear after table constraints,
                        // which is illegal.
                        // it would be nice to improve here.
                        tok(TokenKind.RP),
                        opt(1, new SpecTerm[] {
                            tok(TokenKind.WITHOUT),
                            tok_str("rowid")
                        })
                    }),
                    prod(@"$p.as", 1, new SpecTerm[] {
                        tok(TokenKind.AS),
                        sub_prod("select-stmt")
                    })
                })
            });

            // column-def ::= column-name [ <type-name> ] [ <column-constraint> ]*
            p = "column-def";
            var column_def_token_kinds = new TokenKind[] {
                TokenKind.ABORT,
                TokenKind.ASC,
                TokenKind.BEGIN,
                TokenKind.CONFLICT,
                TokenKind.DESC,
                TokenKind.END,
                TokenKind.EXPLAIN,
                TokenKind.FAIL,
                TokenKind.IGNORE,
                TokenKind.KEY,
                TokenKind.OFFSET,
                TokenKind.PRAGMA,
                TokenKind.REPLACE,
                TokenKind.TEMP,
                TokenKind.VACUUM,
                TokenKind.VIEW
            };
            top_prod(p, 1, new SpecTerm[] {
                or_terms(new SpecTerm[] {
                    id("column name"),
                    // per SQLite test suite file misc1.test, these are valid to use as column names
                    toks(column_def_token_kinds)
                }),
                opt_one(sub_prod("type-name")),
                lst(@"$p.constraint", null, 0, new SpecTerm[] {
                    sub_prod("column-constraint")
                })
            });

            // type-name ::= name+ [ "(" <signed-number> ")" | "(" <signed-number> "," <signed-number> ")" ]
            // implemented as: name+ [ "(" <signed-number> [ "," <signed-number> ] ")" ]
            p = "type-name";
            var type_name_token_kinds = new TokenKind[] {
                TokenKind.EXPLAIN,
                TokenKind.QUERY,
                TokenKind.PLAN,
                TokenKind.BEGIN,
                TokenKind.DEFERRED,
                TokenKind.IMMEDIATE,
                TokenKind.EXCLUSIVE,
                TokenKind.END,
                TokenKind.ROLLBACK,
                TokenKind.SAVEPOINT,
                TokenKind.RELEASE,
                TokenKind.IF,
                TokenKind.TEMP,
                TokenKind.WITHOUT,
                TokenKind.ABORT,
                TokenKind.ACTION,
                TokenKind.AFTER,
                TokenKind.ANALYZE,
                TokenKind.ASC,
                TokenKind.ATTACH,
                TokenKind.BEFORE,
                TokenKind.BY,
                TokenKind.CASCADE,
                TokenKind.CAST,
                TokenKind.COLUMNKW,
                TokenKind.CONFLICT,
                TokenKind.DATABASE,
                TokenKind.DESC,
                TokenKind.DETACH,
                TokenKind.EACH,
                TokenKind.FAIL,
                TokenKind.FOR,
                TokenKind.IGNORE,
                TokenKind.INITIALLY,
                TokenKind.INSTEAD,
                TokenKind.LIKE_KW,
                TokenKind.MATCH,
                TokenKind.NO,
                TokenKind.KEY,
                TokenKind.OF,
                TokenKind.OFFSET,
                TokenKind.PRAGMA,
                TokenKind.RAISE,
                TokenKind.RECURSIVE,
                TokenKind.REPLACE,
                TokenKind.RESTRICT,
                TokenKind.ROW,
                TokenKind.TRIGGER,
                TokenKind.VACUUM,
                TokenKind.VIEW,
                TokenKind.VIRTUAL,
                TokenKind.WITH,
                TokenKind.REINDEX,
                TokenKind.RENAME,
                TokenKind.CTIME_KW,
                TokenKind.ANY,
                TokenKind.REM,
                TokenKind.CONCAT,
                TokenKind.AUTOINCR,
                TokenKind.DEFERRABLE,
                TokenKind.TO_TEXT,
                TokenKind.TO_BLOB,
                TokenKind.TO_NUMERIC,
                TokenKind.TO_INT,
                TokenKind.TO_REAL,
                TokenKind.ISNOT,
                TokenKind.FUNCTION,
                TokenKind.AGG_FUNCTION,
                TokenKind.REGISTER
            };
            top_prod(p, 1, new SpecTerm[] {
                lst(@"$p.part", null, 1, new SpecTerm[] {
                    or_terms(new SpecTerm[] {
                        id("data type"),
                        // these tokens are okay to enter as part of the data type.  the list was created by testing
                        // SQLite; these are not enumerated in the grammar.
                        toks(type_name_token_kinds)
                    })
                }),
                opt_all(new SpecTerm[] {
                    tok(TokenKind.LP),
                    sub_prod("signed-number"),
                    opt_all(new SpecTerm[] {
                        tok(TokenKind.COMMA),
                        sub_prod("signed-number")
                    }),
                    tok(TokenKind.RP)
                })
            });

            // column-constraint ::=
            // [ CONSTRAINT name ]
            // ( PRIMARY KEY [ASC | DESC] <conflict-clause> [AUTOINCREMENT] )
            // |   ( NOT NULL <conflict-clause> )
            // |   ( NULL <conflict-clause> )
            // ^^^ this line isn't in the official grammar, but SQLite seems to accept it.
            // |   ( UNIQUE <conflict-clause> )
            // |   ( CHECK "(" <expr> ")" )
            // |   ( DEFAULT ( <signed-number> | <literal-value> | "(" <expr> ")" ) )
            // |   ( COLLATE collation-name )
            // |   ( <foreign-key-clause> )
            p = "column-constraint";
            top_prod(p, 2, new SpecTerm[] {
                opt(1, new SpecTerm[] {
                    tok(TokenKind.CONSTRAINT),
                    id("constraint name")
                }),
                or_prods(new SpecProd[] {
                    prod(@"$p.primary-key", 1, new SpecTerm[] {
                        tok(TokenKind.PRIMARY),
                        tok(TokenKind.KEY),
                        opt_all(new SpecTerm[] {
                            or_terms(new SpecTerm[] {
                                tok(TokenKind.ASC),
                                tok(TokenKind.DESC)
                            })
                        }),
                        sub_prod("conflict-clause"),
                        opt_one(tok(TokenKind.AUTOINCR))
                    }),
                    prod(@"$p.not-null", 1, new SpecTerm[] {
                        tok(TokenKind.NOT),
                        tok(TokenKind.NULL),
                        sub_prod("conflict-clause")
                    }),
                    prod(@"$p.null", 1, new SpecTerm[] {
                        tok(TokenKind.NULL),
                        sub_prod("conflict-clause")
                    }),
                    prod(@"$p.unique", 1, new SpecTerm[] {
                        tok(TokenKind.UNIQUE),
                        sub_prod("conflict-clause")
                    }),
                    prod(@"$p.check", 1, new SpecTerm[] {
                        tok(TokenKind.CHECK),
                        tok(TokenKind.LP),
                        sub_prod("expr"),
                        tok(TokenKind.RP)
                    }),
                    prod(@"$p.default", 1, new SpecTerm[] {
                        tok(TokenKind.DEFAULT),
                        or_prods(new SpecProd[] {
                            prod(@"$p.number", 1, new SpecTerm[] {
                                sub_prod("signed-number")
                            }),
                            prod(@"$p.literal", 1, new SpecTerm[] {
                                sub_prod("literal-value")
                            }),
                            prod(@"$p.expr", 1, new SpecTerm[] {
                                tok(TokenKind.LP),
                                sub_prod("expr"),
                                tok(TokenKind.RP)
                            })
                        })
                    }),
                    prod(@"$p.collate", 1, new SpecTerm[] {
                        tok(TokenKind.COLLATE),
                        id("collation name")
                    }),
                    prod(@"$p.foreign-key", 1, new SpecTerm[] {
                        sub_prod("foreign-key-clause")
                    })
                })
            });

            // signed-number ::= [ + | - ] numeric-literal
            p = "signed-number";
            top_prod(p, 2, new SpecTerm[] {
                opt_one(or_terms(new SpecTerm[] {
                    tok_str("+"),
                    tok_str("-")
                })),
                or_terms(new SpecTerm[] {
                    tok(TokenKind.INTEGER),
                    tok(TokenKind.FLOAT)
                })
            });

            // table-constraint ::= [ CONSTRAINT name ]
            // ( ( PRIMARY KEY | UNIQUE ) "(" <indexed-column> [ , <indexed-column> ]* ")"
            // <conflict-clause> | CHECK "(" <expr> ")" | FOREIGN KEY "(" column-name [ , column-name ]* ")"
            // <foreign-key-clause> )
            p = "table-constraint";
            top_prod(p, 2, new SpecTerm[] {
                opt(1, new SpecTerm[] {
                    tok(TokenKind.CONSTRAINT),
                    id("constraint name")
                }),
                or_prods(new SpecProd[] {
                    prod(@"$p.key-or-unique", 1, new SpecTerm[] {
                        or_prods(new  SpecProd[] {
                            prod(@"$p.primary-key", 1, new SpecTerm[] {
                                tok(TokenKind.PRIMARY),
                                tok(TokenKind.KEY)
                            }),
                            prod(@"$p.unique", 1, new SpecTerm[] {
                                tok(TokenKind.UNIQUE)
                            })
                        }),
                        tok(TokenKind.LP),
                        lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                            sub_prod("indexed-column")
                        }),
                        tok(TokenKind.RP),
                        sub_prod("conflict-clause")
                    }),
                    prod(@"$p.check", 1, new SpecTerm[] {
                        tok(TokenKind.CHECK),
                        tok(TokenKind.LP),
                        sub_prod("expr"),
                        tok(TokenKind.RP)
                    }),
                    prod(@"$p.foreign-key", 1, new SpecTerm[] {
                        tok(TokenKind.FOREIGN),
                        tok(TokenKind.KEY),
                        tok(TokenKind.LP),
                        lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                            id("column name")
                        }),
                        tok(TokenKind.RP),
                        sub_prod("foreign-key-clause")
                    })
                })
            });

            // foreign-key-clause ::=
            // REFERENCES foreign-table
            // [ "(" column-name [ "," column-name ]* ")" ]
            // [
            // (
            // ON ( DELETE | UPDATE )
            // ( SET NULL | SET DEFAULT | CASCADE | RESTRICT | NO ACTION )
            // ) | (
            // MATCH name
            // )
            // ]*
            // [ [NOT] DEFERRABLE [ INITIALLY DEFERRED | INITIALLY IMMEDIATE ] ]
            p = "foreign-key-clause";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.REFERENCES),
                id("foreign table name"),
                opt_all(new SpecTerm[] {
                    tok(TokenKind.LP),
                    lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                        id("column name")
                    }),
                    tok(TokenKind.RP)
                }),
                lst(@"$p.on-clause", null, 0, new SpecTerm[] {
                    or_prods(new SpecProd[] {
                        prod(@"$p.on", 1, new SpecTerm[] {
                            tok(TokenKind.ON),
                            or_terms(new SpecTerm[] {
                                tok(TokenKind.DELETE),
                                tok(TokenKind.UPDATE)
                            }),
                            or_prods(new SpecProd[] {
                                prod(@"$p.set", 1, new SpecTerm[] {
                                    tok(TokenKind.SET),
                                    or_terms(new SpecTerm[] {
                                        tok(TokenKind.NULL),
                                        tok(TokenKind.DEFAULT)
                                    })
                                }),
                                prod(@"$p.cascade", 1, new SpecTerm[] {
                                    tok(TokenKind.CASCADE)
                                }),
                                prod(@"$p.restrict", 1, new SpecTerm[] {
                                    tok(TokenKind.RESTRICT)
                                }),
                                prod(@"$p.no-action", 1, new SpecTerm[] {
                                    tok(TokenKind.NO), tok(TokenKind.ACTION)
                                })
                            })
                        }),
                        prod(@"$p.match", 1, new SpecTerm[] {
                            tok(TokenKind.MATCH),
                            id("match type")
                        })
                    })
                }),
                opt_all(new SpecTerm[] {
                    opt_one(tok(TokenKind.NOT)),
                    tok(TokenKind.DEFERRABLE),
                    opt(1, new SpecTerm[] {
                        tok(TokenKind.INITIALLY),
                        or_terms(new SpecTerm[] {
                            tok(TokenKind.DEFERRED),
                            tok(TokenKind.IMMEDIATE)
                        })
                    })
                })
            });

            // conflict-clause ::= [ ON CONFLICT ( ROLLBACK | ABORT | FAIL | IGNORE | REPLACE ) ]
            p = "conflict-clause";
            top_prod(p, 1, new SpecTerm[] {
                opt(2, new SpecTerm[] {
                    tok(TokenKind.ON),
                    tok(TokenKind.CONFLICT),
                    or_terms(new SpecTerm[] {
                        tok(TokenKind.ROLLBACK),
                        tok(TokenKind.ABORT),
                        tok(TokenKind.FAIL),
                        tok(TokenKind.IGNORE),
                        tok(TokenKind.REPLACE)
                    })
                })
            });

            // create-trigger-stmt ::= CREATE [ TEMP | TEMPORARY ] TRIGGER [ IF NOT EXISTS ]
            // [database-name "."] trigger-name [BEFORE | AFTER | INSTEAD OF]
            // ( DELETE | INSERT | UPDATE [OF column-name [ "," column-name ]* ] ) ON table-name
            // [ FOR EACH ROW ] [ WHEN <expr> ]
            // BEGIN ( ( <update-stmt> | <insert-stmt> | <delete-stmt> | <select-stmt> ) ";" )+ END
            p = "create-trigger-stmt";
            top_prod(p, 3, new SpecTerm[] {
                tok(TokenKind.CREATE),
                opt_all(new SpecTerm[] {
                    tok(TokenKind.TEMP),
                    tok_str("temporary")
                }),
                tok(TokenKind.TRIGGER),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.NOT),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("trigger name"),
                opt_one(or_prods(new SpecProd[] {
                    prod(@"$p.before", 1, new SpecTerm[] {
                        tok(TokenKind.BEFORE)
                    }),
                    prod(@"$p.after", 1, new SpecTerm[] {
                        tok(TokenKind.AFTER)
                    }),
                    prod(@"$p.instead-of", 1, new SpecTerm[] {
                        tok(TokenKind.INSTEAD),
                        tok(TokenKind.OF)
                    })
                })),
                or_prods(new SpecProd[] {
                    prod(@"$p.delete", 1, new SpecTerm[] {
                        tok(TokenKind.DELETE)
                    }),
                    prod(@"$p.insert", 1, new SpecTerm[] {
                        tok(TokenKind.INSERT)
                    }),
                    prod(@"$p}.update", 1, new SpecTerm[] {
                        tok(TokenKind.UPDATE),
                        opt(1, new SpecTerm[] {
                            tok(TokenKind.OF),
                            lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                                id("column name")
                            })
                        })
                    })
                }),
                tok(TokenKind.ON),
                id("table name"),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.FOR),
                    tok(TokenKind.EACH),
                    tok(TokenKind.ROW)
                }),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.WHEN),
                    sub_prod("expr")
                }),
                tok(TokenKind.BEGIN),
                lst(@"$p.stmt", null, 1, new SpecTerm[] {
                    or_terms(new SpecTerm[] {
                        sub_prod("update-stmt"),
                        sub_prod("insert-stmt"),
                        sub_prod("delete-stmt"),
                        sub_prod("select-stmt")
                    }),
                    tok(TokenKind.SEMI)
                }),
                tok(TokenKind.END)
            });

            // create-view-stmt ::= CREATE [ TEMP | TEMPORARY ] VIEW [ IF NOT EXISTS ]
            // [database-name "."] view-name [ "(" column-name [ "," column-name ]* ")" ] AS <select-stmt>
            p = "create-view-stmt";
            top_prod(p, 3, new SpecTerm[] {
                tok(TokenKind.CREATE),
                opt_all(new SpecTerm[] {
                    tok(TokenKind.TEMP),
                    tok_str("temporary")
                }),
                tok(TokenKind.VIEW),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.NOT),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("view name"),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.LP),
                    lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                        id("column name")
                    }),
                    tok(TokenKind.RP)
                }),
                tok(TokenKind.AS),
                sub_prod("select-stmt")
            });

            // create-virtual-table-stmt ::= CREATE VIRTUAL TABLE [ IF NOT EXISTS ]
            // [ database-name "." ] table-name
            // USING module-name [ "(" module-argument [ "," module-argument ]* ")" ]
            p = "create-virtual-table-stmt";
            top_prod(p, 2, new SpecTerm[] {
                tok(TokenKind.CREATE),
                tok(TokenKind.VIRTUAL),
                tok(TokenKind.TABLE),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.NOT),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("table name"),
                tok(TokenKind.USING),
                id("module name"),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.LP),
                    lst(@"$p.arg", TokenKind.COMMA, 1, new SpecTerm[] {
                        sub_prod("expr")
                    }),
                    tok(TokenKind.RP)
                })
            });

            // with-clause ::= WITH [ RECURSIVE ] <cte-table-name> AS "(" <select-stmt> ")"
            // [ "," <cte-table-name> AS "(" <select-stmt> ")" ]*
            p = "with-clause";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.WITH),
                opt_one(tok(TokenKind.RECURSIVE)),
                lst(@"$p.cte", TokenKind.COMMA, 1, new SpecTerm[] {
                    sub_prod("cte-table-name"),
                    tok(TokenKind.AS),
                    tok(TokenKind.LP),
                    sub_prod("select-stmt"),
                    tok(TokenKind.RP)
                })
            });

            // cte-table-name ::= table-name [ "(" column-name [ "," column-name ]* ")" ]
            p = "cte-table-name";
            top_prod(p, 1, new SpecTerm[] {
                id("table name"),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.LP),
                    lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                        id("column name")
                    }),
                    tok(TokenKind.RP)
                })
            });

            // common-table-expression ::= table-name [ "(" column-name [ "," column-name ]* ")" ]
            // AS "(" <select-stmt> ")"
            p = "common-table-expression";
            top_prod(p, 1, new SpecTerm[] {
                sub_prod("cte-table-name"),
                tok(TokenKind.AS),
                tok(TokenKind.LP),
                sub_prod("select-stmt"),
                tok(TokenKind.RP)
            });

            // delete-stmt ::= [ <with-clause> ] DELETE FROM <qualified-table-name> [ WHERE <expr> ]
            // [
            // [ ORDER BY <ordering-term> [ "," <ordering-term> ]* ]
            // LIMIT <expr> [ ( OFFSET | "," ) <expr> ]
            // ]
            p = "delete-stmt";
            top_prod(p, 2, new SpecTerm[] {
                opt_one(sub_prod("with-clause")),
                tok(TokenKind.DELETE), tok(TokenKind.FROM),
                sub_prod("qualified-table-name"),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.WHERE),
                    sub_prod("expr")
                }),
                opt(2, new SpecTerm[] {
                    opt(1, new SpecTerm[] {
                        tok(TokenKind.ORDER),
                        tok(TokenKind.BY),
                        lst(@"$p.order", TokenKind.COMMA, 1, new SpecTerm[] {
                            sub_prod("ordering-term")
                        })
                    }),
                    tok(TokenKind.LIMIT),
                    sub_prod("expr"),
                    opt(1, new SpecTerm[] {
                        or_terms(new SpecTerm[] {
                            tok(TokenKind.OFFSET),
                            tok(TokenKind.COMMA)
                        }),
                        sub_prod("expr")
                    })
                })
            });

            // detach-stmt ::= DETACH [ DATABASE ] database-name
            p = "detach-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.DETACH),
                opt_one(tok(TokenKind.DATABASE)),
                id("database name")
            });

            // drop-index-stmt ::= DROP INDEX [ IF EXISTS ] [ database-name "." ] index-name
            p = "drop-index-stmt";
            top_prod(p, 2, new SpecTerm[] {
                tok(TokenKind.DROP),
                tok(TokenKind.INDEX),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("index name")
            });

            // drop-table-stmt ::= DROP TABLE [ IF EXISTS ] [ database-name "." ] table-name
            p = "drop-table-stmt";
            top_prod(p, 2, new SpecTerm[] {
                tok(TokenKind.DROP),
                tok(TokenKind.TABLE),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("table name")
            });

            // drop-trigger-stmt ::= DROP TRIGGER [ IF EXISTS ] [ database-name "." ] trigger-name
            p = "drop-trigger-stmt";
            top_prod(p, 2, new SpecTerm[] {
                tok(TokenKind.DROP),
                tok(TokenKind.TRIGGER),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("trigger name")
            });

            // drop-view-stmt ::= DROP VIEW [ IF EXISTS ] [ database-name "." ] view-name
            p = "drop-view-stmt";
            top_prod(p, 2, new SpecTerm[] {
                tok(TokenKind.DROP),
                tok(TokenKind.VIEW),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.IF),
                    tok(TokenKind.EXISTS)
                }),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("view name")
            });

            // The SQLite grammar for expressions does not express operator precedence.  Our expression grammar is
            // modified from the official SQLite grammar to take operator precedence into account.
            //
            // From https://www.sqlite.org/lang_expr.html:
            // SQLite understands the following binary operators, in order from highest to lowest precedence:
            // ||
            // *    /    %
            // +    -
            // <<   >>  &    |
            // <    <=   >    >=
            // =    ==   !=   <>    IS   IS NOT   IN   LIKE   GLOB  MATCH   REGEXP
            // AND
            // OR
            // ...
            // The COLLATE operator is a unary postfix operator that assigns a collating sequence to an
            // expression. The COLLATE operator has a higher precedence (binds more tightly) than any binary
            // operator and any unary prefix operator except "~". (COLLATE and "~" are associative so their
            // binding order does not matter.) ...

            // expr ::= or-expr
            p = "expr";
            top_prod(p, 1, new SpecTerm[] {
                sub_prod("or-expr")
            });

            // or-expr ::= and-expr [ OR and-expr ]*
            p = "or-expr";
            top_prod(p, 1, new SpecTerm[] {
                lst(@"$p.term", TokenKind.OR, 1, new SpecTerm[] {
                    sub_prod("and-expr")
                })
            });

            // and-expr ::= eq-expr [ AND eq-expr ]*
            p = "and-expr";
            top_prod(p, 1, new SpecTerm[] {
                lst(@"$p.term", TokenKind.AND, 1, new SpecTerm[] {
                    sub_prod("eq-expr")
                })
            });

            // eq-expr ::= ineq-expr [ eq-expr-op | eq-expr-is | eq-expr-in | eq-expr-like | eq-expr-between ]*
            p = "eq-expr";
            top_prod(p, 1, new SpecTerm[] {
                sub_prod("ineq-expr"),
                lst(@"$p.term", null, 0, new SpecTerm[] {
                    or_terms(new SpecTerm[] {
                        sub_prod("eq-expr-op"),
                        sub_prod("eq-expr-is"),
                        sub_prod("eq-expr-in"),
                        sub_prod("eq-expr-like"),
                        sub_prod("eq-expr-between")
                    })
                })
            });

            // eq-expr-op ::= ( "=" | "==" | "!=" | "<>" ) ineq-expr
            p = "eq-expr-op";
            top_prod(p, 1, new SpecTerm[] {
                or_terms(new SpecTerm[] {
                    tok_str("="),
                    tok_str("=="),
                    tok_str("!="),
                    tok_str("<>")
                }),
                sub_prod("ineq-expr")
            });

            // eq-expr-is ::= (IS [NOT] ineq-expr) | ISNULL | NOTNULL | (NOT NULL)
            p = "eq-expr-is";
            top_prod(p, 1, new SpecTerm[] {
                or_prods(new SpecProd[] {
                    prod(@"$p.is-not", 1, new SpecTerm[] {
                        tok(TokenKind.IS),
                        opt_one(tok(TokenKind.NOT)),
                        sub_prod("ineq-expr")
                    }),
                    prod(@"$p.is-null", 1, new SpecTerm[] {
                        tok(TokenKind.ISNULL)
                    }),
                    prod(@"$p.notnull", 1, new SpecTerm[] {
                        tok(TokenKind.NOTNULL)
                    }),
                    prod(@"$p.not-null", 1, new SpecTerm[] {
                        tok(TokenKind.NOT),
                        tok(TokenKind.NULL)
                    })
                })
            });

            // eq-expr-in ::= [NOT] IN
            // (
            // "(" [ <select-stmt> | <expr> [ "," <expr> ]* ] ")" |
            // [database-name "."] table-name
            // )
            p = "eq-expr-in";
            top_prod(p, 2, new SpecTerm[] {
                opt_one(tok(TokenKind.NOT)),
                tok(TokenKind.IN),
                or_prods(new SpecProd[] {
                    prod(@"$p.select", 1, new SpecTerm[] {
                        tok(TokenKind.LP),
                        opt_one(or_terms(new SpecTerm[] {
                            sub_prod("select-stmt"),
                            lst(@"$p.value", TokenKind.COMMA, 1, new SpecTerm[] {
                                sub_prod("expr")
                            })
                        })),
                        tok(TokenKind.RP)
                    }),
                    prod(@"$p.table", 2, new SpecTerm[] {
                        opt_all(new SpecTerm[] {
                            id("database name"),
                            tok(TokenKind.DOT)
                        }),
                        id("table name")
                    })
                })
            });

            // eq-expr-like ::= [NOT] (LIKE | GLOB | REGEXP | MATCH) <ineq-expr> [ESCAPE <ineq-expr>]
            p = "eq-expr-like";
            top_prod(p, 2, new SpecTerm[] {
                opt_one(tok(TokenKind.NOT)),
                or_terms(new SpecTerm[] {
                    tok_str("like"),
                    tok_str("glob"),
                    tok_str("regexp"),
                    tok_str("match")
                }),
                sub_prod("ineq-expr"),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.ESCAPE),
                    sub_prod("ineq-expr")
                })
            });

            // eq-expr-between ::= [NOT] BETWEEN <ineq-expr> AND <ineq-expr>
            p = "eq-expr-between";
            top_prod(p, 2, new SpecTerm[] {
                opt_one(tok(TokenKind.NOT)),
                tok(TokenKind.BETWEEN),
                sub_prod("ineq-expr"),
                tok(TokenKind.AND),
                sub_prod("ineq-expr")
            });

            // ineq-expr ::= <bitwise-expr> [ ( "<" | "<=" | ">" | ">=" ) <bitwise-expr> ]*
            p = "ineq-expr";
            top_prod(p, 1, new SpecTerm[] {
                lst_t(".term", or_terms(new SpecTerm[] {
                    tok_str("<"),
                    tok_str("<="),
                    tok_str(">"),
                    tok_str(">=")
                }), 1, new SpecTerm[] {
                    sub_prod("bitwise-expr")
                })
            });

            // bitwise-expr ::= <add-expr> [ ( "<<" | ">>" | "&" | "|" ) <add-expr> ]*
            p = "bitwise-expr";
            top_prod(p, 1, new SpecTerm[] {
                lst_t(".term", or_terms(new SpecTerm[] {
                    tok_str("<<"),
                    tok_str(">>"),
                    tok_str("&"),
                    tok_str("|")
                }), 1, new SpecTerm[] {
                    sub_prod("add-expr")
                })
            });

            // add-expr ::= <mult-expr> [ ( "+" | "-" ) <mult-expr> ]*
            p = "add-expr";
            top_prod(p, 1, new SpecTerm[] {
                lst_t(".term", or_terms(new SpecTerm[] {
                    tok_str("+"),
                    tok_str("-")
                }), 1, new SpecTerm[] {
                    sub_prod("mult-expr")
                })
            });

            // mult-expr ::= <concat-expr> [ ( "*" | "/" | "%" ) <concat-expr> ]*
            p = "mult-expr";
            top_prod(p, 1, new SpecTerm[] {
                lst_t(".term", or_terms(new SpecTerm[] {
                    tok_str("*"),
                    tok_str("/"),
                    tok_str("%")
                }), 1, new SpecTerm[] {
                    sub_prod("concat-expr")
                })
            });

            // concat-expr ::= <unary-expr> [ "||" <unary-expr> ]*
            p = "concat-expr";
            top_prod(p, 1, new SpecTerm[] {
                lst_t(".term", tok_str("||"), 1, new SpecTerm[] {
                    sub_prod("unary-expr")
                })
            });

            // unary-expr ::= [ "-" | "+" | "NOT" | "~" ]* <collate-expr>
            p = "unary-operator";
            top_prod(p, 1, new SpecTerm[] {
                or_terms(new SpecTerm[] {
                    tok_str("-"),
                    tok_str("+"),
                    tok(TokenKind.NOT),
                    tok_str("~")
                })
            });

            p = "unary-expr";
            top_prod(p, 2, new SpecTerm[] {
                lst(".operator", null, 0, new SpecTerm[] {
                    sub_prod("unary-operator")
                }),
                sub_prod("collate-expr")
            });

            // collate-expr ::= <expr-term> [COLLATE collation-name]
            p = "collate-expr";
            top_prod(p, 2, new SpecTerm[] {
                sub_prod("expr-term"),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.COLLATE),
                    id("collation name")
                })
            });

            // expr-term ::=
            // <literal-value> |
            // <bind-parameter> |
            // [ [ database-name "." ] table-name "." ] column-name |
            // function-name "(" [ [DISTINCT] <expr> [ "," <expr> ]* | "*" ] ")" |
            // "(" <expr> ")" |
            // CAST "(" <expr> AS <type-name> ")" |
            // [ [NOT] EXISTS ] ( <select-stmt> ) |
            // CASE [ <expr> ] ( WHEN <expr> THEN <expr> )+ [ ELSE <expr> ] END |
            // <raise-function>
            p = "expr-term";
            top_prod(p, 1, new SpecTerm[] {
                or_prods(new SpecProd[] {
                    // expr ::= function-name "(" [ [DISTINCT] <expr> [ "," <expr> ]* | "*" ] ")"
                    prod(@"$p.function-call", 2, new SpecTerm[] {
                        id("function name"),
                        tok(TokenKind.LP),
                        opt_one(or_prods(new SpecProd[] {
                            prod(@"$p.star", 1, new SpecTerm[] {
                                tok(TokenKind.STAR)
                            }),
                            prod(@"$p.args", 2, new SpecTerm[] {
                                opt_one(tok(TokenKind.DISTINCT)),
                                lst(@"$p.arg", TokenKind.COMMA, 1, new SpecTerm[] {
                                    sub_prod("expr")
                                })
                            })
                        })),
                        tok(TokenKind.RP)
                    }),
                    // [ [ database-name "." ] table-name "." ] column-name
                    prod(@"$p.column-name", 1, new SpecTerm[] {
                        or_prods(new SpecProd[] {
                            prod(".dotted-identifier", 2, new SpecTerm[] {
                                or_terms(new SpecTerm[] {
                                    id("database, table, or column name"),
                                    lit_str("database, table, or column name")
                                }),
                                tok(TokenKind.DOT),
                                or_terms(new SpecTerm[] {
                                    id("table or column name"),
                                    lit_str("table or column name")
                                }),
                                opt_all(new SpecTerm[] {
                                    tok(TokenKind.DOT),
                                    or_terms(new SpecTerm[] {
                                        id("column name"),
                                        lit_str("column name")
                                    })
                                })
                            }),
                            prod(".bare-col-identifier", 1, new SpecTerm[] {
                                id("column name")
                            })
                        })
                    }),
                    // <bind-parameter>
                    prod(@"$p.variable-name", 1, new SpecTerm[] {
                        id("variable name", true)
                    }),
                    // <literal-value>
                    prod(@"$p.literal-value", 1, new SpecTerm[] {
                        sub_prod("literal-value")
                    }),
                    // expr ::= "(" <expr> ")"
                    prod(@"$p.parentheses", 1, new SpecTerm[] {
                        tok(TokenKind.LP),
                        sub_prod("expr"),
                        tok(TokenKind.RP)
                    }),
                    // expr ::= CAST "(" <expr> AS <type-name> ")"
                    prod(@"$p.cast", 1, new SpecTerm[] {
                        tok(TokenKind.CAST),
                        tok(TokenKind.LP),
                        sub_prod("expr"),
                        tok(TokenKind.AS),
                        sub_prod("type-name"),
                        tok(TokenKind.RP)
                    }),
                    // expr ::= [ [NOT] EXISTS ] ( <select-stmt> )
                    prod(@"$p.exists", 2, new SpecTerm[] {
                        opt_all(new SpecTerm[] {
                            opt_one(tok(TokenKind.NOT)),
                            tok(TokenKind.EXISTS)
                        }),
                        tok(TokenKind.LP),
                        sub_prod("select-stmt"),
                        tok(TokenKind.RP)
                    }),
                    // expr ::= CASE [ <expr> ] (WHEN <expr> THEN <expr>)+ [ ELSE <expr> ] END
                    prod(@"$p.case", 1, new SpecTerm[] {
                        tok(TokenKind.CASE),
                        opt_one(sub_prod("expr")),
                        lst(".when", null, 1, new SpecTerm[] {
                            tok(TokenKind.WHEN),
                            sub_prod("expr"),
                            tok(TokenKind.THEN),
                            sub_prod("expr")
                        }),
                        opt(1, new SpecTerm[] {
                            tok(TokenKind.ELSE),
                            sub_prod("expr")
                        }),
                        tok(TokenKind.END)
                    }),
                    // expr ::= <raise-function>
                    prod(@"$p.raise", 1, new SpecTerm[] {
                        sub_prod("raise-function")
                    })
                })
            });

            // raise-function ::= RAISE ( IGNORE | (( ROLLBACK | ABORT | FAIL ) "," error-message) )
            p = "raise-function";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.RAISE),
                tok(TokenKind.LP),
                or_prods(new SpecProd[] {
                    prod(@"$p.ignore", 1, new SpecTerm[] {
                        tok(TokenKind.IGNORE)
                    }),
                    prod(@"$p.rollback-abort-fail", 1, new SpecTerm[] {
                        or_terms(new SpecTerm[] {
                            tok(TokenKind.ROLLBACK),
                            tok(TokenKind.ABORT),
                            tok(TokenKind.FAIL)
                        }),
                        tok(TokenKind.COMMA),
                        lit_str("error message")
                    })
                }),
                tok(TokenKind.RP)
            });

            // literal-value ::= numeric-literal
            // literal-value ::= string-literal
            // literal-value ::= blob-literal
            // literal-value ::= NULL
            // literal-value ::= CURRENT_TIME
            // literal-value ::= CURRENT_DATE
            // literal-value ::= CURRENT_TIMESTAMP
            p = "literal-value";
            top_prod(p, 1, new SpecTerm[] {
                or_terms(new SpecTerm[] {
                    tok(TokenKind.INTEGER),
                    tok(TokenKind.FLOAT),
                    tok(TokenKind.STRING),
                    tok(TokenKind.BLOB),
                    tok(TokenKind.NULL),
                    tok_str("current_time"),
                    tok_str("current_date"),
                    tok_str("current_timestamp")
                })
            });

            // insert-stmt ::= [ <with-clause> ]
            // ( INSERT | REPLACE | INSERT OR REPLACE | INSERT OR ROLLBACK |
            // INSERT OR ABORT | INSERT OR FAIL | INSERT OR IGNORE ) INTO
            // [ database-name "." ] table-name [ "(" column-name [ "," column-name ]* ")" ]
            // (
            // VALUES "(" <expr> [ "," <expr> ]* ")" [ "," "(" <expr> [ "," <expr> ]* ")" ]* |
            // <select-stmt> |
            // DEFAULT VALUES
            // )
            p = "insert-stmt";
            top_prod(p, 1, new SpecTerm[] {
                opt_one(sub_prod("with-clause")),
                or_prods(new SpecProd[] {
                    prod(@"$p.insert", 1, new SpecTerm[] {
                        tok(TokenKind.INSERT),
                        opt(1, new SpecTerm[] {
                            tok(TokenKind.OR),
                            or_terms(new SpecTerm[] {
                                tok(TokenKind.REPLACE),
                                tok(TokenKind.ROLLBACK),
                                tok(TokenKind.ABORT),
                                tok(TokenKind.FAIL),
                                tok(TokenKind.IGNORE)
                            })
                        })
                    }),
                    prod(@"$p.replace", 1, new SpecTerm[] {
                        tok(TokenKind.REPLACE)
                    })
                }),
                tok(TokenKind.INTO),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("table name"),
                opt_all(new SpecTerm[] {
                    tok(TokenKind.LP),
                    lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                        id("column name")
                    }),
                    tok(TokenKind.RP)
                }),
                or_prods(new SpecProd[] {
                    prod(@"$p.values", 1, new SpecTerm[] {
                        tok(TokenKind.VALUES),
                        lst(@"$p.row", TokenKind.COMMA, 1, new SpecTerm[] {
                            tok(TokenKind.LP),
                            lst(@"$p.value", TokenKind.COMMA, 1, new SpecTerm[] {
                                sub_prod("expr")
                            }),
                            tok(TokenKind.RP)
                        })
                    }),
                    prod(@"$p.select", 1, new SpecTerm[] {
                        sub_prod("select-stmt")
                    }),
                    prod(@"$p.default-values", 1, new SpecTerm[] {
                        tok(TokenKind.DEFAULT),
                        tok(TokenKind.VALUES)
                    })
                })
            });

            // pragma-stmt ::= PRAGMA [ database-name "." ] pragma-name
            // [ "=" <pragma-value> | "(" <pragma-value> ")" ]
            p = "pragma-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.PRAGMA),
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("pragma name"),
                opt_one(or_prods(new SpecProd[] {
                    prod(@"$p.equals", 1, new SpecTerm[] {
                        tok(TokenKind.EQ),
                        sub_prod("pragma-value")
                    }),
                    prod(@"$p.paren", 1, new SpecTerm[] {
                        tok(TokenKind.LP),
                        sub_prod("pragma-value"),
                        tok(TokenKind.RP)
                    })
                }))
            });

            // pragma-value ::= <signed-number>
            // pragma-value ::= name
            // pragma-value ::= string-literal
            p = "pragma-value";
            top_prod(p, 1, new SpecTerm[] {
                or_terms(new SpecTerm[] {
                    sub_prod("signed-number"),
                    id("name"),
                    lit_str("string")
                })
            });

            // reindex-stmt ::= REINDEX [ [ database-name "." ] table-or-index-or-collation-name ]
            p = "reindex-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.REINDEX),
                opt_all(new SpecTerm[] {
                    opt_all(new SpecTerm[] {
                        id("database name"),
                        tok(TokenKind.DOT)
                    }),
                    id("table, index, or collation name")
                })
            });

            // select-stmt ::= [ WITH [ RECURSIVE ] <common-table-expression> [ , <common-table-expression> ]* ]
            // [ SELECT [ DISTINCT | ALL ] <result-column> [ , <result-column> ]*
            // [ FROM [ <table-or-subquery> [ , <table-or-subquery> ]* | <join-clause> ]1 ]
            // [ WHERE <expr> ]
            // [ GROUP BY <expr> [ , <expr> ]* [ HAVING <expr> ] ] | VALUES ( <expr> [ , <expr> ]* ) [ , ( <expr> [ ,
            // <expr> ]* ) ]* ]1 [ <compound-operator> [ SELECT [ DISTINCT | ALL ] <result-column> [ , <result-column>
            // ]*
            // [ FROM [ <table-or-subquery> [ , <table-or-subquery> ]* | <join-clause> ]1 ]
            // [ WHERE <expr> ]
            // [ GROUP BY <expr> [ , <expr> ]* [ HAVING <expr> ] ] | VALUES ( <expr> [ , <expr> ]* ) [ , ( <expr> [ ,
            // <expr> ]* ) ]* ]1 ]*
            // [ ORDER BY <ordering-term> [ , <ordering-term> ]* ]
            // [ LIMIT <expr> [ [ OFFSET | , ]1 <expr> ] ]
            top_prod(p = "select-stmt", 1, new SpecTerm[] {
                opt(1, new SpecTerm[] {
                    tok(TokenKind.WITH),
                    opt_one(tok(TokenKind.RECURSIVE)),
                    lst(@"$p.cte", TokenKind.COMMA, 1, new SpecTerm[] {
                        sub_prod("common-table-expression")
                    })
                }),
                lst_t(".compound-operand", sub_prod("compound-operator"), 1, new SpecTerm[] {
                    or_prods(new SpecProd[] {
                        prod(@"$p.select", 1, new SpecTerm[] {
                            tok(TokenKind.SELECT),
                            opt_one(or_terms(new SpecTerm[] {
                                tok(TokenKind.DISTINCT),
                                tok(TokenKind.ALL)
                            })),
                            lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                                sub_prod("result-column")
                            }),
                            opt(1, new SpecTerm[] {
                                tok(TokenKind.FROM),
                                or_terms(new SpecTerm[] {
                                    sub_prod("join-clause"),
                                    lst(@"$p.table", TokenKind.COMMA, 1, new SpecTerm[] {
                                        sub_prod("table-or-subquery")
                                    })
                                })
                            }),
                            opt(1, new SpecTerm[] {
                                tok(TokenKind.WHERE),
                                sub_prod("expr")
                            }),
                            opt(1, new SpecTerm[] {
                                tok(TokenKind.GROUP),
                                tok(TokenKind.BY),
                                lst(@"$p.group-expr", TokenKind.COMMA, 1, new SpecTerm[] {
                                    sub_prod("expr")
                                }),
                                opt(1, new SpecTerm[] {
                                    tok(TokenKind.HAVING),
                                    sub_prod("expr")
                                })
                            })
                        }),
                        prod(@"$p.values", 1, new SpecTerm[] {
                            tok(TokenKind.VALUES),
                            lst(@"$p.row", TokenKind.COMMA, 1, new SpecTerm[] {
                                tok(TokenKind.LP),
                                lst(@"$p.value", TokenKind.COMMA, 1, new SpecTerm[] {
                                    sub_prod("expr")
                                }),
                                tok(TokenKind.RP)
                            })
                        })
                    })
                }),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.ORDER),
                    tok(TokenKind.BY),
                    lst(@"$p.term", TokenKind.COMMA, 1, new SpecTerm[] {
                        sub_prod("ordering-term")
                    })
                }),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.LIMIT),
                    sub_prod("expr"),
                    opt(1, new SpecTerm[] {
                        or_terms(new SpecTerm[] {
                            tok(TokenKind.OFFSET),
                            tok(TokenKind.COMMA)
                        }),
                        sub_prod("expr")
                    })
                })
            });

            // join-clause ::= <table-or-subquery> ( <join-operator> <table-or-subquery> <join-constraint> )+
            // note: the official grammar allows only a single join-operator. that seems like a mistake.
            // we've also changed the optional join-operator into an at-least-one, because the select-stmt production
            // already contains a case for a single table-or-subquery, so join-clause is only needed if a join-operator
            // is present.
            p = "join-clause";
            top_prod(p, 1, new SpecTerm[] {
                sub_prod("table-or-subquery"),
                lst(@"$p.term", null, 1, new SpecTerm[] {
                    sub_prod("join-operator"),
                    sub_prod("table-or-subquery"),
                    sub_prod("join-constraint")
                })
            });

            // table-or-subquery ::= [ database-name "." ] table-function-name "(" [ <expr> ["," <expr>]* ")"
            // [ [AS] table-alias ]
            // table-or-subquery ::= [ database-name "." ] table-name [ [ AS ] table-alias ]
            // [ INDEXED BY index-name | NOT INDEXED ]
            // table-or-subquery ::= "(" ( <table-or-subquery> [ "," <table-or-subquery> ]* | <join-clause> ) ")"
            // table-or-subquery ::= "(" <select-stmt> ")" [ [ AS ] table-alias ]
            // note: the table-function-name production is described in the syntax diagram but not the text BNF.
            p = "table-or-subquery";
            top_prod(p, 1, new SpecTerm[] {
                or_prods(new SpecProd[] {
                    prod(@"$p.table-function-call", 3, new SpecTerm[] {
                        // TableFunctionsMacro requires that table-function-name be the first child of table-function-call
                        sub_prod_premade(prod(@"$p.table-function-name", 2, new SpecTerm[] {
                            opt_all(new SpecTerm[] {
                                id("database name"),
                                tok(TokenKind.DOT)
                            }),
                            id("table function name")
                        })),
                        tok(TokenKind.LP),
                        // TableFunctionsMacro requires that the arguments list be the third child of table-function-call
                        lst(@"$p.arg", TokenKind.COMMA, 0, new SpecTerm[] {
                            sub_prod("expr")
                        }),
                        tok(TokenKind.RP),
                        opt_all(new SpecTerm[] {
                            opt_one(tok(TokenKind.AS)),
                            or_terms(new SpecTerm[] {
                                id("table alias"),
                                lit_str("table alias")
                            })
                        })
                    }),
                    prod(@"$p.table", 2, new SpecTerm[] {
                        or_terms(new SpecTerm[] {
                            id("database or table name"),
                            lit_str("database or table name")
                        }),
                        opt_all(new SpecTerm[] {
                            tok(TokenKind.DOT),
                            or_terms(new SpecTerm[] {
                                id("table name"),
                                lit_str("table name")
                            })
                        }),
                        opt_all(new SpecTerm[] {
                            opt_one(tok(TokenKind.AS)),
                            or_terms(new SpecTerm[] {
                                id("table alias"),
                                lit_str("table alias")
                            })
                        }),
                        opt_one(or_prods(new SpecProd[] {
                            prod(@"$p.indexed-by", 1, new SpecTerm[] {
                                tok(TokenKind.INDEXED),
                                tok(TokenKind.BY),
                                id("index name")
                            }),
                            prod(@"$p.not-indexed", 1, new SpecTerm[] {
                                tok(TokenKind.NOT),
                                tok(TokenKind.INDEXED)
                            })
                        }))
                    }),
                    prod(@"$p.select", 2, new SpecTerm[] {
                        tok(TokenKind.LP),
                        sub_prod("select-stmt"),
                        tok(TokenKind.RP),
                        opt_all(new SpecTerm[] {
                            opt_one(tok(TokenKind.AS)),
                            or_terms(new SpecTerm[] {
                                id("table alias"),
                                lit_str("table alias")
                            })
                        })
                    }),
                    prod(@"$p.joins", 1, new SpecTerm[] {
                        tok(TokenKind.LP),
                        or_terms(new SpecTerm[] {
                            lst(@"$p.term", TokenKind.COMMA, 1, new SpecTerm[] {
                                sub_prod("table-or-subquery")
                            }),
                            sub_prod("join-clause")
                        }),
                        tok(TokenKind.RP)
                    })
                })
            });

            // result-column ::= *
            // result-column ::= table-name . *
            // result-column ::= <expr> [ [ AS ] column-alias ]
            p = "result-column";
            top_prod(p, 1, new SpecTerm[] {
                or_prods(new SpecProd[] {
                    prod(@"$p.star", 1, new SpecTerm[] {
                        tok(TokenKind.STAR)
                    }),
                    prod(@"$p.table-star", 3, new SpecTerm[] {
                        or_terms(new SpecTerm[] {
                            id("table name"),
                            lit_str("table name")
                        }),
                        tok(TokenKind.DOT),
                        tok(TokenKind.STAR)
                    }),
                    prod(@"$p.expr", 1, new SpecTerm[] {
                        sub_prod("expr"),
                        opt_all(new SpecTerm[] {
                            opt_one(tok(TokenKind.AS)),
                            or_terms(new SpecTerm[] {
                                id("column alias"),
                                lit_str("column alias")
                            })
                        })
                    })
                })
            });

            // join-operator ::= ,
            // join-operator ::= [ NATURAL ] [ LEFT [ OUTER ] | INNER | CROSS ] JOIN
            top_prod(p = "join-operator", 1, new SpecTerm[] {
                or_prods(new SpecProd[] {
                    prod(@"$p.comma", 1, new SpecTerm[] {
                        tok(TokenKind.COMMA)
                    }),
                    prod(@"$p.join", 3, new SpecTerm[] {
                        opt_one(tok_str("natural")),
                        opt_one(or_prods(new SpecProd[] {
                            prod(@"$p.left", 1, new SpecTerm[] {
                                tok_str("left"),
                                opt_one(tok_str("outer"))
                            }),
                            prod(@"$p.inner", 1, new SpecTerm[] {
                                tok_str("inner")
                            }),
                            prod(@"$p.cross", 1, new SpecTerm[] {
                                tok_str("cross")
                            })
                        })),
                        tok_str("join")
                    })
                })
            });

            // join-constraint ::= [ ON <expr> | USING ( column-name [ , column-name ]* ) ]
            p = "join-constraint";
            top_prod(p, 1, new SpecTerm[] {
                opt_one(or_prods(new SpecProd[] {
                    prod(@"$p.on", 1, new SpecTerm[] {
                        tok(TokenKind.ON),
                        sub_prod("expr")
                    }),
                    prod(@"$p.using", 1, new SpecTerm[] {
                        tok(TokenKind.USING),
                        tok(TokenKind.LP),
                        lst(@"$p.column", TokenKind.COMMA, 1, new SpecTerm[] {
                            id("column name")
                        }),
                        tok(TokenKind.RP)
                    })
                }))
            });

            // ordering-term ::= <expr> [ COLLATE collation-name ] [ ASC | DESC ]
            p = "ordering-term";
            top_prod(p, 1, new SpecTerm[] {
                sub_prod("expr"),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.COLLATE),
                    id("collation name")
                }),
                opt_one(or_terms(new SpecTerm[] {
                    tok(TokenKind.ASC),
                    tok(TokenKind.DESC)
                }))
            });

            // compound-operator ::= UNION
            // compound-operator ::= UNION ALL
            // compound-operator ::= INTERSECT
            // compound-operator ::= EXCEPT
            p = "compound-operator";
            top_prod(p, 1, new SpecTerm[] {
                or_prods(new SpecProd[] {
                    prod(@"$p.union", 1, new SpecTerm[] {
                        tok(TokenKind.UNION),
                        opt_one(tok(TokenKind.ALL))
                    }),
                    prod(@"$p.intersect", 1, new SpecTerm[] {
                        tok(TokenKind.INTERSECT)
                    }),
                    prod(@"$p.except", 1, new SpecTerm[] {
                        tok(TokenKind.EXCEPT)
                    })
                })
            });

            // update-stmt ::= [ <with-clause> ] UPDATE
            // [ OR ROLLBACK | OR ABORT | OR REPLACE | OR FAIL | OR IGNORE ] <qualified-table-name>
            // SET column-name = <expr> [ , column-name = <expr> ]* [ WHERE <expr> ]
            // [
            // [ ORDER BY <ordering-term> [ , <ordering-term> ]* ]
            // LIMIT <expr> [ ( OFFSET | , ) <expr> ]
            // ]
            p = "update-stmt";
            top_prod(p, 2, new SpecTerm[] {
                opt_one(sub_prod("with-clause")),
                tok(TokenKind.UPDATE),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.OR),
                    or_terms(new SpecTerm[] {
                        tok(TokenKind.ROLLBACK),
                        tok(TokenKind.ABORT),
                        tok(TokenKind.REPLACE),
                        tok(TokenKind.FAIL),
                        tok(TokenKind.IGNORE)
                    })
                }),
                sub_prod("qualified-table-name"),
                tok(TokenKind.SET),
                lst(@"$p.assignment", TokenKind.COMMA, 1, new SpecTerm[] {
                    id("column name"),
                    tok(TokenKind.EQ),
                    sub_prod("expr")
                }),
                opt(1, new SpecTerm[] {
                    tok(TokenKind.WHERE),
                    sub_prod("expr")
                }),
                opt(2, new SpecTerm[] {
                    opt_all(new SpecTerm[] {
                        tok(TokenKind.ORDER),
                        tok(TokenKind.BY),
                        lst(@"$p.order-term", TokenKind.COMMA, 1, new SpecTerm[] {
                            sub_prod("ordering-term")
                        })
                    }),
                    tok(TokenKind.LIMIT),
                    sub_prod("expr"),
                    opt(1, new SpecTerm[] {
                        or_terms(new SpecTerm[] {
                            tok(TokenKind.OFFSET),
                            tok(TokenKind.COMMA)
                        }),
                        sub_prod("expr")
                    })
                })
            });

            // qualified-table-name ::= [ database-name . ] table-name [ INDEXED BY index-name | NOT INDEXED ]
            p = "qualified-table-name";
            top_prod(p, 2, new SpecTerm[] {
                opt_all(new SpecTerm[] {
                    id("database name"),
                    tok(TokenKind.DOT)
                }),
                id("table name"),
                opt_one(or_prods(new SpecProd[] {
                    prod(@"$p.indexed-by", 1, new SpecTerm[] {
                        tok(TokenKind.INDEXED),
                        tok(TokenKind.BY),
                        id("index name")
                    }),
                    prod(@"$p.not-indexed", 1, new SpecTerm[] {
                        tok(TokenKind.NOT),
                        tok(TokenKind.INDEXED)
                    })
                }))
            });

            // vacuum-stmt ::= VACUUM
            p = "vacuum-stmt";
            top_prod(p, 1, new SpecTerm[] {
                tok(TokenKind.VACUUM)
            });
        }

        private void top_prod(string name, int num_required_terms, SpecTerm[] terms) {
            var terms_list = ArrayUtil.to_list(terms);
            prods.@set(name, new SpecProd(name, num_required_terms, terms_list));
        }

        private static SpecProd prod(string name, int num_required_terms, SpecTerm[] terms) {
            var terms_list = ArrayUtil.to_list(terms);
            return new SpecProd(name, num_required_terms, terms_list);
        }

        private static IdentifierTerm id(string desc, bool allow_variable = false) {
            var x = new IdentifierTerm() {
                desc = desc,
                allow_variable = allow_variable
            };
            return x;
        }

        private static KeyTokenTerm tok(TokenKind kind) {
            var x = new KeyTokenTerm() {
                token_kind = kind
            };
            return x;
        }

        private static StringTokenTerm tok_str(string text) {
            var x = new StringTokenTerm() {
                text = text
            };
            return x;
        }

        private static TokenSetTerm toks(TokenKind[] kinds) {
            return new TokenSetTerm(kinds);
        }

        private static OptionalTerm opt(int num_required_terms, SpecTerm[] terms) {
            var x = new OptionalTerm() {
                prod = new SpecProd(null, num_required_terms, ArrayUtil.to_list(terms))
            };
            return x;
        }

        private static OptionalTerm opt_all(SpecTerm[] terms) {
            var x = new OptionalTerm() {
                prod = new SpecProd(null, terms.length, ArrayUtil.to_list(terms))
            };
            return x;
        }

        private static OptionalTerm opt_one(SpecTerm term) {
            var terms = new SpecTerm[] { term };
            return opt_all(terms);
        }

        private static OrTerm or_prods(SpecProd[] prods) {
            var x = new OrTerm() {
                prods = ArrayUtil.to_list(prods)
            };
            return x;
        }

        private static OrTerm or_terms(SpecTerm[] terms) {
            var terms_list = ArrayUtil.to_list(terms);
            var prods = terms_list.map<SpecProd>(x => new SpecProd(null, 1, ArrayUtil.to_list(new SpecTerm[] { x })));
            var x = new OrTerm() {
                prods = TraversableUtil.to_list(prods)
            };
            return x;
        }

        private static ProdTerm sub_prod(string name) {
            var x = new ProdTerm() {
                prod_name = name
            };
            return x;
        }

        private static OrTerm sub_prod_premade(SpecProd prod) {
            var x = new OrTerm() {
                prods = ArrayUtil.to_list(new SpecProd[] { prod })
            };
            return x;
        }

        private static ListTerm lst(string sub_prod_name, TokenKind? separator_kind, int min, SpecTerm[] terms) {
            SpecProd separator_prod = null;
            if (separator_kind != null) {
                separator_prod = prod(".list-separator", 1, new SpecTerm[] { tok(separator_kind) });
            }

            var x = new ListTerm() {
                separator_prod = separator_prod,
                min = min,
                item_prod = prod(sub_prod_name, terms.length, terms)
            };
            return x;
        }

        private static ListTerm lst_t(string sub_prod_name, SpecTerm separator_term, int min, SpecTerm[] terms) {
            var x = new ListTerm() {
                separator_prod = prod(".list_separator", 1, new SpecTerm[] { separator_term }),
                min = min,
                item_prod = prod(sub_prod_name, terms.length, terms)
            };
            return x;
        }

        private static LiteralStringTerm lit_str(string desc) {
            var x = new LiteralStringTerm() {
                desc = desc
            };
            return x;
        }
    }
}
