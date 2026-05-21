import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gologapp/data/datasource/local/coordinate_sql_service.dart';
import 'package:gologapp/data/datasource/local/delivery_sql_service.dart';
import 'package:gologapp/data/datasource/local/transport_sql_service.dart';
import 'package:gologapp/data/datasource/local/ocurrence_sql_service.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/datasource/remote/api_service.dart';
import 'package:gologapp/data/datasource/remote/auth_api_service.dart';
import 'package:gologapp/data/repository/auth_repository.dart';
import 'package:gologapp/presentation/controller/location_controller.dart';
import 'package:gologapp/presentation/controller/login_controller.dart';
import 'package:gologapp/presentation/screen/login/login_screen.dart';
import 'package:gologapp/presentation/screen/route/route_screen.dart';
import 'package:gologapp/presentation/screen/delivery_route/delivery_route_screen.dart';
import 'package:gologapp/presentation/screen/route_details/route_details_screen.dart';
import 'package:gologapp/util/styles.dart';
import 'package:gologapp/data/datasource/local/sql_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  await Get.putAsync(() async => SqlService());
  await Get.putAsync(() async => Get.find<SqlService>().initDB());
  await Get.putAsync(() async => UserSqlService());
  await Get.putAsync(() async => CoordinateSqlService());
  await Get.putAsync(() async => OccurrenceSqlService());
  await Get.putAsync(() async => DeliverySqlService());
  await Get.putAsync(() async => TransportSqlService());

  Get.put(ApiService());
  Get.put(AuthApi(Get.find<ApiService>()));
  Get.put(AuthRepository(Get.find<AuthApi>()));
  Get.put(LocationController(), permanent: true);
  Get.put(LoginController(Get.find<AuthRepository>(), Get.find<UserSqlService>()), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();
    return FutureBuilder<String>(
      future: loginController.tryKeepConnected(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Styles.COLOR_BLACKBLUE), 
              ),
            ),
          );
        }
        final initialRoute = snapshot.data ?? '/login';

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GoLog',
          theme: ThemeData(scaffoldBackgroundColor: Styles.COLOR_BACKGROUND),
          initialRoute: initialRoute, 
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
              page: () => DeliveryRouteScreen(),
              transition: Transition.fadeIn,
            ),
            GetPage(
              name: '/route_details',
              page: () => RouteDetailsScreen(),
              transition: Transition.fadeIn,
            ),
          ],
        );
      },
    );
  }
}