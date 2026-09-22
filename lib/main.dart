import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth/auth_state.dart';
import 'auth/session.dart';
import 'notifications/notification_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await NotificationService.instance.init();
  final session = Session();
  final auth = AuthState(session);
  await auth.bootstrap();
  runApp(SwaEqApp(auth: auth));
}

class SwaEqApp extends StatefulWidget {
  const SwaEqApp({super.key, required this.auth});
  final AuthState auth;

  @override
  State<SwaEqApp> createState() => _SwaEqAppState();
}

class _SwaEqAppState extends State<SwaEqApp> {
  late final _router = createRouter(widget.auth);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.auth,
      child: Consumer<AuthState>(
        builder: (context, auth, _) {
          if (!auth.ready) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.brand600),
                ),
              ),
            );
          }
          return MaterialApp.router(
            title: 'SwaEQ Care',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(elderly: true),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
