import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TodoApp());
}

class Todo {
  final String id;
  final String title;
  final bool isCompleted;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Todo copyWith({String? id, String? title, bool? isCompleted}) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Todo.fromJson(String source) => Todo.fromMap(jsonDecode(source));
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late SharedPreferences _prefs;
  late List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTodos();
  }

  void _loadTodos() {
    final List<String>? todoStrings = _prefs.getStringList('todos');
    if (todoStrings != null) {
      setState(() {
        _todos = todoStrings.map((todoString) {
          final Map<String, dynamic> todoMap = jsonDecode(todoString);
          return Todo.fromMap(todoMap);
        }).toList();
      });
    }
  }

  Future<void> _saveTodos() async {
    final List<String> todoStrings =
    _todos.map((todo) => todo.toJson()).toList();
    await _prefs.setStringList('todos', todoStrings);
  }

  void _addTodo(String title) {
    final newTodo = Todo(
      id: DateTime.now().toString(),
      title: title,
    );
    setState(() {
      _todos.add(newTodo);
    });
    _saveTodos();
  }

  void _updateTodoTitle(int index, String newTitle) {
    setState(() {
      _todos[index] = _todos[index].copyWith(title: newTitle);
    });
    _saveTodos();
  }

  void _toggleTodoCompleted(int index) {
    setState(() {
      _todos[index] = _todos[index].copyWith(
        isCompleted: !_todos[index].isCompleted,
      );
    });
    _saveTodos();
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),backgroundColor: Colors.greenAccent,
      ),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final todo = _todos[index];
          return ListTile(
            onTap: () {
              if (!todo.isCompleted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    String updatedTitle = todo.title;
                    return AlertDialog(
                      title: Text('Update Todo'),
                      content: TextField(
                        onChanged: (value) {
                          updatedTitle = value;
                        },
                        controller: TextEditingController(text: todo.title),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _updateTodoTitle(index, updatedTitle);
                            Navigator.pop(context);
                          },
                          child: Text('Update'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Cannot Update Task'),
                      content: Text('Uncheck the task to update.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            leading: Checkbox(
              value: todo.isCompleted,
              onChanged: (_) => _toggleTodoCompleted(index),
            ),
            title: Text(
              todo.title,
              style: TextStyle(
                decoration:
                todo.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteTodo(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Add Todo'),
              content: TextField(
                onChanged: (value) {
                  // Nothing to do here, just to show the linting error
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _addTodo(value);
                    Navigator.pop(context);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Enter your To do',
                ),
              ),
            ),
          );
        },
        child: Icon(Icons.add),backgroundColor: Colors.greenAccent,
      ),
    );
  }
}
