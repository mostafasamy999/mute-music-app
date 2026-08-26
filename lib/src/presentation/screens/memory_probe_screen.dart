import 'package:flutter/material.dart';
import 'package:mute_music_app/src/config/theme/app_theme.dart';
import 'package:mute_music_app/src/core/di/injector.dart';
import 'package:mute_music_app/src/core/diagnostics/memory_probe.dart';

// TEMPORARY diagnostic screen. Never shown to users, so the labels below stay
// as plain constants instead of going through S.of(context).
const String _title = 'Memory probe';
const String _runLabel = 'Run probe';
const String _idle = 'Press the button. Watch the PEAK number.';

class MemoryProbeScreen extends StatefulWidget {
  const MemoryProbeScreen({super.key});

  @override
  State<MemoryProbeScreen> createState() => _MemoryProbeScreenState();
}

class _MemoryProbeScreenState extends State<MemoryProbeScreen> {
  final ValueNotifier<List<String>> _lines = ValueNotifier<List<String>>(
    <String>[],
  );
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  final ValueNotifier<bool> _running = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _lines.dispose();
    _progress.dispose();
    _running.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    _running.value = true;
    _lines.value = <String>[];
    try {
      await injector<MemoryProbe>().run(
        log: (String line) {
          debugPrint('PROBE | $line');
          _lines.value = <String>[..._lines.value, line];
        },
        progress: (double value) => _progress.value = value,
      );
    } on Object catch (error) {
      _lines.value = <String>[..._lines.value, 'ERROR: $error'];
    }
    _running.value = false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(_title)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: _running,
              builder: (_, bool running, _) => FilledButton(
                onPressed: running ? null : _run,
                child: const Text(_runLabel),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _progressBar(),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _output(context)),
          ],
        ),
      ),
    ),
  );

  Widget _progressBar() => ValueListenableBuilder<double>(
    valueListenable: _progress,
    builder: (_, double value, _) => value <= 0 || value >= 1
        ? const SizedBox.shrink()
        : LinearProgressIndicator(value: value),
  );

  Widget _output(BuildContext context) => ValueListenableBuilder<List<String>>(
    valueListenable: _lines,
    builder: (_, List<String> lines, _) => lines.isEmpty
        ? const Center(child: Text(_idle))
        : ListView.builder(
            itemCount: lines.length,
            itemBuilder: (_, int index) => Text(
              lines[index],
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
  );
}
