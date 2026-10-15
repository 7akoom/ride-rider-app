import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../core/config/app_env.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design/components/components.dart';
import '../../../design/design_context.dart';

/// Opens [page] inside the app and returns when it is closed: by the rider, or by
/// itself once the provider sends the rider back to our return page.
Future<void> openPaymentPage(BuildContext context, Uri page) => Navigator.of(context).push(
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => PaymentPageScreen(page: page)),
    );

/// Our return pages on the API's own domain (web/pay/index.html in ride-platform):
/// https://<api>/pay/done/ after a payment, /pay/failed/ after a failure or a cancel.
bool isPaymentReturnPage(Uri url, {String apiBaseUrl = AppEnv.apiBaseUrl}) {
  final api = Uri.tryParse(apiBaseUrl);

  if (api == null || url.host.isEmpty || url.host.toLowerCase() != api.host.toLowerCase()) {
    return false;
  }

  return RegExp(r'^/pay/(done|failed)/?$').hasMatch(url.path);
}

/// The provider's payment page (ZainCash's), in a web view inside the app. The card
/// number or wallet PIN is typed on the provider's own page and never reaches the
/// app. When the provider sends the rider to our return page, the page is left a
/// moment to hand its token to the server (it settles the top-up at once), then it
/// closes, and the top-up screen asks the server how the payment ended.
class PaymentPageScreen extends StatefulWidget {
  const PaymentPageScreen({super.key, required this.page});

  final Uri page;

  /// How long the return page stays after it loads, for its webhook call.
  static const Duration settleFor = Duration(milliseconds: 1200);

  /// Closes anyway this long after reaching the return page (it may never finish).
  static const Duration closeAtMost = Duration(seconds: 5);

  @override
  State<PaymentPageScreen> createState() => _PaymentPageScreenState();
}

class _PaymentPageScreenState extends State<PaymentPageScreen> {
  late final WebViewController _web;
  Timer? _closer;
  bool _loading = true;
  bool _returning = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigation,
          onPageStarted: (_) => _setLoading(true),
          onPageFinished: _onPageFinished,
          onWebResourceError: (error) {
            // The return page did not load: nothing left to show; the server still
            // learns the outcome from ZainCash.
            if (_returning && error.isForMainFrame != false) {
              _close();
            } else {
              _setLoading(false);
            }
          },
        ),
      )
      ..loadRequest(widget.page);
  }

  @override
  void dispose() {
    _closer?.cancel();
    super.dispose();
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    final url = Uri.tryParse(request.url);

    if (url == null) {
      return NavigationDecision.prevent;
    }

    if (url.scheme != 'http' && url.scheme != 'https') {
      // about:blank and the like stay; a provider's own app (intent://, zaincash://)
      // opens outside.
      if (url.scheme == 'about' || url.scheme == 'data') {
        return NavigationDecision.navigate;
      }
      unawaited(_openOutside(url));

      return NavigationDecision.prevent;
    }

    if (request.isMainFrame && isPaymentReturnPage(url)) {
      _returning = true;
      _closer ??= Timer(PaymentPageScreen.closeAtMost, _close);
    }

    return NavigationDecision.navigate;
  }

  void _onPageFinished(String address) {
    _setLoading(false);
    final url = Uri.tryParse(address);

    if (_returning || (url != null && isPaymentReturnPage(url))) {
      _returning = true;
      _closer?.cancel();
      _closer = Timer(PaymentPageScreen.settleFor, _close);
    }
  }

  Future<void> _openOutside(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No app for it: the provider's page offers its own way on.
    }
  }

  void _setLoading(bool loading) {
    if (mounted && _loading != loading) {
      setState(() => _loading = loading);
    }
  }

  void _close() {
    if (_closed || !mounted) {
      return;
    }
    _closed = true;
    Navigator.of(context).pop();
  }

  /// On Android the page is a real Android view in the window (hybrid composition):
  /// drawn through a texture, as by default, it stays blank on some phones (Mali GPUs,
  /// the same trouble the map had), with or without Impeller.
  Widget _webView() {
    final platform = _web.platform;

    if (platform is AndroidWebViewController) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(controller: platform, displayWithHybridComposition: true),
      );
    }

    return WebViewWidget(controller: _web);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppScaffold(
      padded: false,
      topBar: AppTopBar(title: context.l10n.topUpZainCash, onBack: _close),
      body: Column(
        children: [
          SizedBox(
            height: 2,
            child: _loading ? LinearProgressIndicator(color: p.brandStrong, backgroundColor: p.surface2) : null,
          ),
          Expanded(child: _webView()),
        ],
      ),
    );
  }
}
