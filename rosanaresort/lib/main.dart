import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rosanaresort/feature/splash_screen/cubit/aplsh_cubit.dart';

import 'config/routes/routes.dart';

import 'config/routes/routes_manager.dart';
import 'core/api/api_consumer.dart';
import 'core/api/deep_link_cubit.dart';
import 'core/api/deep_link_services.dart';
import 'core/api/dio_consumer.dart';
import 'core/cache/cache_consumer_impl.dart';
import 'core/dependencies/app_dependencies.dart';
import 'core/theme/transelation/l10n.dart';
import 'core/theme/transelation/localization_cubit.dart';
import 'core/theme/transelation/localization_loader.dart';
import 'feature/auth/log_in/cubit/login_cubit.dart';
import 'feature/auth/otp/cubit/otp_cubit.dart';
import 'feature/auth/services/auth_services.dart';
import 'feature/passes/data/datasources/passes_remote_datasource.dart';
import 'feature/passes/data/repositories/passes_repository.dart';
import 'feature/passes/presentation/cubit/passes_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  await dotenv.load(fileName: '.env');
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final cache = await EncryptedCacheConsumerImpl.init();
  final baseUrl = dotenv.env['BASE_URL'] ?? '';
  final api = DioConsumer(dio: Dio(), baseUrl: baseUrl,cache: cache);
  // await NotificationService.instance.initialize(
  //   repository: createNotificationRepository(api: api, cache: cache),
  // );
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFFF29D00),
    systemNavigationBarIconBrightness: Brightness.dark, // dark icons on white bg
  ));
  RoutesManager.navigatorKey = GlobalKey<NavigatorState>();
  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const LocalizationLoader(),
      child: Ehub(api: api, cache: cache),
    ),
  );
}

class Ehub extends StatefulWidget {
  final ApiConsumer api;
  final EncryptedCacheConsumerImpl cache;

  const Ehub({
    super.key,
    required this.api,
    required this.cache,
  });

  @override
  State<Ehub> createState() => _EhubState();
}

class _EhubState extends State<Ehub> {
  late final DeepLinkService _deepLinkService;
  late final DeepLinkCubit _deepLinkCubit;
  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService();
    _deepLinkCubit = DeepLinkCubit(_deepLinkService);

    // ✅ Wait for MaterialApp + navigatorKey to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkCubit.init();
    });

  }
  @override
  void dispose() {
    _deepLinkCubit.close();
    _deepLinkService.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      api: widget.api,
      cache: widget.cache,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),

        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => LoginCubit(
                authService: AuthServices(widget.api),
              ),
            ),
            BlocProvider.value(value: _deepLinkCubit),
            BlocProvider(
              create: (_) => OtpCubit(
                authServices:AuthServices(widget.api),
              ),
            ),
            BlocProvider(
              create: (_) => PassesCubit(repository: PassesRepository(dataSource: PassesRemoteDataSource(widget.api),), storage: widget.cache),

            ),
            BlocProvider(create: (_)=> LocalizationCubit(widget.cache)),
            BlocProvider(
              create: (_) => SplashCubit(
              ),
            ),

          ],

          child:BlocListener<DeepLinkCubit, DeepLinkState>(
            listenWhen: (previous, current) => current.pendingResult != null,
            listener: (context, state) {
              context.read<DeepLinkCubit>().handleIfExists(context);
            },
            child: MaterialApp(
              navigatorKey: RoutesManager.navigatorKey,
              locale: context.locale,
              localizationsDelegates: [
                S.delegate, // Your auto-generated L10n delegates
                ...context.localizationDelegates, // Add easy_localization delegates
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              debugShowCheckedModeBanner: false,
              initialRoute: Routes.splashScreen,
              onGenerateRoute: RoutesManager.generateRoute,
            ),
          ),
        ),
      ),
    );
  }
}
