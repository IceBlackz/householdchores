import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'dashboard_screen.dart';

// 1. Initialize the PocketBase client
final pb = PocketBase('http://127.0.0.1:9010');

void main() {
  runApp(const HouseholdApp());
}

class HouseholdApp extends StatelessWidget {
  const HouseholdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Household Chores',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 2. The function that talks to your backend
  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      // Send the email and password to PocketBase
      final authData = await pb.collection('users').authWithPassword(
            _emailController.text,
            _passwordController.text,
          );
      
      // If successful, show a success message!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Success! Welcome back, ${authData.record.data['name'] ?? 'User'}!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on ClientException catch (e) {
      // PocketBase specifically throws this when the server rejects the request
      String friendlyError = 'Something went wrong.';
      
      if (e.statusCode == 400) {
        friendlyError = 'Incorrect email or password. Please try again.';
      } else if (e.statusCode == 0) {
        friendlyError = 'Cannot connect to the server. Check your network.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      // Catch any other weird app crashes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Household Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true, // Hides the password
              textInputAction: TextInputAction.done, // Changes mobile keyboard return key to "Done"
              onSubmitted: (_) => _login(), // Triggers the login function when you press Enter!
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}