import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget{

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _scanLink(){

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Scanning Link...",
        )
      )
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "K A P E A",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5,),
                  const Text(
                    "Check before you open",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54
                    ),
                  ),
                  const SizedBox(height: 35,),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                      prefix: Text("https://"),
                      prefixIcon: Icon(Icons.link),
                      hintText: "Paste a link to check",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15,),
                  ElevatedButton(
                    onPressed: _scanLink,
                    child: const Text(
                      "Scan Link"
                    )
                  ),
                ],
              ),
            )
          ),
        ),
      ),
    );
  }
}