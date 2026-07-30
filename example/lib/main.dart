import 'package:flutter/material.dart';
import 'package:tecta_inspector/tecta_inspector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Tecta Inspector
  TectaInspector.initialize(enabled: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tecta Inspector Example',
      navigatorKey: TectaInspector.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Add navigator observer to record routing logs automatically
      navigatorObservers: [
        TectaInspectorNavigatorObserver(),
      ],
      // Wrap application with TectaInspectorOverlay
      builder: (context, child) {
        return TectaInspectorOverlay(
          child: child ?? const SizedBox(),
        );
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TectaHttp _http = TectaHttp(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  );

  bool _inspectorEnabled = true;

  Future<void> _makeSuccessfulRequest() async {
    try {
      TectaInspector.log("Sending GET request to /posts/1...");
      final response = await _http.call(
        '/posts/1',
        method: MethodRequest.GET,
      );
      TectaInspector.log("Request succeeded! Status Code: ${response.statusCode}");
    } catch (e, stack) {
      TectaInspector.logError("API Call failed", error: e, stackTrace: stack);
    }
  }

  Future<void> _makeFailedRequest() async {
    try {
      TectaInspector.log("Sending GET request to an invalid endpoint...");
      // This will throw a 404 Not Found error
      await _http.call(
        '/invalid-endpoint',
        method: MethodRequest.GET,
      );
    } catch (e, stack) {
      // The interceptor automatically logs this network error,
      // but we can also manually log the caught exception details here.
      TectaInspector.logError(
        "Request failed (Expected 404)",
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _triggerCrash() {
    TectaInspector.log("Triggering a Null Pointer Exception...");
    // This will throw a Null Pointer Exception which will be automatically
    // caught by the unhandled error handlers we registered in initialize().
    String? nullString;
    final _ = nullString!.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tecta Inspector Demo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Configuration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Show Debugger Button'),
                        subtitle: const Text('Toggle the floating debugger overlay on/off'),
                        value: _inspectorEnabled,
                        onChanged: (val) {
                          setState(() {
                            _inspectorEnabled = val;
                            TectaInspector.initialize(enabled: val);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'LOG SIMULATIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _makeSuccessfulRequest,
                icon: const Icon(Icons.cloud_done_outlined),
                label: const Text('Send Successful GET Request (200)'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _makeFailedRequest,
                icon: const Icon(Icons.cloud_off_outlined),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('Send Failed GET Request (404)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  TectaInspector.log("This is a manual custom log message written by a developer.");
                },
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Save Custom Print Log'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  TectaInspector.logDatabase(
                    query: "INSERT INTO users (name, email) VALUES ('Tecta Demo', 'demo@tecta.id')",
                    result: "row inserted: 1",
                  );
                },
                icon: const Icon(Icons.storage_outlined),
                label: const Text('Save Custom Database Log'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/second-page'),
                      builder: (context) => const SecondPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_outlined),
                label: const Text('Navigate to Another Route'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AUTO-CATCH ERROR DEMO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _triggerCrash,
                icon: const Icon(Icons.flash_on_outlined),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('Trigger Unhandled Exception'),
              ),
              const SizedBox(height: 32),
              const Text(
                'Tip: Tap the teal floating bug icon at the bottom right to open the logs dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You are on the second page.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
