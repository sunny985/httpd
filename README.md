A mirror for tinyhttpd
测试CGI时需要本机安装PERL，同时安装perl-cgi

### Prepare 
Compile for Linux
```
 To compile for Linux:
  1) Comment out the #include <pthread.h> line.
  2) Comment out the line that defines the variable newthread.
  3) Comment out the two lines that run pthread_create().
  4) Uncomment the line that runs accept_request().
  5) Remove -lsocket from the Makefile.
```

<p>&nbsp; &nbsp; &nbsp;每个函数的作用：</p>
<p>&nbsp; &nbsp; &nbsp;accept_request: &nbsp;处理从套接字上监听到的一个 HTTP 请求，在这里可以很大一部分地体现服务器处理请求流程。</p>
<p>&nbsp; &nbsp; &nbsp;bad_request: 返回给客户端这是个错误请求，HTTP 状态吗 400 BAD REQUEST.</p>
<p>&nbsp; &nbsp; &nbsp;cat: 读取服务器上某个文件写到 socket 套接字。</p>
<p>&nbsp; &nbsp; &nbsp;cannot_execute: 主要处理发生在执行 cgi 程序时出现的错误。</p>
<p>&nbsp; &nbsp; &nbsp;error_die: 把错误信息写到 perror 并退出。</p>
<p>&nbsp; &nbsp; &nbsp;execute_cgi: 运行 cgi 程序的处理，也是个主要函数。</p>
<p>&nbsp; &nbsp; &nbsp;get_line: 读取套接字的一行，把回车换行等情况都统一为换行符结束。</p>
<p>&nbsp; &nbsp; &nbsp;headers: 把 HTTP 响应的头部写到套接字。</p>
<p>&nbsp; &nbsp; &nbsp;not_found: 主要处理找不到请求的文件时的情况。</p>
<p>&nbsp; &nbsp; &nbsp;sever_file: 调用 cat 把服务器文件返回给浏览器。</p>
<p>&nbsp; &nbsp; &nbsp;startup: 初始化 httpd 服务，包括建立套接字，绑定端口，进行监听等。</p>
<p>&nbsp; &nbsp; &nbsp;unimplemented: 返回给浏览器表明收到的 HTTP 请求所用的 method 不被支持。</p>
<p><br>
</p>
<p>&nbsp; &nbsp; &nbsp;建议源码阅读顺序： main -&gt; startup -&gt; accept_request -&gt; execute_cgi, 通晓主要工作流程后再仔细把每个函数的源码看一看。</p>
<p><br>
</p>
<h4>&nbsp; &nbsp; &nbsp;工作流程</h4>
<p>&nbsp; &nbsp; &nbsp;（1） 服务器启动，在指定端口或随机选取端口绑定 httpd 服务。</p>
<p>&nbsp; &nbsp; &nbsp;（2）收到一个 HTTP 请求时（其实就是 listen 的端口 accpet 的时候），派生一个线程运行 accept_request 函数。</p>
<p>&nbsp; &nbsp; &nbsp;（3）取出 HTTP 请求中的 method (GET 或 POST) 和 url,。对于 GET 方法，如果有携带参数，则 query_string 指针指向 url 中 ？ 后面的 GET 参数。</p>
<p>&nbsp; &nbsp; &nbsp;（4） &#26684;式化 url 到 path 数组，表示浏览器请求的服务器文件路径，在 tinyhttpd 中服务器文件是在 htdocs 文件夹下。当 url 以 / 结尾，或 url 是个目录，则默认在 path 中加上 index.html，表示访问主页。</p>
<p>&nbsp; &nbsp; &nbsp;（5）如果文件路径合法，对于无参数的 GET 请求，直接输出服务器文件到浏览器，即用 HTTP &#26684;式写到套接字上，跳到（10）。其他情况（带参数 GET，POST 方式，url 为可执行文件），则调用 excute_cgi 函数执行 cgi 脚本。</p>
<p>&nbsp; &nbsp; （6）读取整个 HTTP 请求并丢弃，如果是 POST 则找出 Content-Length. 把 HTTP 200 &nbsp;状态码写到套接字。</p>
<p>&nbsp; &nbsp; （7） 建立两个管道，cgi_input 和 cgi_output, 并 fork 一个进程。</p>
<p>&nbsp; &nbsp; （8） 在子进程中，把 STDOUT 重定向到 cgi_outputt 的写入端，把 STDIN 重定向到 cgi_input 的读取端，关闭 cgi_input 的写入端 和 cgi_output 的读取端，设置 request_method 的环境变量，GET 的话设置 query_string 的环境变量，POST 的话设置 content_length 的环境变量，这些环境变量都是为了给 cgi 脚本调用，接着用 execl 运行 cgi 程序。</p>
<p>&nbsp; &nbsp; （9） 在父进程中，关闭 cgi_input 的读取端 和 cgi_output 的写入端，如果 POST 的话，把 POST 数据写入 cgi_input，已被重定向到 STDIN，读取 cgi_output 的管道输出到客户端，该管道输入是 STDOUT。接着关闭所有管道，等待子进程结束。这一部分比较乱，见下图说明：</p>
<p><br>
</p>
<p><img src="http://img.blog.csdn.net/20141226173222750?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvamNqYzkxOA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center" width="484" height="222" alt=""><br>
</p>
<p>图 1 &nbsp; &nbsp;管道初始状态</p>
<p><br>
</p>
<p><img src="http://img.blog.csdn.net/20141226161119981?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvamNqYzkxOA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center" alt=""></p>
<p> 图 2 &nbsp;管道最终状态&nbsp;</p>
<p><br>
</p>
<p>&nbsp; &nbsp; （10） 关闭与浏览器的连接，完成了一次 HTTP 请求与回应，因为 HTTP 是无连接的。</p>
<p><br>
</p>
流程：
1.客户端发起访问请求
  在浏览器上访问http//192.168.9.104:4000
2.服务端接受客户请求
  接受的请求信息如下
  GET / HTTP/1.1
  Host: 172.16.2.44:4000 
  Connection: keep-alive
  Upgrade-Insecure-Requests: 1
  User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.86 Safari/537.36
  Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8
  Accept-Encoding: gzip, deflate
  Accept-Language: zh-CN,zh;q=0.8
3.服务端响应客户请求
  解析第一条请求信息，表示客户端要获取httpd服务器根目录下的内容，检查请求能够满足，将请求结果返回客户端，返回头如下：
  HTTP/1.0 200 OK\r\n
  Server: jdbhttpd/0.1.0\r\n
  Content-Type: text/html\r\n
  \r\n
  然后将htdocs/index.html中的内容返回给客户端
4.客户端接受到index.html中的内容并在网页上显示里面的内容
5.客户端的用户在网页中输入颜色(如:red),点击提交
6.服务端收到如下信息：
  POST /color.cgi HTTP/1.1
  Host: 172.16.2.44:4000
  Connection: keep-alive
  Content-Length: 9
  Cache-Control: max-age=0
  Origin: http://172.16.2.44:4000
  Upgrade-Insecure-Requests: 1
  User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.86 Safari/537.36
  Content-Type: application/x-www-form-urlencoded
  Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8
  Referer: http://172.16.2.44:4000/
  Accept-Encoding: gzip, deflate
  Accept-Language: zh-CN,zh;q=0.8
7.服务器端解析第一条请求，POST表示要在表示的资源后面添加新的内容
8.接下来，服务器会fork一个子进程，用于执行color.cgi,父进程接受需要添加的新内容作为color.cgi的参数，
  然后将color.cgi的执行结果返回给客户端

管道文件描述符：
    fd[0]用于读管道，fd[1]用于写管道
管道读写规则：
    管道创建时默认是阻塞模式
    阻塞模式：
	    当没有数据可读时，read会被阻塞，即进程暂停运行，直到有进程向管道写新的数据 
		当缓冲区被写满时，write会被阻塞，直到有进程将数据读走
	非阻塞模式：
	    当没有数据可读时，read返回-1，error = EAGAIN
		当缓冲区被写满时，write返回-1，error = EAGAIN
	当所有写端描述符被关闭时，read返回0
    当所有读端描述符被关闭时，write会产生信号SIGPIPE   
    当要写入的数据量小于PIPE_BUF时，写操作会立即完成，	