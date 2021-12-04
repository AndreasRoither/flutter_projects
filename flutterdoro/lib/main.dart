import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        backgroundColor: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.blueGrey,
        primarySwatch: Colors.blueGrey,
      ),
      home: const SafeArea(child: HomePage(title: "Flutterdoro")),
    );
  }
}

enum PomodoroStates { focus, shortBreak, longBreak }

class PomodoroStateMachine {
  int _round = 1;

  int get round => _round;
  int maxRounds = 4;
  bool _focusActive = true;
  bool _breakActive = false;
  PomodoroStates _state = PomodoroStates.focus;

  PomodoroStates get state => _state;

  PomodoroStateMachine(this.maxRounds);

  PomodoroStates nextState() {
    if (_breakActive) {
      _state = PomodoroStates.focus;
      _focusActive = true;
      _breakActive = false;

      if (round == maxRounds) {
        _round = 1;
      } else {
        _round++;
      }
    } else if (_focusActive && _round == maxRounds) {
      _state = PomodoroStates.longBreak;
      _breakActive = true;
    } else if (_focusActive) {
      _state = PomodoroStates.shortBreak;
      _breakActive = true;
    }

    return _state;
  }

  PomodoroStates resetState() {
    _state = PomodoroStates.focus;
    _round = 1;
    return _state;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _oneSec = const Duration(seconds: 1);
  final alarmAudioPath = "notification.mp3";
  AudioCache player = AudioCache();
  PomodoroStateMachine stateMachine = PomodoroStateMachine(4);

  Timer? _timer;
  String _stateTitle = "Focus";
  bool _muted = false;

  // time in seconds
  int _time = 1500;
  int _focus = 1500;
  int _shortBreak = 300;
  int _longBreak = 900;

  void playSound() {
    if (!_muted) {
      player.play(alarmAudioPath);
    }
  }

  void updateTimerAndTitle(PomodoroStates state) {
    switch (state) {
      case PomodoroStates.focus:
        _stateTitle = "Focus";
        _time = _focus;
        break;
      case PomodoroStates.shortBreak:
        _stateTitle = "Short break~";
        _time = _shortBreak;
        break;
      case PomodoroStates.longBreak:
        _stateTitle = "Long break~";
        _time = _longBreak;
        break;
    }
  }

  void _tick(_) {
    if (_time == 0) {
      updateTimerAndTitle(stateMachine.nextState());
      playSound();
      _timer!.cancel();
      _timer = null;
      _timer = Timer.periodic(_oneSec, _tick);
      setState(() {});
    } else {
      setState(() {
        _time--;
      });
    }
  }

  void _handleTimerState() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    } else {
      _timer = Timer.periodic(_oneSec, _tick);
    }
    setState(() {});
  }

  void _handleRoundsReset() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    stateMachine.resetState();
    _time = _focus;
    _stateTitle = "Focus";

    setState(() {});
  }

  void _handleTimerValuesReset() {
    _time = 1500;
    _focus = 1500;
    _shortBreak = 300;
    _longBreak = 900;
    stateMachine.maxRounds = 4;
    setState(() {});
  }

  void _handleSkip() {
    updateTimerAndTitle(stateMachine.nextState());
    playSound();
    setState(() {});
  }

  Widget buildTime() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(_time ~/ 60);
    final seconds = twoDigits(_time % 60);

    return Text(
      '$minutes:$seconds',
      style: const TextStyle(fontSize: 80, color: Colors.white70),
    );
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: Text(widget.title),
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.blueGrey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            children: [
              Container(
                height: 100,
                color: Colors.blueGrey,
                child: const Center(
                  child: Text(
                    "Settings",
                    style: TextStyle(color: Colors.white70, fontSize: 40),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 1, color: Colors.grey),
                  const SizedBox(
                    height: 15,
                  ),
                  const Text(
                    "Focus",
                    style: TextStyle(color: Colors.white70, fontSize: 25),
                  ),
                  Text(
                    '${_focus ~/ 60}:00',
                    style: const TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                  Slider(
                    activeColor: Colors.redAccent,
                    inactiveColor: Colors.white70,
                    value: _focus / 60,
                    min: 0,
                    max: 90,
                    label: (_focus ~/ 60).toString(),
                    onChanged: (double value) {
                      setState(() {
                        _focus = value.toInt() * 60;
                        updateTimerAndTitle(stateMachine._state);
                      });
                    },
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  const Text(
                    "Short Break",
                    style: TextStyle(color: Colors.white70, fontSize: 25),
                  ),
                  Text(
                    '${_shortBreak ~/ 60}:00',
                    style: const TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                  Slider(
                    activeColor: Colors.lightGreen,
                    inactiveColor: Colors.white70,
                    value: _shortBreak / 60,
                    min: 0,
                    max: 90,
                    label: (_shortBreak ~/ 60).toString(),
                    onChanged: (double value) {
                      setState(() {
                        _shortBreak = value.toInt() * 60;
                        updateTimerAndTitle(stateMachine._state);
                      });
                    },
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  const Text(
                    "Long Break",
                    style: TextStyle(color: Colors.white70, fontSize: 25),
                  ),
                  Text(
                    '${_longBreak ~/ 60}:00',
                    style: const TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                  Slider(
                    activeColor: Colors.lightBlue,
                    inactiveColor: Colors.white70,
                    value: _longBreak / 60,
                    min: 0,
                    max: 90,
                    label: (_longBreak ~/ 60).toString(),
                    onChanged: (double value) {
                      setState(() {
                        _longBreak = value.toInt() * 60;
                        updateTimerAndTitle(stateMachine._state);
                      });
                    },
                  ),
                  const Text(
                    "Rounds",
                    style: TextStyle(color: Colors.white70, fontSize: 25),
                  ),
                  Text(
                    '${stateMachine.maxRounds}',
                    style: const TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                  Slider(
                    activeColor: Colors.grey,
                    inactiveColor: Colors.white70,
                    value: stateMachine.maxRounds.toDouble(),
                    min: 1,
                    max: 10,
                    label: stateMachine.maxRounds.toString(),
                    onChanged: (double value) {
                      setState(() {
                        stateMachine.maxRounds = value.toInt();
                        _handleRoundsReset();
                      });
                    },
                  ),
                  const SizedBox(
                    height: 45,
                  ),
                ],
              ),
              Center(
                child: GestureDetector(
                  onTap: _handleTimerValuesReset,
                  child: const Text(
                    "Reset defaults",
                    style: TextStyle(color: Colors.white70, fontSize: 25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            buildTime(),
            Text(
              _stateTitle,
              style: const TextStyle(color: Colors.white70, fontSize: 40),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 25, 0, 50),
              child: ElevatedButton(
                onPressed: _handleTimerState,
                child: _timer == null
                    ? const Icon(Icons.play_arrow, color: Colors.white70)
                    : const Icon(Icons.pause, color: Colors.white70),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(
                    const CircleBorder(
                        side: BorderSide(width: 1, color: Colors.white70)),
                  ),
                  padding: MaterialStateProperty.all(const EdgeInsets.all(25)),
                  backgroundColor: MaterialStateProperty.all(Colors.blueGrey),
                  overlayColor:
                      MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.grey;
                    }
                  }),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _handleRoundsReset,
                  child: Column(
                    children: [
                      Text(
                          'Round ${stateMachine.round}/${stateMachine.maxRounds}',
                          style: const TextStyle(color: Colors.white70)),
                      const Text("Reset",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  style: ButtonStyle(
                    padding:
                        MaterialStateProperty.all(const EdgeInsets.all(10)),
                    backgroundColor: MaterialStateProperty.all(Colors.blueGrey),
                    elevation: MaterialStateProperty.all(0),
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.grey;
                        }
                      },
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _handleSkip,
                      child: const Icon(Icons.skip_next, color: Colors.white70),
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(const CircleBorder(
                            side: BorderSide(
                                width: 0, color: Colors.transparent))),
                        padding:
                            MaterialStateProperty.all(const EdgeInsets.all(10)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.blueGrey),
                        elevation: MaterialStateProperty.all(0),
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(MaterialState.pressed)) {
                              return Colors.grey;
                            }
                          },
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _muted = !_muted;
                        });
                      },
                      child: _muted
                          ? const Icon(Icons.volume_off, color: Colors.white70)
                          : const Icon(Icons.volume_up, color: Colors.white70),
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(const CircleBorder(
                            side: BorderSide(
                                width: 0, color: Colors.transparent))),
                        padding:
                            MaterialStateProperty.all(const EdgeInsets.all(10)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.blueGrey),
                        elevation: MaterialStateProperty.all(0),
                        overlayColor:
                            MaterialStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(MaterialState.pressed)) {
                            return Colors.grey;
                          }
                        }),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
