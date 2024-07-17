import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QRViewExample(),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  List<Map<String, dynamic>> userDataList = [];

  @override
  void initState() {
    super.initState();
    _getAllUserData(); // Carga los datos al iniciar la app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text('QR Code: ${result!.code}')
                  : Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
      bool isValid = await _validateQRCode(scanData.code!);
      if (isValid) {
        _showDialog('Validación exitosa', 'El código QR es válido.');
      } else {
        _showDialog('Validación fallida',
            'El código QR no es válido o ya ha sido escaneado.');
      }
    });
  }

  Future<bool> _validateQRCode(String code) async {
    try {
      if (userDataList.isEmpty) {
        print('Cargando datos de usuario...');
        await _getAllUserData();
      }
      print('Usuarios cargados: ${userDataList.length}');
      bool found = userDataList.any((user) {
        print('Comparando ${user['_field_2253']} con $code');
        return user['_field_2253'].toString() == code;
      });
      if (found) {
        print('Código QR válido y no previamente escaneado.');
      }
      print('Resultado de la validación: $found');
      return found;
    } catch (e) {
      print('Error al validar el QR: $e');
      return false;
    }
  }

// Remove the duplicate declaration of userDataList
  Future<void> _getAllUserData() async {
    const url = 'https://ufidelitas.ac.cr/wp-json/nf-submissions/v1/form/114';
    try {
      // Agrega el encabezado NF-REST-Key a tu solicitud
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'NF-REST-Key':
              'a2d3f2da9fc9413766ce10b6a3914bab178711ff8144f7d91003437d398b22d9',
        },
      );
      final data = json.decode(response.body);
      if (data is Map) {
        if (data.containsKey('submissions') && data['submissions'] is List) {
          userDataList = List<Map<String, dynamic>>.from(data['submissions']);
        } else {
          userDataList = [];
        }
      } else {
        userDataList = [];
      }
      print('Datos de usuario cargados: ${userDataList.length}');
    } catch (e) {
      print('Error al obtener datos de usuario: $e');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
