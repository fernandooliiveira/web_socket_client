import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


final date = DateTime.now().toIso8601String();

final operatorMessageController = StateProvider.autoDispose<String>((ref) => "Aguarde...");


final webSocketProvider =
    Provider<WebSocketSitef>((ref) => WebSocketSitef(ref));

class WebSocketSitef {
  final Ref ref;
  late WebSocketChannel channel;
  String consoleMessage = "";

  WebSocketSitef(this.ref);

  init() async {
    channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:3000/ws/4'));

    channel.stream.listen((message) {
      Map<String, dynamic> json = {};

      try {
        json = jsonDecode(message);
      } catch (e) {
        print(e);
      }

      if (json.containsKey("status")) {
        final response = WebSocketResponse.fromJson(json);
        if (response.status == "console") {
          final consoleMessageControler = ref.read(operatorMessageController.notifier);
          consoleMessageControler.state = response.message ?? "";
        }
        if (response.status == "success") {
          print(response.data.toString());
          finaliza();
        }
      }
    });
  }

  sendMessage() {
    final json = {
      "tipo": 2,
      "jsonTipo": {
        "formaDePagamento": 2,
        "valor": 10.0,
        "parcela": 1,
        "nrCupom": 2,
        "operador": 1,
        "data": date
      }
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }

  void finaliza() {
    // final date = DateTime.now().toIso8601String();
    final json = {
      "tipo": 3,
      "jsonTipo": {"confirma": true, "nrCupom": 2, "data": date}
    };

    final jsonEncoded = jsonEncode(json);
    channel.sink.add(jsonEncoded);
  }
}

// late IOWebSocketChannel channel;

void main() {
  // channel = IOWebSocketChannel.connect('ws://127.0.0.1:3000/ws/4');
  // channel.stream.listen((message) {
  //   // if(message is String && message.contains("CONSOLE")) {
  //   //   int inicio = message.indexOf('[');
  //   //   int fim = message.lastIndexOf(']');
  //   //   if (inicio != -1 && fim != -1 && fim > inicio) {
  //   //     String console = message.substring(inicio + 1, fim);
  //   //     print(console);
  //   //   }
  //   //   return;
  //   // }
  //   if (message is Map<String, dynamic>) {
  //     if (message.containsKey("status")) {
  //       final response = WebSocketResponse.fromJson(message);
  //       if (response.status == "console") {
  //         print(response.message);
  //       }
  //       if (response.status == "success") {
  //         // final funcResponse = TransacaoResponse.fromJson(response.data ?? {});
  //         finaliza();
  //
  //
  //       }
  //     }
  //   }
  //   print('$message');
  // });
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
    // final channel = IOWebSocketChannel.connect('ws://127.0.0.1:3000/ws/4');
    //
    // channel.stream.listen((message) {
    //   print('Received: $message');
    // });
    // final date = DateTime.now().toIso8601String();
    final webSocket = ref.read(webSocketProvider);
    await webSocket.init();
    webSocket.sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final message = ref.watch(operatorMessageController);
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => sendMessage(ref),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
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
