NOTE: this is forked from https://github.com/argos83/ritm
# Ruby In The Middle (HTTP/HTTPS interception proxy)

<img src="docs/ritm.png" width="500">

**Ruby in the middle** (RITM) is an HTTP/HTTPS interception proxy with
on-the-fly certificate generation and signing, which leaves the user
with the full power of the Ruby language to intercept and even modify
requests and responses as she pleases.

## Installation

`gem install ritm`

## Basic usage

1. **Write your interception handlers**

  ```ruby
  require 'ritm'
  
  # A single answer for all your google searches
  Ritm.on_request do |req|
    if req.request_uri.host.start_with? 'www.google.'
      new_query_string = req.request_uri.query.gsub(/(?<=^q=|&q=)(((?!&|$).)*)(?=&|$)/, 'RubyInTheMiddle')
      req.request_uri.query = new_query_string
    end
  end
  
  my_picture = File.read('i_am_famous.jpg')
  
  # Replaces every picture on the web with my pretty face
  Ritm.on_response do |_req, res|
    if res.header['content-type'] && res.header['content-type'].start_with?('image/')
      res.header['content-type'] = 'image/jpeg'
      res.body = my_picture
    end
  end
  ```
2. **Start the proxy server**

  ```ruby
  Ritm.start
   
  puts 'Hit enter to finish'
  gets
  
  Ritm.shutdown
  ```
3. **Configure your browser**

  Or whatever HTTP client you want to intercept traffic from, to connect
  to the proxy in `localhost:8080`
4. **Browse the web!**

  For the examples above, search anything in google and also visit your
  favorite newspaper website.

## Trusting self-signed certificates generated by RITM

With the previous example your client might have encountered issues when
trying to access HTTPS resources. In some cases you can add an exception
to your browser (or instruct your http client not to verify
certificates) but 
[in some other cases](https://tools.ietf.org/html/rfc6797) you won't be
able to add exceptions. The reason for this is that in order to decrypt
and to be able to modify SSL traffic, RITM will have to be the one doing
the SSL negotiatiation with the client (using its own set of
certificates) and then it will establish a separate SSL session towards
the server. I.e.:

```
Client <--- SSL session ---> RITM <--- SSL session ---> Server
```

For every different server's hostname your client tries to communicate
with, RITM will generate a certificate on the fly and sign it with a
pre-configured Certificate Authority (CA). So, in order to be able to
establish a secure connection you will need to configure your client
(e.g. browser) to trust RITM's CA.

For security reasons, every time you start RITM's proxy with the default
settings it will generate a new internal Certificate Authority. To use
your own CA instead (so it can be loaded and trusted by your browser)
perform the following steps:

1. **Generate a Certificate Authority PEM and Private Key files**

  You can use
  [OpenSSL](https://www.openssl.org/docs/manmaster/apps/ca.html) or RITM
  to generate these two files. With OpenSSL:

  ```
  openssl req -new -nodes -x509 -days 365 -extensions v3_ca -keyout insecure_ca.key -out insecure_ca.crt
  ```

  Or with RITM:

  ```ruby
  require 'ritm/certs/ca'
  
  ca = Ritm::CA.create common_name: 'InsecureCA'
  
  File.write('insecure_ca.crt', ca.pem)
  File.write('insecure_ca.key', ca.private_key.to_s)
  ```
2. **Repeat step 2 from the previous example, this time indicating what
CA should be used to sign certificates**

  ```ruby
  Ritm.configure do
    ssl_reverse_proxy.ca[:pem] = 'path/to/insecure_ca.crt'
    ssl_reverse_proxy.ca[:key] = 'path/to/insecure_ca.key'
  end
  
  Ritm.start
  
  puts 'Hit enter to finish'
  gets
  
  Ritm.shutdown
  ```
3. **Trust the CA certificate into your browser or client**

  I'll leave it to you to figure out how this is done in your browser or
  client.
4. **Surf the web!**
5. When you are done **Remove the CA from your trusted authorities!** 

  Or take really good care of the CA private key since anyone in
  possession of that key will be capable of decrypting all your traffic!
  Also notice that when using the proxy every server will be
  automatically trusted even if the end server certificate is not valid.

## Running multiple sessions with different settings

In the examples above we've been using the default global session. If
you don't like using a statically configured global session, or you want
to have multiple sessions coexisting (e.g. multiple proxies listening on
different ports and using different interception handlers) you can
create different session instances this way:


```ruby
session = Ritm::Session.new

# Now you can use the same methods but on the session instance

session.configure { proxy[:bind_port] = 7777 }
session.on_request { |req| ...do something here ... }

another_session = Ritm::Session.new
another_session.configure { proxy[:bind_port] = 8888 }
another_session.on_request { |req| ...do something else ... }

session.start
another_session.start

puts 'Hit enter to finish'
gets

session.shutdown
another_session.shutdown
```

## License

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
