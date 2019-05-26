import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http_server/http_server.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

HttpServer connectionServer;
Directory appDir;
String ipAddress;

var certFile = '${appDir.path}/certificate.pem';
var keyFile = '${appDir.path}/key.pem';

void main() async {
  appDir = await getApplicationDocumentsDirectory();
  ipAddress = InternetAddress.loopbackIPv4.address;

  if (FileSystemEntity.typeSync(certFile) == FileSystemEntityType.notFound) {
    String certContents = await rootBundle.loadString("assets/certificate.pem");
    new File(certFile).writeAsString(certContents);
  }

  if (FileSystemEntity.typeSync(keyFile) == FileSystemEntityType.notFound) {
    String keyContents = await rootBundle.loadString("assets/key.pem");
    new File(keyFile).writeAsString(keyContents);
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Server Test',
        home: HomePage(),
        routes: <String, WidgetBuilder>{
          '/webview': (BuildContext context) => MyWebView(),
        });
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: FlatButton(
            onPressed: () async {
//              SecurityContext context = new SecurityContext();

//              context.useCertificateChain(certFile);
//              context.usePrivateKey(keyFile);

              VirtualDirectory appVDirectory = new VirtualDirectory(appDir.path)
                ..allowDirectoryListing = true;

              connectionServer = await HttpServer.bind('localhost', 4404);

              await for (HttpRequest request in connectionServer) {
                print('------------${request.method}------------');
                var content = await request.transform(Utf8Decoder()).join();
                print(content);
                if (request.method == 'PUT') {
                  print('------------PUT method was recorded-------------');
                } else if (request.method == 'OPTIONS') {
                  request.response.headers.set(HttpHeaders.acceptHeader,
                      'GET,HEAD,POST,OPTIONS,CONNECT,PUT,DAV,dav');
                  request.response.headers.set('x-api-access-type', 'file');
                  request.response.headers.set('dav', 'tw5/put');
                } else {
                  appVDirectory.serveRequest(request);
                }
              }
            },
            child: Text('Start Server'),
            color: Colors.deepPurpleAccent,
          ),
        ),
        Expanded(
          child: FlatButton(
            onPressed: () async {
//              Navigator.push(
//                  context,
//                  MaterialPageRoute(
//                      builder: (BuildContext context) => MyWebView()));
              await launch('http://localhost:4404/index.html');
            },
            child: Text('Open Webview'),
            color: Colors.white,
          ),
        ),
        Expanded(
          child: FlatButton(
            onPressed: () {
              connectionServer.close();
            },
            child: Text('Stop Server'),
            color: Colors.blueGrey,
          ),
        ),
        Expanded(
          child: FlatButton(
            onPressed: () async {
              var _downloadData = StringBuffer();
              var fileSave = new File('${appDir.path}/index.html');
              HttpClient client = new HttpClient();
              client
                  .getUrl(Uri.parse('https://tiddlywiki.com/empty.html'))
                  .then((HttpClientRequest request) {
                return request.close();
              }).then((HttpClientResponse response) {
                response.transform(utf8.decoder).listen(
                    (contents) => _downloadData.write(contents), onDone: () {
                  fileSave.writeAsString(_downloadData.toString().replaceAll(
                      new RegExp(r'\/\^https\?:\/\.test\(location\.protocol\)'),
                      'true'));
                });
              });
            },
            child: Text('Download TiddlyWiki'),
            color: Colors.green,
          ),
        ),
      ],
    ));
  }
}

class MyWebView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      url: 'http://localhost:4404',
      appBar: new AppBar(title: new Text('Server Test')),
      allowFileURLs: true,
    );
  }
}
