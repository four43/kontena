require 'yaml'
require_relative 'common'

module Kontena::Cli::Apps
  class StopCommand < Clamp::Command
    include Kontena::Cli::Common
    include Common

    parameter "[SERVICE] ...", "Services to stop"

    attr_reader :services, :service_prefix

    def execute
      @services = load_services_from_yml
      if services.size > 0
        Dir.chdir(File.dirname(filename))
        stop_services(services)
      elsif !service_list.empty?
        puts "No such service: #{service_list.join(', ')}".colorize(:red)
      end

    end

    def stop_services(services)
      services.each do |service_name, opts|
        if service_exists?(service_name)
          puts "stopping #{prefixed_name(service_name)}"
          stop_service(token, prefixed_name(service_name))
        else
          puts "No such service: #{service_name}".colorize(:red)
        end
      end
    end
  end
end