import 'dart:io';

import 'serenity_server.dart';

void main() async{
  print('Server Starting');
  SerenityServer server = SerenityServer(await HttpServer.bind('0.0.0.0', 12345));

  await server.initialize();
  print('Server Initialized');

  stdin.listen((input){
    serverCommandLine(String.fromCharCodes(input));
  });
}

void serverCommandLine(String input){

  stdout.write(input);
}