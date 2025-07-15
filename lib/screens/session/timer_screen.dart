import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

/// Modo de temporizador
enum TimerMode { rest, hiit, tabata }

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerMode? _mode;
  bool _isCountingDown = true;
  bool _soundOn = true;
  bool _vibrationOn = true;

  final TextEditingController _workCtrl = TextEditingController(text: '30');
  final TextEditingController _restCtrl = TextEditingController(text: '10');
  final TextEditingController _roundsCtrl = TextEditingController(text: '5');

  int _currentRound = 0;
  late int _totalRounds;
  late int _workSec;
  late int _restSec;

  Duration _time = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  String _phase = 'Work';

  final AudioPlayer _audio = AudioPlayer();

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    _workCtrl.dispose();
    _restCtrl.dispose();
    _roundsCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_mode == null) return;
    _workSec = int.tryParse(_workCtrl.text) ?? 30;
    _restSec = int.tryParse(_restCtrl.text) ?? 10;
    _totalRounds = int.tryParse(_roundsCtrl.text) ?? 1;
    _currentRound = 1;
    _phase = 'Work';
    _setTime();
    _isRunning = true;
    _runPhaseLoop();
    setState(() {});
  }

  void _runPhaseLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_isCountingDown) {
          _time -= const Duration(seconds: 1);
        } else {
          _time += const Duration(seconds: 1);
        }

        bool phaseComplete = _isCountingDown
            ? _time.inSeconds <= 0
            : (_phase == 'Work'
                ? _time.inSeconds >= _workSec
                : _time.inSeconds >= _restSec);

        if (phaseComplete) {
          _playAlert();
          if (_phase == 'Work') {
            _phase = 'Rest';
            _setTime();
          } else {
            if (_currentRound < _totalRounds) {
              _currentRound++;
              _phase = 'Work';
              _setTime();
            } else {
              _stopTimer();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Temporizador completado 🎉')),);
            }
          }
        }
      });
    });
  }

  void _setTime() {
    if (_isCountingDown) {
      _time = Duration(seconds: _phase == 'Work' ? _workSec : _restSec);
    } else {
      _time = Duration.zero;
    }
  }

  Future<void> _playAlert() async {
    if (_soundOn) {
      await _audio.play(AssetSource('sounds/beep.mp3'));
    }
    if (_vibrationOn && (await Vibration.hasVibrator() ?? false)) {
      Vibration.vibrate(duration: 500);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  String _formattedTime() {
    final mins = _time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = _time.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temporizador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Modo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: TimerMode.values.map((m) {
                final selected = _mode == m;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected ? Colors.blue : Colors.grey[300],
                    foregroundColor: selected ? Colors.white : Colors.black,
                  ),
                  onPressed: () => setState(() => _mode = m),
                  child: Text(m.name.toUpperCase()),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_mode != null) ...[
              const Text('Configuración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _workCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duración actividad (s)'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _restCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duración descanso (s)'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _roundsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número de rondas'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Cuenta regresiva'),
                value: _isCountingDown,
                onChanged: (v) => setState(() => _isCountingDown = v),
              ),
              SwitchListTile(
                title: const Text('Sonido'),
                value: _soundOn,
                onChanged: (v) => setState(() => _soundOn = v),
              ),
              SwitchListTile(
                title: const Text('Vibración'),
                value: _vibrationOn,
                onChanged: (v) => setState(() => _vibrationOn = v),
              ),
              const SizedBox(height: 24),
              // Mostrando tiempo y fase actual
              Text(
                _formattedTime(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _phase == 'Work' ? 'Comienza el ejercicio' : 'Descanso',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              if (!_isRunning)
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _stopTimer,
                  icon: const Icon(Icons.stop),
                  label: const Text('Detener'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
