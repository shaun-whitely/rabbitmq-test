require 'bunny'

def with_rabbitmq(&block)
  connection = Bunny.new
  connection.start

  begin
    channel = connection.create_channel

    block.call(connection, channel)
  rescue Interrupt => _
    connection.close
  end
end

def create_start_move_queue(channel)
  channel.queue('start_move_requests')
end
