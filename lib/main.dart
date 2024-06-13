import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;


final date = DateTime.now().toIso8601String();

final operatorMessageController =
    StateProvider.autoDispose<String>((ref) => "Aguarde...");

final qrCodeController = StateProvider.autoDispose<String>((ref) => "");

final webSocketProvider =
    Provider<WebSocketSitef>((ref) => WebSocketSitef(ref));

class WebSocketSitef {
  final Ref ref;
  late WebSocketChannel channel;
  String consoleMessage = "";

  WebSocketSitef(this.ref);

  init() async {
    channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:3000/ws/1'));

    channel.stream.listen((message) {
      Map<String, dynamic> json = {};
      print(message);

      try {
        json = jsonDecode(message);
      } catch (e) {
        print(e);
      }

      if (json.containsKey("status")) {
        final response = WebSocketResponse.fromJson(json);
        if (response.status == "console") {
          final consoleMessageControler =
              ref.read(operatorMessageController.notifier);
          consoleMessageControler.state = response.message ?? "";
          return;
        }
        if (response.status == "error") {
          print("Erro: ${response.message}");
          return;
        }
        if (response.status == "qr_code") {
          final qr =
              ref.read(qrCodeController.notifier);
          qr.state = response.message ?? "";
          return;
        }
        if (response.status == "success") {
          switch (response.tipo) {
            case 2:
              print("RETORNO TRANSAÇÃO: ${response.data}");
              finaliza();
              return;
            case 3:
              print("RETORNO FINALIZA: ${response.data}");
              return;
            case 4:
              print("RETORNO CANCELAMENTO: ${response.data}");
              return;
            case 6:
              print("RETORNO OBTEM DADOS PINPAD: ${response.data}");
              return;
            default:
              return;
          }
        }
        if (response.status == "cancelamento") {
          print(json.toString());
          print(response.message);
          return;
        }
      }
    });
  }

  void finaliza() {
    // final date = DateTime.now().toIso8601String();
    final json = {
      "tipo": 3,
      "jsonTipo": {
        "confirma": true,
        "nrCupom": 2,
        "data": DateTime.now().toIso8601String(),
      }
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }

  sendMessage() {
    final json = {
      "tipo": 2,
      "jsonTipo": {
        "formaDePagamento": 3,
        "valor": 10.0,
        "parcela": 1,
        "nrCupom": 2,
        "operador": 300,
        "data": DateTime.now().toIso8601String()
      }
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }

  sendTestData() {
    final json = {
      "tipo": 6,
      "jsonTipo": {}
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }

  cancelaOp() {
    final json = {
      "tipo": 5,
      "jsonTipo": {}
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }

  verificaPinPad() {
    final json = {
      "tipo": 1,
      "jsonTipo": {}
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }

  // {"tipo":2,"jsonTipo":{"formaDePagamento":2,"valor":10.0,"parcela":1,"nrCupom":103,"operador":361,"data":"2024-04-05T08:11:18.418643"}}
  sendCancelamento() {
    final json = {
      "tipo": 4,
      "jsonTipo": {
        //0 DEBITO - 1 CREDITO
        "tipoCancelamento": 1,
        "valor": 40.0,
        // "parcela": 1,
        // "nrCupom": 107,
        // "operador": 361,
        "data": DateTime.now().toIso8601String(),
        'autorizacao': "999050014"
      }
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }

  sendObtemDadosPinPad() {
    final json = {
      "tipo": 6,
      "jsonTipo": {
        "tipo": 1
      }
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }

  send() {
    final json = {
      "migrate_action": 0
    };
    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }
}

// late IOWebSocketChannel channel;

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void sendMessage(WidgetRef ref) async {

    final webSocket = ref.read(webSocketProvider);
    await webSocket.init();
    // webSocket.send();
    // webSocket.sendTestData();
    webSocket.verificaPinPad();
    // webSocket.sendMessage();
    // webSocket.sendCancelamento();
  }

  void cancela(WidgetRef ref) async {
    // final qr = ref.read(qrCodeController.notifier);
    // qr.state = "";
    final webSocket = ref.read(webSocketProvider);
    // await webSocket.init();
    webSocket.cancelaOp();
    // webSocket.sendCancelamento();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final message = ref.watch(operatorMessageController);
      final qr = ref.watch(qrCodeController);
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              qr.isNotEmpty
                  ? SizedBox(
                      width: 400,
                      height: 400,
                      child: QrImageView(
                        data: qr,
                        version: QrVersions.auto,
                        size: 400.0,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        gapless: true,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(
                          color: Colors.black,
                        ),
                      ),
                    )
                  : Container(),
              Text(
                message,
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => cancela(ref),
              tooltip: 'Cancela',
              child: const Icon(Icons.subdirectory_arrow_left),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              onPressed: () => sendMessage(ref),
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      );
    });
  }
}

class WebSocketResponse {
  String? status;
  int? tipo;
  String? message;
  Map<String, dynamic>? data;

  WebSocketResponse({this.status, this.tipo, this.message, this.data});

  WebSocketResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    tipo = json['tipo'];
    message = json['message'];
    data = json['data'];
  }
}

class TransacaoResponse {
  String? rede;
  String? bandeira;
  String? nSUSitef;
  String? nSUHostAutorizador;
  String? cartao;
  String? dataDoVencimento;
  String? tipoDoCartaoLido;
  String? bandeiraNFCE;
  String? gerPDV;
  String? pagamentoCdGrupo;
  String? pagamentoCdSubgrupo;
  String? pagamentoUsu;
  String? modalidadeDePagamento;
  String? comprovanteTipo;
  String? comprovanteViaCliente;
  String? comprovanteViaLoja;
  String? respostaAutorizador;
  String? identificacaoTransacao;
  String? contadorPagamentos;

  TransacaoResponse({
    this.rede,
    this.bandeira,
    this.nSUSitef,
    this.nSUHostAutorizador,
    this.cartao,
    this.dataDoVencimento,
    this.tipoDoCartaoLido,
    this.bandeiraNFCE,
    this.gerPDV,
    this.pagamentoCdGrupo,
    this.pagamentoCdSubgrupo,
    this.pagamentoUsu,
    this.modalidadeDePagamento,
    this.comprovanteTipo,
    this.comprovanteViaCliente,
    this.comprovanteViaLoja,
    this.respostaAutorizador,
    this.identificacaoTransacao,
    this.contadorPagamentos,
  });

  TransacaoResponse.fromJson(Map<String, dynamic> json) {
    rede = json['rede'];
    bandeira = json['bandeira'];
    nSUSitef = json['NSUSitef'];
    nSUHostAutorizador = json['NSUHostAutorizador'];
    cartao = json['cartao'];
    dataDoVencimento = json['dataDoVencimento'];
    tipoDoCartaoLido = json['tipoDoCartaoLido'];
    bandeiraNFCE = json['bandeiraNFCE'];
    gerPDV = json['gerPDV'];
    pagamentoCdGrupo = json['pagamentoCdGrupo'];
    pagamentoCdSubgrupo = json['pagamentoCdSubgrupo'];
    pagamentoUsu = json['pagamentoUsu'];
    modalidadeDePagamento = json['modalidadeDePagamento'];
    comprovanteTipo = json['comprovanteTipo'];
    comprovanteViaCliente = json['comprovanteViaCliente'];
    comprovanteViaLoja = json['comprovanteViaLoja'];
    respostaAutorizador = json['respostaAutorizador'];
    identificacaoTransacao = json['identificacaoTransacao'];
    contadorPagamentos = json['contadorPagamentos'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['rede'] = rede;
    data['bandeira'] = bandeira;
    data['NSUSitef'] = nSUSitef;
    data['NSUHostAutorizador'] = nSUHostAutorizador;
    data['cartao'] = cartao;
    data['dataDoVencimento'] = dataDoVencimento;
    data['tipoDoCartaoLido'] = tipoDoCartaoLido;
    data['bandeiraNFCE'] = bandeiraNFCE;
    data['gerPDV'] = gerPDV;
    data['pagamentoCdGrupo'] = pagamentoCdGrupo;
    data['pagamentoCdSubgrupo'] = pagamentoCdSubgrupo;
    data['pagamentoUsu'] = pagamentoUsu;
    data['modalidadeDePagamento'] = modalidadeDePagamento;
    data['comprovanteTipo'] = comprovanteTipo;
    data['comprovanteViaCliente'] = comprovanteViaCliente;
    data['comprovanteViaLoja'] = comprovanteViaLoja;
    data['respostaAutorizador'] = respostaAutorizador;
    data['identificacaoTransacao'] = identificacaoTransacao;
    data['contadorPagamentos'] = contadorPagamentos;
    return data;
  }

  @override
  String toString() {
    return 'TransacaoResponse{rede: $rede, bandeira: $bandeira, nSUSitef: $nSUSitef, nSUHostAutorizador: $nSUHostAutorizador, cartao: $cartao, dataDoVencimento: $dataDoVencimento, tipoDoCartaoLido: $tipoDoCartaoLido, bandeiraNFCE: $bandeiraNFCE, gerPDV: $gerPDV, pagamentoCdGrupo: $pagamentoCdGrupo, pagamentoCdSubgrupo: $pagamentoCdSubgrupo, pagamentoUsu: $pagamentoUsu, modalidadeDePagamento: $modalidadeDePagamento, comprovanteTipo: $comprovanteTipo, comprovanteViaCliente: $comprovanteViaCliente, comprovanteViaLoja: $comprovanteViaLoja, respostaAutorizador: $respostaAutorizador, identificacaoTransacao: $identificacaoTransacao, contadorPagamentos: $contadorPagamentos}';
  }
}

class MigrateRequest {
  final String migratiosnPath;

  MigrateRequest({required this.migratiosnPath});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['migrations_path'] = migratiosnPath;
    return data;
  }
}
