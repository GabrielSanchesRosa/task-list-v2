import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final taskController = TextEditingController();

  List taskList = [];

  Map<String, dynamic>? lastRemoved;
  int? lastRemovedPos;

  @override
  void initState() {
    super.initState();

    readData().then((data) {
      setState(() {
        taskList = json.decode(data);
      });
    });
  }

  void addTask() {
    setState(() {
      Map<String, dynamic> newTask = Map();

      newTask["title"] = taskController.text;
      newTask["ok"] = false;

      taskController.clear();

      taskList.add(newTask);
      saveData(taskList);
    });
  }

  Future<Null> refresh() async {
    setState(() {
      taskList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });

      saveData(taskList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task List"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),

      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "New Task",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                    controller: taskController,
                  ),
                ),

                ElevatedButton(
                  onPressed: addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text("ADD", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              color: Colors.blueAccent,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: taskList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      child: CheckboxListTile(
        onChanged: (value) {
          setState(() {
            taskList[index]["ok"] = value;
            saveData(taskList);
          });
        },
        value: taskList[index]["ok"],
        title: Text(taskList[index]["title"]),
        activeColor: Colors.blueAccent,
        secondary: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(
            taskList[index]["ok"] ? Icons.check : Icons.error,
            color: Colors.white,
          ),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          lastRemoved = Map.from(taskList[index]);
          lastRemovedPos = index;
          taskList.removeAt(index);

          saveData(taskList);

          final snack = SnackBar(
            content: Text("Task ${lastRemoved!["title"]} removed!"),
            action: SnackBarAction(
              label: "Undo",
              onPressed: () {
                setState(() {
                  taskList.insert(lastRemovedPos!, lastRemoved);
                  saveData(taskList);
                });
              },
            ),
            duration: Duration(seconds: 5),
          );

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }
}

Future<File> getFile() async {
  final directory = await getApplicationDocumentsDirectory();

  return File("${directory.path}/data.json");
}

Future<File> saveData(List taskList) async {
  String data = json.encode(taskList);
  final file = await getFile();

  return file.writeAsString(data);
}

Future<String> readData() async {
  try {
    final file = await getFile();

    return file.readAsString();
  } catch (e) {
    return "Error";
  }
}
