import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlwaAlameerApp());
}

class AlwaAlameerApp extends StatelessWidget {
  const AlwaAlameerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF174D38);
    return MaterialApp(
      title: 'علوة الأمير',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: brandGreen),
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const InventoryWebScreen(),
    );
  }
}

class InventoryWebScreen extends StatefulWidget {
  const InventoryWebScreen({super.key});

  @override
  State<InventoryWebScreen> createState() => _InventoryWebScreenState();
}

class _InventoryWebScreenState extends State<InventoryWebScreen> {
  static final Uri _homeUri =
      Uri.parse('https://inventory-and-sales-jgrk.bolt.host/');
  static const String _host = 'inventory-and-sales-jgrk.bolt.host';

  late final WebViewController _webController;
  int _progress = 0;
  bool _hasMainFrameError = false;
  bool _isLoading = true;
  String _errorMessage = 'تعذر الاتصال بالموقع. تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F7F5))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasMainFrameError = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _progress = 100;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _hasMainFrameError = true;
                _isLoading = false;
                _errorMessage = 'تعذر تحميل الموقع. تأكد من اتصال الإنترنت ثم أعد المحاولة.';
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // Keep the inventory website and its subdomains inside the app.
            if (uri.scheme == 'https' &&
                (uri.host == _host || uri.host.endsWith('.bolt.host'))) {
              return NavigationDecision.navigate;
            }

            // Open telephone, email, WhatsApp and other external links with Android apps.
            if (uri.scheme == 'http' || uri.scheme == 'https' ||
                uri.scheme == 'tel' || uri.scheme == 'mailto' ||
                uri.scheme == 'sms' || uri.scheme == 'whatsapp') {
              _openExternal(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(_homeUri);
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على تطبيق لفتح هذا الرابط')),
        );
      }
    }
  }

  Future<void> _reload() async {
    setState(() {
      _hasMainFrameError = false;
      _isLoading = true;
      _progress = 0;
    });
    await _webController.loadRequest(_homeUri);
  }

  Future<void> _handleBack() async {
    if (await _webController.canGoBack()) {
      await _webController.goBack();
    } else if (mounted) {
      // At the home page, ask before closing the app.
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('الخروج من التطبيق'),
          content: const Text('هل تريد إغلاق تطبيق علوة الأمير؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('خروج'),
            ),
          ],
        ),
      );
      if (shouldClose == true) SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('علوة الأمير', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: 'إعادة تحميل',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 3,
                    backgroundColor: Colors.white24,
                    color: const Color(0xFFFFD166),
                  ),
                )
              : null,
        ),
        body: _hasMainFrameError
            ? _ErrorView(message: _errorMessage, onRetry: _reload)
            : WebViewWidget(controller: _webController),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFF174D38)),
            const SizedBox(height: 18),
            const Text('لا يوجد اتصال', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}