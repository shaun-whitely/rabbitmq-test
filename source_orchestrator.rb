require 'bunny'
require 'securerandom'
require_relative './common'

jobs = {}

with_rabbitmq do |_conn, channel|
  start_move_queue = create_start_move_queue(channel)
  start_move_callback_queue = channel.queue('', exclusive: true)

  puts 'Sending StartMove'
  pk = SecureRandom.uuid

  jobs[pk] = { status: :start_move, queue_name: nil }

  channel.default_exchange.publish(
    'StartMove',
    routing_key: start_move_queue.name,
    reply_to: start_move_callback_queue.name,
    correlation_id: pk
  )

  start_move_callback_queue.subscribe(block: true) do |_delivery_info, properties, body|
    puts "Received #{body}"
    jobs[properties.correlation_id][:status] = body.to_sym
    jobs[properties.correlation_id][:queue_name] = properties.reply_to

    queue = jobs[pk][:queue_name]
    puts "Sending GoCritical"
    channel.default_exchange.publish(
      "GoCritical #{pk}",
      routing_key: queue
    )

    puts "Sending Finalize"
    channel.default_exchange.publish(
      "Finalize #{pk}",
      routing_key: queue
    )
  end


end
