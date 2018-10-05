require 'resolv'

# monkey-patching the Port class in the uru environment

module Serverspec::Type
	class Port < Base
	  def protocols
      %w(udp tcp tcp6 udp6)
    end

    def options
      @options ||= {}
    end

    def protocol_matcher(protocol)
      protocol = protocol.to_s.downcase
      if protocols.include?(protocol)
        options[:protocol] = protocol
      else
        raise ArgumentError.new("`be_listening` matcher doesn't support #{protocol}")
      end
    end

    def local_address_matcher(local_address)
      if valid_ip_address?(local_address)
        options[:local_address] = local_address
      else
        raise ArgumentError.new("`be_listening` matcher requires valid IPv4 or IPv6 address")
      end
    end

    def listening?(protocol, local_address)
      protocol_matcher(protocol) if protocol
      local_address_matcher(local_address) if local_address
      @runner.check_port_is_listening(@name, options)
    end

   def listening_with_retry?( max_retry, default_delay )
    start_time = Time.now
    while (Time.now - start_time) < max_retry * default_delay
      begin
        return true if @runner.check_port_is_listening(@name, options)
      rescue  => e
        STDERR.puts e.message
      end
      sleep default_delay
    end
    false
  end

  def valid_ip_address?(ip_address)
      !!(ip_address =~ Resolv::IPv4::Regex) || !!(ip_address =~ Resolv::IPv6::Regex)
    end
  end
end
