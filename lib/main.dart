import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

const yellow = Color.fromRGBO(240, 210, 58, 1);

void main() {
  runApp(
    MaterialApp(
      home: Home(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashColor: Colors.white,
        primaryColor: Colors.white,
        primarySwatch: Colors.grey,
        accentColor: yellow,
        cursorColor: yellow,
        brightness: Brightness.light,
        textSelectionColor: yellow,
        textSelectionHandleColor: yellow,
      ),
    )
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _toDoList = [];
  String _dateTime;
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  final _toDoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, 
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark));
      
    _dateTime = getDate(DateTime.now());  
    
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  String getDate(DateTime date) {
    return date.toString()
               .substring(0, 10)
               .replaceAll("-", "");
  }

  void _addToDo() {
    if(_toDoController.text.trim().isNotEmpty) {
      setState(() {
        Map<String, dynamic> newToDo = {};
        newToDo["title"] = _toDoController.text.trim();
        _toDoController.text = "";
        newToDo["ok"] = false;
        newToDo["dateComp"] = _dateTime;
        newToDo["date"] = "${_dateTime.substring(6,8)}/${_dateTime.substring(4,6)}/${_dateTime.substring(0,4)}";
        _dateTime = getDate(DateTime.now());
        _toDoList.add(newToDo); 
        _refresh(0);
        _saveData();
      });
    }
  }
  
  Future<Null> _refresh(int time) async {
    await Future.delayed(Duration(milliseconds: time));
    setState(() {
      _toDoList.sort((a, b) {
        if(int.parse(a["dateComp"]) > int.parse(b["dateComp"])) {
          return 1;
        }
        else if(int.parse(a["dateComp"]) < int.parse(b["dateComp"])){
          return -1;
        }
        else {
          return 0;
        }
      });

      _toDoList.sort((a, b) {
        if(a["ok"] && !b["ok"]) {
          return 1;
        }
        else if(!a["ok"] && b["ok"]){
          return -1;
        }
        else {
          return 0;
        }
      });

      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Tarefas", style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        elevation: 0,
        brightness: Brightness.light,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(1000),
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 30),
                      child: TextField( 
                        
                        autocorrect: false,
                        //autofocus: true,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                        controller: _toDoController,
                        decoration: InputDecoration(
                          suffixIcon: InkWell(
                                excludeFromSemantics: false,
                                borderRadius: BorderRadius.circular(30),
                                onTap: () => 
                                  showDatePicker( 
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2018),
                                    lastDate: DateTime(2050)
                                  ).then((date) {
                                  setState(() {
                                    _dateTime = getDate(date);
                                  });
                                }),
                                child: Icon(
                                  Icons.calendar_today, 
                                  color: Colors.grey, 
                                  size: 20,),),
                          hasFloatingPlaceholder: false,
                          labelText: "Nova tarefa",
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(15)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white), 
                            borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ),
                  RaisedButton(
                    color: yellow,
                    elevation: 5,
                    padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Text("ADD"),
                    textColor: Colors.white,
                    onPressed: _addToDo,
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildItem (BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        activeColor: yellow,
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        subtitle: Text(_toDoList[index]["date"], style: TextStyle(fontSize: 13),),
        secondary: CircleAvatar(
          backgroundColor: yellow,
          foregroundColor: Colors.white,
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.hourglass_empty),
        ),
        onChanged: (check) {
          setState(() {
            _toDoList[index]["ok"] = check;
            _refresh(250);
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            backgroundColor: Color.fromRGBO(245, 245, 245, 1),
            content: Text(
              "Tarefa \"${_lastRemoved["title"]}\" removida!", 
              style: TextStyle(color: Color.fromRGBO(112, 112, 112, 1)),),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar(); 
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    }
    catch(e) {
      return null;
    }
  }
}
