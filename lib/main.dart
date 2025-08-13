import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(PasswordManagerApp());
}

class PasswordManagerApp extends StatelessWidget {
  PasswordManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Password Manager',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => AuthGate()),
                  );
                },
                child: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _authenticated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final auth = LocalAuthentication();
    try {
      final canCheck =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canCheck) {
        final didAuth = await auth.authenticate(
          localizedReason: 'Please authenticate to access your passwords',
        );
        if (didAuth) {
          setState(() => _authenticated = true);
        } else {
          setState(() => _error = 'Authentication failed.');
        }
      } else {
        // If device does not support biometrics or PIN, skip authentication
        setState(() => _authenticated = true);
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return PasswordListScreen();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Authenticate')),
      body: Center(
        child: _error != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Try Again'),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class PasswordListScreen extends StatefulWidget {
  const PasswordListScreen({super.key});

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  String _searchQuery = '';
  final List<Map<String, String>> _passwords = [];
  final _storage = const FlutterSecureStorage();
  final String _storageKey = 'passwords';

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    final data = await _storage.read(key: _storageKey);
    if (data != null && data.isNotEmpty) {
      final List<Map<String, String>> loaded = List<Map<String, String>>.from(
        (data.split('|').where((e) => e.isNotEmpty)).map((entry) {
          final parts = entry.split('::');
          // Support backward compatibility for old entries
          return {
            'title': parts.length > 0 ? parts[0] : '',
            'password': parts.length > 1 ? parts[1] : '',
            'passkey': parts.length > 2 ? parts[2] : '',
            'remarks': parts.length > 3 ? parts[3] : '',
          };
        }),
      );
      setState(() {
        _passwords.clear();
        _passwords.addAll(loaded);
      });
    }
  }

  Future<void> _savePasswords() async {
    final data = _passwords
        .map(
          (e) =>
              '${e['title']}::${e['password']}::${e['passkey'] ?? ''}::${e['remarks'] ?? ''}',
        )
        .join('|');
    await _storage.write(key: _storageKey, value: data);
  }

  void _addPassword(
    String title,
    String password,
    String passkey,
    String remarks,
  ) {
    setState(() {
      _passwords.add({
        'title': title,
        'password': password,
        'passkey': passkey,
        'remarks': remarks,
      });
    });
    _savePasswords();
  }

  void _editPassword(
    int index,
    String newTitle,
    String newPassword,
    String newPasskey,
    String newRemarks,
  ) {
    setState(() {
      _passwords[index] = {
        'title': newTitle,
        'password': newPassword,
        'passkey': newPasskey,
        'remarks': newRemarks,
      };
    });
    _savePasswords();
  }

  void _deletePassword(int index) {
    setState(() {
      _passwords.removeAt(index);
    });
    _savePasswords();
  }

  void _showAddPasswordDialog() {
    _showPasswordDialog(
      onSave: (title, password, passkey, remarks) {
        _addPassword(title, password, passkey, remarks);
      },
    );
  }

  void _showEditPasswordDialog(int index) {
    final current = _passwords[index];
    _showPasswordDialog(
      initialTitle: current['title'] ?? '',
      initialPassword: current['password'] ?? '',
      initialPasskey: current['passkey'] ?? '',
      initialRemarks: current['remarks'] ?? '',
      onSave: (title, password, passkey, remarks) {
        _editPassword(index, title, password, passkey, remarks);
      },
    );
  }

  void _showPasswordDialog({
    String initialTitle = '',
    String initialPassword = '',
    String initialPasskey = '',
    String initialRemarks = '',
    required void Function(String, String, String, String) onSave,
  }) {
    String title = initialTitle;
    String password = initialPassword;
    String passkey = initialPasskey;
    String remarks = initialRemarks;
    final titleController = TextEditingController(text: initialTitle);
    final passwordController = TextEditingController(text: initialPassword);
    final passkeyController = TextEditingController(text: initialPasskey);
    final remarksController = TextEditingController(text: initialRemarks);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initialTitle.isEmpty ? 'Add Password' : 'Edit Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
                controller: titleController,
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Password'),
                controller: passwordController,
                onChanged: (value) => password = value,
                obscureText: true,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Passkey'),
                controller: passkeyController,
                onChanged: (value) => passkey = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Remarks'),
                controller: remarksController,
                onChanged: (value) => remarks = value,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (title.isNotEmpty && password.isNotEmpty) {
                onSave(title, password, passkey, remarks);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPasswords = _searchQuery.isEmpty
        ? _passwords
        : _passwords
              .where(
                (item) => (item['title'] ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Manager'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredPasswords.length,
        itemBuilder: (context, index) {
          final item = filteredPasswords[index];
          // Find the real index in the original list for edit/delete
          final realIndex = _passwords.indexOf(item);
          return Dismissible(
            key: Key('${item['title']}_${item['password']}_$realIndex'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deletePassword(realIndex),
            child: ListTile(
              title: Text(item['title'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Password: ${item['password'] ?? ''}'),
                  Text('Passkey: ${item['passkey'] ?? ''}'),
                  Text('Remarks: ${item['remarks'] ?? ''}'),
                ],
              ),
              isThreeLine: true,
              onTap: () => _showEditPasswordDialog(realIndex),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPasswordDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
