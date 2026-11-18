import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:golog/data/datasource/local/coordinate_sql_service.dart';
import 'package:golog/data/datasource/local/credential_store.dart';
import 'package:golog/data/datasource/local/delivery_sql_service.dart';
import 'package:golog/data/datasource/local/occurrence_sql_service.dart';
import 'package:golog/data/datasource/local/sql_service.dart';
import 'package:golog/data/datasource/local/transport_sql_service.dart';
import 'package:golog/data/datasource/local/user_sql_service.dart';
import 'package:golog/data/datasource/remote/api_service.dart';
import 'package:golog/data/datasource/remote/auth_api_service.dart';
import 'package:golog/data/repository/auth_repository.dart';
import 'package:golog/data/repository/route_repository.dart';
import 'package:golog/data/repository/sync_repository.dart';
import 'package:golog/presentation/controller/location_controller.dart';
import 'package:golog/presentation/controller/login_controller.dart';
import 'package:golog/presentation/controller/occurrence_controller.dart';
import 'package:golog/presentation/controller/route_controller.dart';
import 'package:golog/presentation/controller/sync_controller.dart';
import 'package:golog/presentation/screen/delivery_route/delivery_route_screen.dart';
import 'package:golog/presentation/screen/login/login_screen.dart';
import 'package:golog/presentation/screen/route/route_screen.dart';
import 'package:golog/presentation/screen/route_details/route_details_screen.dart';
import 'package:golog/presentation/screen/splash/splash_view.dart';
import 'package:golog/util/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App em retrato; só a tela de assinatura gira para paisagem
  // (ver OccurrenceScreen).
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  await GetStorage.init();
  await _registerDependencies();
  runApp(const MyApp());
}

/// Monta o grafo de dependências. Tudo é criado aqui, em ordem, e
/// recebido pelo construtor — nenhuma classe busca dependências sozinha.
Future<void> _registerDependencies() async {
  final credentials = Get.put(CredentialStore(), permanent: true);
  final sql = await Get.putAsync(
    () => SqlService(credentials).init(),
    permanent: true,
  );
  final db = sql.db;

  final userSql = Get.put(UserSqlService(db), permanent: true);
  final coordinateSql = Get.put(CoordinateSqlService(db), permanent: true);
  final occurrenceSql = Get.put(OccurrenceSqlService(db), permanent: true);
  final deliverySql = Get.put(DeliverySqlService(db), permanent: true);
  final transportSql = Get.put(
    TransportSqlService(db, deliverySql),
    permanent: true,
  );

  final api = Get.put(ApiService(credentials, userSql), permanent: true);
  final routeRepository = Get.put(
    RouteRepository(
      api,
      transportSql,
      deliverySql,
      sql,
      occurrenceSql,
      userSql,
    ),
    permanent: true,
  );
  final authRepository = Get.put(
    AuthRepository(AuthApi(api), userSql, credentials),
    permanent: true,
  );
  final syncRepository = SyncRepository(
    api,
    credentials,
    occurrenceSql,
    coordinateSql,
  );

  final syncController = Get.put(
    SyncController(syncRepository),
    permanent: true,
  );
  final routeController = Get.put(
    RouteController(
      routeRepository,
      occurrenceSql,
      userSql,
      deliverySql,
      sql,
      GetStorage(),
      syncController,
    ),
    permanent: true,
  );
  final locationController = Get.put(
    LocationController(routeController, coordinateSql),
    permanent: true,
  );
  Get.put(
    LoginController(
      authRepository,
      routeRepository,
      routeController,
      locationController,
      syncController,
    ),
    permanent: true,
  );
  Get.put(
    OccurrenceController(
      routeController,
      occurrenceSql,
      userSql,
      deliverySql,
      syncController,
    ),
    permanent: true,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Criado uma única vez: em build() seria refeito a cada rebuild.
  late final Future<String> _initialRoute = Get.find<LoginController>()
      .initialRoute();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _initialRoute,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const SplashView(),
          );
        }
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GoLog',
          theme: AppTheme.light,
          initialRoute: snapshot.data ?? '/login',
          getPages: [
            GetPage(
              name: '/login',
              page: () => const LoginScreen(),
              transition: Transition.fadeIn,
            ),
            GetPage(
              name: '/route_screen',
              page: () => const RouteScreen(),
              transition: Transition.fadeIn,
            ),
            GetPage(
              name: '/delivery_route',
              page: () => const DeliveryRouteScreen(),
              transition: Transition.fadeIn,
            ),
            GetPage(
              name: '/route_details',
              page: () => const RouteDetailsScreen(),
              transition: Transition.fadeIn,
            ),
          ],
        );
      },
    );
  }
}
