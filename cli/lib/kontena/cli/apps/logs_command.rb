require 'yaml'
require_relative 'common'

module Kontena::Cli::Apps
  class LogsCommand < Clamp::Command
    include Kontena::Cli::Common
    include Common

    option ['-f', '--file'], 'FILE', 'Specify an alternate Kontena compose file', attribute_name: :filename, default: 'kontena.yml'
    option ['-p', '--project-name'], 'NAME', 'Specify an alternate project name (default: directory name)'

    parameter "[SERVICE] ...", "Services to start"

    attr_reader :services, :service_prefix

    def execute
      @services = load_services_from_yml
      if services.size > 0
        Dir.chdir(File.dirname(filename))
        show_logs(services)
      elsif !service_list.empty?
        puts "No such service: #{service_list.join(', ')}".colorize(:red)
      end

    end

    def show_logs(services)
      logs = []
      services.each do |service_name, opts|
        service = get_service(token, prefixed_name(service_name)) rescue false
        result = client(token).get("services/#{service['id']}/container_logs")
        logs = logs + result['logs']
      end
      logs.sort!{|x,y| DateTime.parse(x['created_at']) <=> DateTime.parse(y['created_at'])}
      logs.each do |log|
        color = color_for_container(log['name'])
        puts "#{log['name'].colorize(color)} | #{log['data']}"
      end
    end

    def color_for_container(container_id)
      color_maps[container_id] = colors.shift unless color_maps[container_id]
      color_maps[container_id].to_sym
    end

    def color_maps
      @color_maps ||= {}
    end

    def colors
      if(@colors.nil? || @colors.size == 0)
        @colors = [:green, :magenta, :yellow, :cyan, :red,
                   :light_green, :light_yellow, :ligh_magenta, :light_cyan, :light_red]
      end
      @colors
    end
  end
end
