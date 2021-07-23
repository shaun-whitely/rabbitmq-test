require 'bunny'
require_relative './common'

with_rabbitmq do |_conn, channel|
  start_move_queue = create_start_move_queue(channel)
  my_queue = channel.queue('', exclusive: true)

  start_move_queue.subscribe(block: true) do |_delivery_info, properties, body|
    puts "Received StartMove request: #{body}"

    channel.default_exchange.publish(
      'bulk',
      routing_key: properties.reply_to,
      correlation_id: properties.correlation_id,
      reply_to: my_queue.name
    )

    my_queue.subscribe(block: true) do |_delivery_info, _properties, body|
      puts "Received: #{body}"
    end
  end
end
