import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionController extends GetxController {
  var isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        isConnected.value = false;
        Get.snackbar('Conexiune pierdută', 'Nu ești conectat la internet.',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        isConnected.value = true;
        Get.snackbar('Conexiune restabilită', 'Ești din nou online.',
            snackPosition: SnackPosition.BOTTOM);
      }
    });
  }
}
