import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  Barcode? result; // Cambiamos a Barcode? para permitir nulo
  QRViewController?
      controller; // Cambiamos a QRViewController? para permitir nulo

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Scanner'),
      ),
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
                  ? Text(
                      'Barcode Type: ${result!.format}   Data: ${result!.code}')
                  : Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
      // Llamada a la API para validar el QR
      final isValid = await _validateQRCode(result!.code!);
      _showValidationDialog(isValid);
    });
  }

  Future<bool> _validateQRCode(String code) async {
    final response = await http.get(
      Uri.parse('https://ufidelitas.ac.cr/wp-json/nf-submissions/v1/form/114'),
      headers: {
        'NF-REST-Key':
            'a2d3f2da9fc9413786ec10b8a3914bab17871fff814f7d91003437d398b22d9',
        'Accept': 'application/json',
        'Cookie':
            'AWSALB=TuN6b4jLAMOWc8ThDV64QmqJ+P+ujWjBSJfJpea8AhAEoUQH54jU...'
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Aquí puedes implementar la lógica específica para validar el código QR.
      for (var submission in data['submissions']) {
        if (submission['_field_977'] == code) {
          return true;
        }
      }
    }
    return false;
  }

  void _showValidationDialog(bool isValid) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isValid ? 'Valid' : 'Invalid'),
          content: Text(isValid
              ? 'The QR code is valid.'
              : 'The QR code is invalid or already used.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
