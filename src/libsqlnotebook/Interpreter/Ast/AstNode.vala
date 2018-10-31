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
using SqlNotebook.Interpreter.Tokens;

namespace SqlNotebook.Interpreter.Ast {
    public abstract class AstNode : Object {
        private static Gee.LinkedList<AstNode> _empty_node_linked_list = new Gee.LinkedList<AstNode>();

        public Token source_token { get; set; }
        
        public int child_count {
            get {
                if (is_leaf) {
                    return 0;
                } else if (get_child() != null) {
                    return 1;
                } else {
                    return get_children().length;
                }
            }
        }
        
        public AstNode? get_child_at(int index) {
            if (index == 0) {
                var child = get_child();
                if (child != null) {
                    return child;
                }
            }
            
            var children = get_children();
            if (index < children.length) {
                return children[index];
            } else {
                return null;
            }
        }

        // each node will implement only one of the following three:

        // implemented if the node has no children
        protected virtual bool is_leaf {
            get {
                return false;
            }
        }

        // implemented if the node has exactly one child
        protected virtual AstNode? get_child() {
            return null;
        }

        // implemented if the node has multiple children, or if the number of children is not known statically
        protected virtual AstNode?[] get_children() {
            return new AstNode?[0];
        }

        public delegate bool FilterFunc<AstNode>(AstNode node);

        public Gee.List<AstNode> find_nodes(FilterFunc<AstNode> filter_func) {
            Gee.LinkedList<AstNode> result = null;
            var stack = new Stack<AstNode>();
            stack.push(this);

            while (stack.any()) {
                var n = stack.pop();

                if (filter_func(n)) {
                    if (result == null) {
                        result = new Gee.LinkedList<AstNode>();
                    }
                    result.add(n);
                }
                
                if (!n.is_leaf) {
                    var only_child = n.get_child();
                    if (only_child != null) {
                        stack.push(only_child);
                    } else {
                        var children = n.get_children();
                        for (var i = children.length - 1; i >= 0; i--) {
                            var child = children[i];
                            if (child != null) {
                                stack.push(child);
                            }
                        }
                    }
                }
            }

            return result ?? _empty_node_linked_list;
        }
        
        public Gee.List<AstNode> find_nodes_bottom_up(FilterFunc<AstNode> filter_func) {
            var nodes_top_down = find_nodes(filter_func);
            if (nodes_top_down.size == 0) {
                return _empty_node_linked_list;
            }
            
            var nodes_bottom_up = new AstNode[nodes_top_down.size];
            var i = nodes_top_down.size;
            foreach (var node in nodes_top_down) {
                nodes_bottom_up[--i] = node;
            }
            return new Gee.ArrayList<DataValue>.wrap(nodes_bottom_up);
        }
        
        public AstNode? find_node(FilterFunc<AstNode> filter_func) {
            foreach (var node in find_nodes(filter_func)) {
                return node;
            }
            
            return null;
        }
    }
}
