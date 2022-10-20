import { useEffect, useState } from 'react';
import './App.css';

function App() {
  const [message, setMessage] = useState('')

  useEffect(() => {
    window.flutterMessage.webReceiveMessage = (message) => {
      setMessage(message + message + message + message + message + message + message + message + message + message + message)
    }
    return () => {
      delete window.flutterMessage.webReceiveMessage
    }
  }, [])

  return (
    <div className="App">
      <div onClick={() => {
        window.flutterMessage?.postMessage("发送了FlutterMessage消息给flutter");
      }}>点击发送FlutterMessage消息</div>
      <div onClick={() => {
        window.flutterOrder?.postMessage("发送了FlutterOrder消息给flutter");
      }}>点击发送FlutterOrder消息</div>
      <div>接收到flutte传递过来的message：{message}</div>
    </div>
  );
}

export default App;
