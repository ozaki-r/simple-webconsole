require 'pty'
require 'em-websocket'

EventMachine.run {
  @channel = EM::Channel.new
  @channel2 = EM::Channel.new

  cmd = 'bash'
  PTY.getpty(cmd) do |ptyin, ptyout|
    EM.defer do
      while true do
        @channel.push(ptyin.read(1))
      end
    end
    sid = @channel2.subscribe { |msg| ptyout.write(msg) }
  end

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8888) do |ws|
    ws.onopen {
      sid = @channel.subscribe { |msg| ws.send msg }
      #@channel.push "#{sid} connected!"

      ws.onmessage { |msg|
        @channel2.push(msg)
      }

      ws.onclose {
        @channel.unsubscribe(sid)
      }
    }
  end
}
