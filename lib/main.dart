import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gologapp/data/datasource/local/user_sql_service.dart';
import 'package:gologapp/data/datasource/remote/api_service.dart';
import 'package:gologapp/data/datasource/remote/auth_api_service.dart';
import 'package:gologapp/data/repository/auth_repository.dart';
import 'package:gologapp/presentation/screen/login/login_screen.dart';
import 'package:gologapp/presentation/screen/route/route_screen.dart';
import 'package:gologapp/presentation/screen/delivery_route/delivery_route_screen.dart';
import 'package:gologapp/presentation/screen/route_details/route_details_screen.dart';
import 'package:gologapp/util/styles.dart';
import 'package:gologapp/data/datasource/local/sql_service.dart';

// Ajuste o path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  await Get.putAsync(() async => SqlService());
  await Get.putAsync(() async => Get.find<SqlService>().initDB());
  await Get.putAsync(() async => UserSqlService());
  Get.put(ApiService());
  Get.put(AuthApi(Get.find<ApiService>()));
  Get.put(AuthRepository(Get.find<AuthApi>()));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoLog',
      theme: ThemeData(scaffoldBackgroundColor: Styles.COLOR_BACKGROUND),
      initialRoute: '/login',
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
          name: '/route_datails',
          page: () => const RouteDetailsScreen(),
          transition: Transition.fadeIn,
        ),
      ],
    );
  }
}
