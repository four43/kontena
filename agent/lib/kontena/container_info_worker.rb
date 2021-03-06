require 'docker'
require_relative 'logging'

module Kontena
  class ContainerInfoWorker
    include Kontena::Logging

    LOG_NAME = 'ContainerInfoWorker'
    attr_reader :queue, :node_info

    ##
    # @param [Queue] queue
    def initialize(queue)
      @queue = queue

      Pubsub.subscribe('container:event') do |event|
        self.on_container_event(event) rescue nil
      end
    end

    ##
    # Start work
    #
    def start!
      Thread.new {
        loop do
          logger.info(LOG_NAME) { 'fetching containers information' }
          Docker::Container.all(all: true).each do |container|
            self.publish_info(container)
          end
          sleep 60
        end
      }
    end

    ##
    # @param [Docker::Event] event
    def on_container_event(event)
      return if event.status == 'destroy'

      container = Docker::Container.get(event.id)
      self.publish_info(container) if container
    rescue Docker::Error::NotFoundError
      self.publish_destroy_event(event)
    rescue => exc
      logger.error(LOG_NAME) { "on_container_event: #{exc.message}" }
    end

    ##
    # @param [Docker::Container]
    def publish_info(container)
      data = container.json
      event = {
        event: 'container:info',
        data: {
          node: self.node_info['ID'],
          container: data
        }
      }
      logger.debug(LOG_NAME) { event }
      self.queue << event
    rescue => exc
      logger.error(LOG_NAME) { "publish_info: #{exc.message}" }
    end

    ##
    # @param [Docker::Event] event
    def publish_destroy_event(event)
      data = {
          event: 'container:event',
          data: {
              id: event.id,
              status: 'destroy',
              from: event.from,
              time: event.time
          }
      }
      self.queue << data
    end

    # @return [Hash]
    def node_info
      @node_info ||= Docker.info
    end
  end
end
