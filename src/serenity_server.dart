import 'dart:collection';
import 'dart:convert';
import 'dart:io';


import 'serenity_config.dart';

class SerenityServer {
  SerenityServer(this.server);
  HttpServer server;
  String errorString = "";
  List<WebSocket> textClients = [];
  HashMap<String, List<WebSocket>> voiceChannels = HashMap();
  SerenityConfig config = SerenityConfig('NUll', [], [], false, 0);

  Future<bool> initialize() async{

    bool configCheck = await readConfig();
    
    if(!configCheck){
      return false;
    }

    /*
      Listen Function checks the query type and pushes the 
      request to the correct function, or drops it.
    */
    server.listen((HttpRequest request) async {
      /*
        Get the type of request,

        Text types are the initial that handle all incoming text
        Voice connects to a specific channel.
      */
      String? type = request.uri.queryParameters['type'];

      switch(type){
        case 'text':
          clientTextConnect(request);
          break;
        case 'voice':
          clientVoiceConnect(request);
          break;
        default:
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.reasonPhrase = 'Invalid Request Type';
          request.response.flush();
          request.response.close();
          break;
      }
      
    },
    onDone: () {
      
    },
    onError: (e){
      print(e.toString());
    }
    );

    return true;
  }

  /*
    Name: readConfig

    Date Last Updated: 7/17/25

    Last Updater: Parker DelBene

    Function: reads the server.config file and initializes the SerenityConfig variable
  */
  Future<bool> readConfig() async{
    Directory configDirectory = Directory('./config');
    bool configExists = await configDirectory.exists();

    /*
      If the config directory does not exist, create the directory,
      then create the config File, and then populate the config file
      with the default values.
    */
    if(!configExists){
      configDirectory = await configDirectory.create();
      File configFile = File('${configDirectory.path}/server.config');
      configFile = await configFile.create();
      await configFile.writeAsString(jsonEncode(config.defaultData));
    }


    /*
      Read the File as a string, parse the json, and load the config into
      the config variable.
    */
    File configFile = File('${configDirectory.uri}server.config');
    String configString = await configFile.readAsString();
    
    
    /*
      Wrap in try catch because some people may incorrectly format 
      their server.config
    */
    try{
      var jsonConfig = jsonDecode(configString);
      config = SerenityConfig(jsonConfig[0]['serverName'], List<String>.from(jsonConfig[0]['textChannels']), List<String>.from(jsonConfig[0]['voiceChannels']), jsonConfig[0]['saveContent'], jsonConfig[0]['port']);
    }
    catch(e){
      print(e);
      print('Error in Config File');
      return false;
    }
    
    
    return true;
  }

  /*
    Name: clientVoiceConnect

    Date Last Updated: 7/7/25

    Last Updater: Parker DelBene
    
    Function: Handles finding the correct voice channel and connecting
  */
  void clientVoiceConnect(HttpRequest request){

      String? channelName = request.uri.queryParameters['channelName'];

      /*
        If it does not contain the channel name, return 403 Invalid Channel
      */
      if(!voiceChannels.containsKey(channelName)){
        request.response.statusCode = HttpStatus.forbidden;
        request.response.reasonPhrase = 'Invalid Channel';
        request.response.close();
        
        return;
      }

      /*
        Add the websocket to the correct voicechannel 
      */
      WebSocketTransformer.upgrade(request).then((webSocket){

        voiceChannels[channelName]?.add(webSocket);

        webSocket.listen((data){
          writeVoiceData(webSocket, voiceChannels[channelName]!, data);
        },
        onDone: () {
          voiceChannels[channelName]?.remove(webSocket);
        });
      });
  }

  /*
    Name: writeVoiceData

    Date Last Updated: 7/17/25

    Last Updater: Parker DelBene

    Function: This function is called by the .listen
      function on the websockets. It replicates the data to 
      the rest of the clients in the voice Channel.

  */
  void writeVoiceData(WebSocket sender, List<WebSocket> voiceChannel, dynamic message){
    for (WebSocket client in voiceChannel){
      if(client != sender){
        client.add(message);
      } 
    }
  }
  /*
    Name: clientTextConnect

    Date Last Updated: 7/17/25

    Last Updater: Parker DelBene
    
    Function: Handles the initial text connection and handshake
  */
  void clientTextConnect(HttpRequest request){
    WebSocketTransformer.upgrade(request).then((webSocket){

        
        textClients.add(webSocket);
        webSocket.add(jsonEncode(config.toMap()));
        /*
          Replicate the data to the rest of the clients
        */
        webSocket.listen((message){
          writeTextData(webSocket, message);                
        },

        onDone: () {
          textClients.remove(webSocket);
        },);

      });
  }
  /*
    Name: writeTextData

    Date Last Updated: 7/17/25

    Last Updater: Parker DelBene

    Function: This function is called by the .listen
      function on the websockets. It replicates the data to 
      the rest of the clients on the server.
  */
  void writeTextData(WebSocket sender, dynamic message){
    for (WebSocket client in textClients){
      if(client != sender){
        client.add(message);
      } 
    }
  }
}