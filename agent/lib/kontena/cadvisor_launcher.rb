require 'docker'

module Kontena
  class CadvisorLauncher
    include Kontena::Logging

    CADVISOR_VERSION = ENV['CADVISOR_VERSION'] || '0.16.0'
    CADVISOR_IMAGE = ENV['CADVISOR_IMAGE'] || 'google/cadvisor'
    LOG_NAME = 'CadvisorLauncher'

    def initialize
      logger.info(LOG_NAME) { 'initialized' }
    end

    def start!
      Thread.new {
        begin
          start_cadvisor
        rescue => exc
          puts exc.message
          puts exc.backtrace.join("\n")
        end
      }
    end

    def start_cadvisor
      image = "#{CADVISOR_IMAGE}:#{CADVISOR_VERSION}"

      pull_image(image)
      create_container(image)
    end

    # @param [String] image
    def pull_image(image)
      return if Docker::Image.exist?(image)
      logger.info(LOG_NAME) { "pulling image #{image}" }
      Docker::Image.create('fromImage' => image)
      sleep 1 until Docker::Image.exist?(image)
    end

    # @param [String] image
    def create_container(image)
      container = Docker::Container.get('kontena-cadvisor') rescue nil
      container.remove(force: true) if container

      container = Docker::Container.create(
        'name' => 'kontena-cadvisor',
        'Image' => image,
        'Cmd' => ['--logtostderr=true'],
        'Volumes' => {
          '/rootfs' => {},
          '/var/run' => {},
          '/sys' => {},
          '/var/lib/docker' => {}
        },
        'ExposedPorts' => {'8080/tcp' => {}},
        'HostConfig' => {
          'Binds' => [
            '/:/rootfs:ro',
            '/var/run:/var/run',
            '/sys:/sys:ro',
            '/var/lib/docker:/var/lib/docker:ro'
          ],
          'PortBindings' => {
            '8080/tcp' => [
              {'HostIp' => '127.0.0.1', 'HostPort' => '8080'}
            ]
          },
          'RestartPolicy' => {'Name' => 'always'}
        }
      )
      container.start
    end
  end
end
