import 'package:get/get.dart';
import 'package:gologapp/data/datasource/local/transport_sql_service.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/data/model/transport.dart';
import 'package:gologapp/data/repository/route_repository.dart';

class RouteController extends GetxController {
  final TransportSqlService _transportSqlService =
      Get.find<TransportSqlService>();
  final RouteRepository _routeRepository = Get.find<RouteRepository>();

  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var transportList = <Transport>[].obs;
  Transport? selectedTransport;
  Delivery? selectedDelivery;

  @override
  void onInit() {
    super.onInit();
    fetchTransports();
  }

  Future<void> fetchTransports() async {
    try {
      isLoading(true);
      var data = await _routeRepository.getTransports();
      transportList.assignAll(data);
    } catch (e) {
      print('Erro ao buscar transportes: $e');
      errorMessage.value = 'Erro ao buscar transportes: $e';
    } finally {
      isLoading(false);
    }
  }

  void goToDetails(Transport transport) {
    selectedTransport = transport;
    Get.toNamed('/route_details');
  }

  void goToDeliveryRoute(Delivery delivery) {
    selectedDelivery = delivery;
    Get.toNamed('/delivery_route');
  }

  void clearError(){
    errorMessage.value = '';
  }
}
