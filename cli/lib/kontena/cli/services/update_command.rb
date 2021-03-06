require_relative 'services_helper'

module Kontena::Cli::Services
  class UpdateCommand < Clamp::Command
    include Kontena::Cli::Common
    include ServicesHelper

    parameter "NAME", "Service name"

    option "--image", "IMAGE", "Docker image to use"
    option ["-p", "--ports"], "PORTS", "Publish a service's port to the host", multivalued: true
    option ["-e", "--env"], "ENV", "Set environment variables", multivalued: true
    option ["-a", "--affinity"], "AFFINITY", "Set service affinity", multivalued: true
    option ["-c", "--cpu-shares"], "CPU_SHARES", "CPU shares (relative weight)"
    option ["-m", "--memory"], "MEMORY", "Memory limit (format: <number><optional unit>, where unit = b, k, m or g)"
    option ["--memory-swap"], "MEMORY_SWAP", "Total memory usage (memory + swap), set \'-1\' to disable swap (format: <number><optional unit>, where unit = b, k, m or g)"
    option "--cmd", "CMD", "Command to execute"
    option "--instances", "INSTANCES", "How many instances should be deployed"
    option ["-u", "--user"], "USER", "Username who executes first process inside container"
    option "--cap-add", "CAP_ADD", "Add capabitilies", multivalued: true
    option "--cap-drop", "CAP_DROP", "Drop capabitilies", multivalued: true

    def execute
      require_api_url
      token = require_token

      data = parse_service_data_from_options
      update_service(token, name, data)
    end

    ##
    # parse given options to hash
    # @return [Hash]
    def parse_service_data_from_options
      data = {}
      data[:ports] = parse_ports(ports_list) if ports_list
      data[:memory] = parse_memory(memory) if memory
      data[:memory_swap] = parse_memory(memory_swap) if memory_swap
      data[:cpu_shares] = cpu_shares if cpu_shares
      data[:affinity] = affinity_list if affinity_list
      data[:env] = env_list if env_list
      data[:container_count] = instances if instances
      data[:cmd] = cmd.split(" ") if cmd
      data[:user] = user if user
      data[:image] = image if image
      data[:cap_add] = cap_add_list if cap_add_list
      data[:cap_drop] = cap_drop_list if cap_drop_list
      data
    end
  end
end
