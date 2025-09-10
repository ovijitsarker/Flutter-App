import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter/foundation.dart';
import 'aes_helper.dart';

// Config Page
class ConfigPage extends StatefulWidget {
  const ConfigPage({Key? key}) : super(key: key);

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _storage = const FlutterSecureStorage();
  String? _secretKey;

  @override
  void initState() {
    super.initState();
    _loadSecretKey();
  }

  Future<void> _loadSecretKey() async {
    final key = await _storage.read(key: 'secret_key');
    setState(() {
      _secretKey = key;
    });
  }

  Future<void> _saveSecretKey(String value) async {
    await _storage.write(key: 'secret_key', value: value);
    setState(() {
      _secretKey = value;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Secret Key saved!')));
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: _secretKey ?? '');
    showDialog(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Secret Key'),
            content: TextField(
              controller: controller,
              maxLength: 16,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter 16 character secret key',
                errorText: errorText,
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = controller.text;
                  if (value.length != 16) {
                    setState(
                      () => errorText =
                          'Secret Key must be exactly 16 characters',
                    );
                    return;
                  }
                  _saveSecretKey(value);
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Config')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secret Key',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showEditDialog,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key, color: Colors.orange, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _secretKey != null && _secretKey!.isNotEmpty
                              ? '*' * _secretKey!.length
                              : 'Tap to set secret key',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit, color: Colors.blueAccent),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// (Removed duplicate ConfigPage and stray imports)

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
          child: _LandingPageContent(),
        ),
      ),
    );
  }
}

class _LandingPageContent extends StatefulWidget {
  @override
  State<_LandingPageContent> createState() => _LandingPageContentState();
}

class _LandingPageContentState extends State<_LandingPageContent> {
  bool _showPasswordField = false;
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _obscurePassword = true;

  String _getCurrentPassword() {
    final now = DateTime.now();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hhmm = twoDigits(now.hour) + twoDigits(now.minute);
    final dd = twoDigits(now.day);
    final mm = twoDigits(now.month);
    final yyyy = now.year.toString();
    return hhmm + dd + mm + yyyy;
  }

  void _onContinuePressed() {
    setState(() {
      _showPasswordField = true;
      _errorText = null;
    });
  }

  void _onPasswordSubmit() {
    final input = _passwordController.text.trim();
    final expected = _getCurrentPassword();
    if (input == expected) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => AuthGate()));
    } else {
      setState(() {
        _errorText = 'Incorrect password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Welcome to Password Manager',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (!_showPasswordField)
          ElevatedButton(
            onPressed: _onContinuePressed,
            child: const Text('Continue'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
          ),
        if (_showPasswordField) ...[
          const Text(
            'Enter password', //(current time and date, e.g. 133519082025)
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Password',
              errorText: _errorText,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _onPasswordSubmit(),
            autofocus: true,
            obscureText: _obscurePassword,
          ),
          const SizedBox(height: 8),
          const Text(
            "Today is a gift, that's why they call it Present.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _onPasswordSubmit,
            child: const Text('Submit'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
          ),
        ],
      ],
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
  void _confirmDeletePassword(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password'),
        content: const Text('Are you sure you want to delete this password?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePassword(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPasswords() async {
    final storage = FlutterSecureStorage();
    String? secretKey = await storage.read(key: 'secret_key');
    if (secretKey == null || secretKey.isEmpty) {
      // Prompt user to enter secret key
      final controller = TextEditingController();
      String? errorText;
      bool? submitted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Enter Secret Key'),
              content: TextField(
                controller: controller,
                maxLength: 16,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter 16 character secret key',
                  errorText: errorText,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.length != 16) {
                      setState(
                        () => errorText =
                            'Secret Key must be exactly 16 characters',
                      );
                      return;
                    }
                    secretKey = controller.text;
                    storage.write(key: 'secret_key', value: secretKey);
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      );
      if (submitted != true) {
        // User cancelled
        return;
      }
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (result == null || result.files.single.path == null) {
        // User canceled
        return;
      }
      final file = File(result.files.single.path!);
      final encryptedContent = await file.readAsString();
      String content;
      try {
        content = AESHelper.decrypt(encryptedContent, secretKey!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to decrypt file. Please check your secret key.',
            ),
          ),
        );
        return;
      }
      final entries = content.split('---');
      int added = 0;
      for (final entry in entries) {
        final lines = entry.trim().split('\n');
        if (lines.length < 2) continue;
        String title = '',
            url = '',
            email = '',
            username = '',
            password = '',
            passkey = '',
            remarks = '';
        for (final line in lines) {
          if (line.startsWith('Title:')) {
            title = line.replaceFirst('Title:', '').trim();
          } else if (line.startsWith('URL:')) {
            url = line.replaceFirst('URL:', '').trim();
          } else if (line.startsWith('Email:')) {
            email = line.replaceFirst('Email:', '').trim();
          } else if (line.startsWith('User Name:')) {
            username = line.replaceFirst('User Name:', '').trim();
          } else if (line.startsWith('Password:')) {
            password = line.replaceFirst('Password:', '').trim();
          } else if (line.startsWith('Passkey:')) {
            passkey = line.replaceFirst('Passkey:', '').trim();
          } else if (line.startsWith('Remarks:')) {
            remarks = line.replaceFirst('Remarks:', '').trim();
          }
        }
        if (title.isNotEmpty && password.isNotEmpty) {
          _passwords.add({
            'title': title,
            'url': url,
            'email': email,
            'username': username,
            'password': password,
            'passkey': passkey,
            'remarks': remarks,
          });
          added++;
        }
      }
      if (added > 0) {
        await _savePasswords();
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imported $added password(s)')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid passwords found in file.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to import: $e')));
    }
  }

  Future<void> _downloadPasswords() async {
    final storage = FlutterSecureStorage();
    final secretKey = await storage.read(key: 'secret_key');
    if (secretKey == null || secretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please set your Secret Key in Config before downloading.',
          ),
        ),
      );
      return;
    }
    try {
      final buffer = StringBuffer();
      for (final entry in _passwords) {
        buffer.writeln('Title:    \t${entry['title'] ?? ''}');
        buffer.writeln('URL:      \t${entry['url'] ?? ''}');
        buffer.writeln('Email:    \t${entry['email'] ?? ''}');
        buffer.writeln('User Name:\t${entry['username'] ?? ''}');
        buffer.writeln('Password: \t${entry['password'] ?? ''}');
        buffer.writeln('Passkey:  \t${entry['passkey'] ?? ''}');
        buffer.writeln('Remarks:  \t${entry['remarks'] ?? ''}');
        buffer.writeln('---');
      }
      final text = buffer.toString();
      final encrypted = AESHelper.encrypt(text, secretKey);

      // Format: 2025_08_17_01_34_PM_password.txt
      final now = DateTime.now();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      int hour = now.hour;
      String ampm = hour >= 12 ? 'pm' : 'am';
      int hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final dateStr =
          '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}${twoDigits(hour12)}${twoDigits(now.minute)}${ampm}_password.txt';

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export not supported on web.')),
        );
        return;
      }
      if (Platform.isAndroid || Platform.isIOS) {
        final params = SaveFileDialogParams(
          data: Uint8List.fromList(encrypted.codeUnits),
          fileName: dateStr,
        );
        final filePath = await FlutterFileDialog.saveFile(params: params);
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Passwords saved to: $filePath')),
          );
        } else {
          // User cancelled
        }
      } else {
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Passwords As',
          fileName: dateStr,
          type: FileType.custom,
          allowedExtensions: ['txt'],
        );
        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsString(encrypted);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Passwords saved to: $outputPath')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save file: $e')));
    }
  }

  String _searchQuery = '';
  final List<Map<String, String>> _passwords = [];
  final _storage = const FlutterSecureStorage();
  final String _storageKey = 'passwords';
  final Map<int, bool> _showPassword = {};
  final Map<int, bool> _expanded = {};

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
            'url': parts.length > 1 ? parts[1] : '',
            'password': parts.length > 2 ? parts[2] : '',
            'passkey': parts.length > 3 ? parts[3] : '',
            'remarks': parts.length > 4 ? parts[4] : '',
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
              '${e['title']}::${e['url'] ?? ''}::${e['password']}::${e['passkey'] ?? ''}::${e['remarks'] ?? ''}',
        )
        .join('|');
    await _storage.write(key: _storageKey, value: data);
  }

  void _addPassword(
    String title,
    String url,
    String email,
    String username,
    String password,
    String passkey,
    String remarks,
  ) {
    setState(() {
      _passwords.add({
        'title': title,
        'url': url,
        'email': email,
        'username': username,
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
    String newUrl,
    String newEmail,
    String newUsername,
    String newPassword,
    String newPasskey,
    String newRemarks,
  ) {
    setState(() {
      _passwords[index] = {
        'title': newTitle,
        'url': newUrl,
        'email': newEmail,
        'username': newUsername,
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
      onSave: (title, url, email, username, password, passkey, remarks) {
        _addPassword(title, url, email, username, password, passkey, remarks);
      },
    );
  }

  void _showEditPasswordDialog(int index) {
    final current = _passwords[index];
    _showPasswordDialog(
      initialTitle: current['title'] ?? '',
      initialUrl: current['url'] ?? '',
      initialEmail: current['email'] ?? '',
      initialUsername: current['username'] ?? '',
      initialPassword: current['password'] ?? '',
      initialPasskey: current['passkey'] ?? '',
      initialRemarks: current['remarks'] ?? '',
      onSave: (title, url, email, username, password, passkey, remarks) {
        _editPassword(
          index,
          title,
          url,
          email,
          username,
          password,
          passkey,
          remarks,
        );
      },
    );
  }

  void _showPasswordDialog({
    String initialTitle = '',
    String initialUrl = '',
    String initialEmail = '',
    String initialUsername = '',
    String initialPassword = '',
    String initialPasskey = '',
    String initialRemarks = '',
    required void Function(
      String,
      String,
      String,
      String,
      String,
      String,
      String,
    )
    onSave,
  }) {
    String title = initialTitle;
    String url = initialUrl;
    String email = initialEmail;
    String username = initialUsername;
    String password = initialPassword;
    String passkey = initialPasskey;
    String remarks = initialRemarks;
    final titleController = TextEditingController(text: initialTitle);
    final urlController = TextEditingController(text: initialUrl);
    final emailController = TextEditingController(text: initialEmail);
    final usernameController = TextEditingController(text: initialUsername);
    final passwordController = TextEditingController(text: initialPassword);
    final passkeyController = TextEditingController(text: initialPasskey);
    final remarksController = TextEditingController(text: initialRemarks);
    bool showPassword = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                  decoration: const InputDecoration(labelText: 'URL'),
                  controller: urlController,
                  onChanged: (value) => url = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  controller: emailController,
                  onChanged: (value) => email = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'User Name'),
                  controller: usernameController,
                  onChanged: (value) => username = value,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                  controller: passwordController,
                  onChanged: (value) => password = value,
                  obscureText: !showPassword,
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
                  onSave(
                    title,
                    url,
                    email,
                    username,
                    password,
                    passkey,
                    remarks,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Config',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ConfigPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download as TXT',
            onPressed: _downloadPasswords,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload TXT',
            onPressed: _uploadPasswords,
          ),
        ],
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
      body: filteredPasswords.isEmpty
          ? Center(
              child: Text(
                'No passwords found.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : ListView.separated(
              itemCount: filteredPasswords.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final item = filteredPasswords[index];
                final realIndex = _passwords.indexOf(item);
                final isVisible = _showPassword[realIndex] ?? false;
                final isExpanded = _expanded[realIndex] ?? false;
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showEditPasswordDialog(realIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    if ((item['url'] ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.link,
                                            size: 16,
                                            color: Colors.blueGrey,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['url'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.blueGrey,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if ((item['email'] ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.email,
                                            size: 16,
                                            color: Colors.deepPurple,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['email'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.deepPurple,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if ((item['username'] ?? '')
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.indigo,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['username'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.indigo,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.lock_outline,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isVisible
                                                ? (item['password'] ?? '')
                                                : (item['password'] != null
                                                      ? '*' *
                                                            (item['password']!
                                                                .length)
                                                      : ''),
                                            style: const TextStyle(
                                              letterSpacing: 2,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.blueAccent,
                                ),
                                tooltip: isVisible
                                    ? 'Hide Password'
                                    : 'Show Password',
                                onPressed: () {
                                  setState(() {
                                    _showPassword[realIndex] = !isVisible;
                                  });
                                },
                              ),
                              IconButton(
                                icon: AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 28,
                                  ),
                                ),
                                tooltip: isExpanded ? 'Collapse' : 'Expand',
                                onPressed: () {
                                  setState(() {
                                    _expanded[realIndex] = !isExpanded;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete',
                                onPressed: () =>
                                    _confirmDeletePassword(realIndex),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((item['passkey'] ?? '').isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.vpn_key,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item['passkey'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              if ((item['remarks'] ?? '').isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.comment,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item['remarks'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black54,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
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
