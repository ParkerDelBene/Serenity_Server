import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';


void main() async {
  final wsURL = Uri.parse("ws://192.168.0.38:12345");
  final webSocket = WebSocketChannel.connect(wsURL);
  
  
  webSocket.stream.listen((message){
    print(message);
  });

  webSocket.sink.add("Hello");

  stdin.listen((message){
    webSocket.sink.add(message);

  });
  
}