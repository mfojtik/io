+++
title = "Ruby websockets on Openshift"
date = "2013-08-08T14:44:55+01:00"
+++

Few months ago, Openshift [announced](https://www.openshift.com/blogs/paas-websockets)
support for websockets on their site, with nice examples how to use then using
the Node.JS. Since using websockets in Node.JS is easy because the Node.JS web
server supports them, the situlation in Ruby is a bit more complex.

The Ruby cartridge by default runs Apache with Passenger, which makes
implementing websockets a bit tricky. Fortunately, Openshift permits us to
replace the default web server with a different server that has support for this
new cutting-edge technology. This is a quick tutorial how to make things
rolling using [Sinatra](http://www.sinatrarb.com/) and [Faye](https://github.com/faye/faye-websocket-ruby)
and deployed under [Puma](http://puma.io/) web server, a modern concurrent web
server build for Ruby apps.

First step is to create a new ruby application:

```
$ rhc app create websockets ruby-1.9
$ cd websockets/
```

Now is the time to prepare the dependencies in `Gemfile`:

```ruby
source 'https://rubygems.org'
gem 'puma'
gem 'faye-websocket', :require => 'faye/websocket'
gem 'eventmachine'
gem 'sinatra', :require => 'sinatra/base'
```

Next step is to run `bundle` and wait until all dependencies are installed.
After that, we can start modifying the `config.ru`. The very first step is to
remove everything from that file and replace it with this content:

```ruby
Bundler.require(:default)
load './app.rb'

Faye::WebSocket.load_adapter('puma')

# The default OpenShift websockets port is '8000' where in your local
# environment you will use default puma port which is 9292
#
ENV['WEBSOCKET_PORT'] = ENV['OPENSHIFT_RUBY_PORT'].nil? ? '9292' : '8000'

# This is needed to have Puma bind on the right IP address and port:
#
run Rack::URLMap.new("/time" => TimeApp, "/" => WebSocketApp)
```

The `config.ru` is the file used for launching your application. By default, the
config.ru is picked up by Passenger in Apache, we just replaced that so instead
of Passenger your application will be handled by Puma.

Now let's write the application itself. Open the `app.rb` file and put the following
content there:

```ruby
# This is the WebSocket routing application:
#
WebSocketApp = lambda do |env|

  if Faye::WebSocket.websocket?(env)

    ws = Faye::WebSocket.new(env)

    # When client connects through WebSocket, then start sending the current
    # time in the Thread every 1s
    ws.on :open do |e|
      @clock = Thread.new { loop { ws.send(Time.now.to_s); sleep(1) } }
    end

    # Kill the thread when client disconnects and remove the websocket
    ws.on :close do |e|
      Thread.kill(@clock)
      ws = nil
    end

    ws.rack_response

  else
    # Redirect the client to the Sinatra application, if the request
    # is not WebSocket
    [301, { 'Location' => '/time'}, []]
  end
end

# Puma require the 'log' method for the server request logging:
#
def WebSocketApp.log(message); $stdout.puts message; end

# This is very basic Sinatra app that will just render the HTML with WebSocket
# javascript handling:
#
class TimeApp < Sinatra::Base

  get '/' do
    erb :index
  end

end
```

Now we need to write the HTML page with a JavaScript piece that will open the
web socket and actually read some data through it. You can grab the content of
the file [here](https://github.com/mfojtik/openshift-ruby-websockets-demo/blob/master/views/index.erb) and
just save it to `views/index.erb`.

The important piece is:

```javascript
socket = new Socket('ws://' + location.hostname + ':' + '<%=ENV['WEBSOCKET_PORT']%>' + '/')
```

This will connect the browser to the websocket app and use the 'right' port.

So we are almost finished here, but we need to tell OpenShift to replace the
default web server with our Puma. To do so, we need to create the
`.openshift/action_hooks/post_start_ruby-1.9` file and put following content in:

```bash
#!/bin/bash
echo "Replacing the default Passenger server with Puma"

pushd ${OPENSHIFT_REPO_DIR} > /dev/null
${HOME}/ruby/bin/control stop &> /dev/null
set -e

PUMA_PID_FILE="${OPENSHIFT_DATA_DIR}puma.pid"
PUMA_BIND_URL="tcp://${OPENSHIFT_RUBY_IP}:${OPENSHIFT_RUBY_PORT}"
PUMA_OPTS="-d --pidfile ${PUMA_PID_FILE} -e production --bind '${PUMA_BIND_URL}'"

bundle exec "puma $PUMA_OPTS"
exit 0
```

Now make it executable with `chmod +x .openshift/action_hooks/post_start_ruby-1.9`.
So this will replace the Passenger server, but we also want to handle the
application restarts and make the Puma restart working as well. For that we
need to create the `.openshift/action_hooks/deploy` file with the following
content:

```bash
#!/bin/bash

if [ -f "${OPENSHIFT_DATA_DIR}puma.pid" ]; then
  echo "Stopping Puma..."
  PUMA_PID=$(cat "${OPENSHIFT_DATA_DIR}puma.pid")
  ps -p $PUMA_PID &> /dev/null
  [ "$?" == 0 ] && kill $PUMA_PID
  rm "${OPENSHIFT_DATA_DIR}puma.pid" &> /dev/null
fi

```

*Note: I sux in writing Bash scripts, so this could be probably written
       better ;-)*


And now is the time to test out the application we created:

```
$ git add -A && git commit -m 'Initial commit.'
$ git push
# ... snip ...
remote: Replacing the default Passenger server with Puma
remote: Puma starting in single mode...
remote: * Version 2.4.1, codename: Crunchy Munchy Lunchy
remote: * Min threads: 0, max threads: 16
remote: * Environment: production
remote: * Listening on tcp://127.9.4.1:8080
remote: * Daemonizing...
# ... snip ...
```

Now open the browser and navigate to your application URL. You should be
immediately redirected to '/time' URL and see the current time which updates
every second. I know this is a pretty stupid app and the time could be told by
just using JavaScript, but this is a PoC tutorial, right? :-)

The full sources can be found in this Github [repository](https://github.com/mfojtik/openshift-ruby-websockets-demo).
Also, I have live demo running here: [websockets-mfojtik.rhcloud.com/time](http://websockets-mfojtik.rhcloud.com/time)
