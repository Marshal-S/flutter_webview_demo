import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {"WebViewWidget": (context) => const WebViewWidget(url: "https://www.baidu.com")},
      home: Builder(
        builder: (context) {
          return Container(
            color: Colors.blue,
            child: SafeArea(
              child: Column(
                children: [
                  //注意 context 的问题，外面所以嵌套了一个 builder
                  MaterialButton(
                    onPressed: () {
                      // Navigator.of(context).push(MaterialPageRoute(
                      //     builder: (BuildContext context) => const WebViewWidget(url: "https://juejin.cn/ios")));
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => const WebViewWidget(url: "http://localhost:3000/")));
                      // Navigator.of(context).pushNamed("WebViewWidget");
                      // Navigator.of(context).pushReplacementNamed("WebViewWidget"); //替换根路由
                    },
                    child: const Text(
                      '点击进入百度',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class WebViewWidget extends StatefulWidget {
  final String url;

  const WebViewWidget({Key? key, required this.url}) : super(key: key);

  @override
  State<WebViewWidget> createState() => _WebViewWidgetState();
}

class _WebViewWidgetState extends State<WebViewWidget> {
  WebViewController? _controller;
  double progessValue = 0.1;
  String webTitle = '';

  @override
  void initState() {
    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          webTitle,
          style: const TextStyle(fontSize: 18),
        ),
        leading: Builder(builder: (context) {
          return IconButton(
            onPressed: () {
              // if (_controller != null) {
              //   _controller?.canGoBack().then((value) {
              //     if (value) {
              //       _controller?.goBack();
              //     }else {
              //       Navigator.of(context).pop();
              //     }
              //   }).catchError((err) {
              //     Navigator.of(context).pop();
              //   });
              // }else {
              //   Navigator.of(context).pop();
              // }
              //简化一下逻辑，使其更清晰
              Future<void> canGoBack() async {
                if (_controller != null && await _controller!.canGoBack()) return;
                throw Error();
              }

              canGoBack().then((value) {
                _controller?.goBack();
              }).catchError((error) {
                Navigator.of(context).pop();
              });
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
          );},
        ),
        actions: [
          Builder(builder: (context) {
            return TextButton(
              onPressed: () {
                //发送给web端消息
                _controller?.runJavascript('flutterMessage.webReceiveMessage("收到了没")');
              },
              child: const Text("发送", style: TextStyle(color: Colors.white, fontSize: 14),),
            );
          }),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            //webView
            WebView(
              //url
              initialUrl: widget.url,
              //允许js执行，默认不允许，显示静态页面
              javascriptMode: JavascriptMode.unrestricted,
              //路由侧边手势是否开启，开启后从左往右划动可以退出当前page页面
              gestureNavigationEnabled: true,
              //webview创建完成后的回调，只会回调一次
              onWebViewCreated: (WebViewController webViewController) {
                //webView创建完成
                _controller = webViewController;
              },
              //页面开始加载
              onPageStarted: (String url) {
                print('Page started loading: $url');
              },
              //页面加载完毕
              onPageFinished: (String url) async {
                print('Page finished loading: $url');
                //顺表获取导航标题，返回的是 Future
                final title = await _controller?.getTitle();
                if (title != null) {
                  setState(() {
                    webTitle = title;
                  });
                }
              },
              initialCookies: const <WebViewCookie>[
                //一般一个网页用同一组cookie，支持多组cookie
                WebViewCookie(
                  name: "token", //cooke键值
                  value: "1293172938712931798", //cookie值
                  domain: ".juejin.cn", //域名
                  //path: "/",//一般页面都是使用一个cookie，一般'/'应用到整个应用
                ),
                WebViewCookie(
                  name: "username", //cooke键值
                  value: "www.baidu.com", //cooke值
                  domain: ".juejin.cn", //域名
                  //path: "/",//一般页面都是使用一个cookie，一般'/'应用到整个应用
                ),
              ],
              //进度条刚好再开始和结束之间
              onProgress: (int progress) {
                print('WebView is loading (progress : $progress%)');
                setState(() {
                  progessValue = progress / 100.0;
                });
              },
              //路由委托(导航代理)，可以通过拦截跳转url来实现，可以跳转flutter或者交互，也可以传递参数
              navigationDelegate: (NavigationRequest request) {
                print(request.url);
                if (request.url.startsWith('https://juejin.cn/post/7155821382742310920')) {
                  print("进入了我的侧边栏文章，暂时不作处理，就标记一下");
                }
                // else if (request.url.startsWith('https://juejin.cn/post/')) {
                //   //阻止进入其他文章，就只能进入我上面一篇文章😂
                //   print('blocking navigation to $request}');
                //   return NavigationDecision.prevent;
                // }
                //其他请求正常跳转
                return NavigationDecision.navigate;
              },
              //JavascriptChannel来进行交互
              javascriptChannels: <JavascriptChannel>{
                //参数为Set，可以传入多个JavascriptChannel，根据name作为哈希值
                JavascriptChannel(
                  name: 'flutterMessage',
                  onMessageReceived: (JavascriptMessage message) {
                    print("flutter接收到了web端发送过来的flutterMessage消息${message.message}"); //js发送过来的信息
                  },
                ),
                JavascriptChannel(
                  name: 'flutterOrder',
                  onMessageReceived: (JavascriptMessage message) {
                    //js发送过来的信息，我们可以进行处理或者跳转等
                    print("flutter接收到了web端发送过来的flutterOrder消息${message.message}"); //js发送过来的信息
                    _controller?.loadUrl("https://juejin.cn/ios");
                  },
                ),
              },
            ),

            progessValue < 1 ? Positioned(
              top: 0,
              left: 0,
              right: 0,
              //滚动条，用来显示加载进度,下面是线性的，圆形的是CircularProgressIndicator
              child: LinearProgressIndicator(
                color: Colors.greenAccent,
                backgroundColor: Colors.transparent,
                value: progessValue,
              ),
            ) : Container(),
          ],
        ),
      ),
    );
  }
}
