class Hiera
  module Backend
    class Consul_yaml_backend
      def initialize
        require 'net/http'
        require 'net/https'
        require 'json'
        @config = Config[:consul]

        if @config[:host] && @config[:port]
          @consul = Net::HTTP.new(@config[:host], @config[:port])
        else
          raise "[hiera-consul]: Missing minimum configuration, please check hiera.yaml"
        end

        @consul.read_timeout = @config[:http_read_timeout] || 10
        @consul.open_timeout = @config[:http_connect_timeout] || 10
        @cache = {}

        if @config[:use_ssl]
          @consul.use_ssl = true

          @consul.verify_mode = if @config[:ssl_verify] == false
                                  OpenSSL::SSL::VERIFY_NONE
                                else
                                  OpenSSL::SSL::VERIFY_PEER
                                end

          if @config[:ssl_cert]
            store = OpenSSL::X509::Store.new
            store.add_cert(OpenSSL::X509::Certificate.new(File.read(@config[:ssl_ca_cert])))

            @consul.cert_store = store
            @consul.key = OpenSSL::PKey::RSA.new(File.read(@config[:ssl_key]))
            @consul.cert = OpenSSL::X509::Certificate.new(File.read(@config[:ssl_cert]))
          end
        else
          @consul.use_ssl = false
        end
      end

      def lookup(key, scope, order_override, resolution_type, context)
        answer = nil
        found  = false

        Backend.datasources(scope, order_override) do |source|
          yaml_data = wrapquery("/v1/kv/configuration/#{source}")

          data = {}
          data = YAML.load(yaml_data) if yaml_data

          next if data.empty?
          next unless data.include?(key)
          found = true

          # Extra logging that we found the key. This can be outputted
          # multiple times if the resolution type is array or hash but that
          # should be expected as the logging will then tell the user ALL the
          # places where the key is found.
          Hiera.debug("Found #{key} in #{source}")

          # for array resolution we just append to the array whatever
          # we find, we then goes onto the next file and keep adding to
          # the array
          #
          # for priority searches we break after the first found data item
          new_answer = Backend.parse_answer(data[key], scope, {}, context)
          case resolution_type.is_a?(Hash) ? :hash : resolution_type
          when :array
            raise Exception, "Hiera type mismatch for key '#{key}': expected Array and got #{new_answer.class}" unless new_answer.is_a?(Array) || new_answer.is_a?(String)
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch for key '#{key}': expected Hash and got #{new_answer.class}" unless new_answer.is_a? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer, answer, resolution_type)
          else
            answer = new_answer
            break
          end
        end

        throw :no_such_key unless found
        answer
      end

      def parse_result(res)
        require 'base64'
        answer = nil
        if res == "null"
          Hiera.debug("[hiera-consul]: Jumped as consul null is not valid")
          return answer
        end
        # Consul always returns an array
        res_array = JSON.parse(res)
        # See if we are a k/v return or a catalog return
        if !res_array.empty?
          if res_array.first.include? 'Value'
            return answer if res_array.first['Value'].nil?

            answer = Base64.decode64(res_array.first['Value'])
          else
            answer = res_array
          end
        else
          Hiera.debug("[hiera-consul]: Jumped as array empty")
        end
        answer
      end

      def token(path)
        # Token is passed only when querying kv store
        if @config[:token] && path =~ %r{^\/v\d\/kv\/}
          return "?token=#{@config[:token]}"
        else
          return nil
        end
      end

      def wrapquery(path)
        httpreq = Net::HTTP::Get.new("#{path}#{token(path)}")
        answer = nil

        begin
          result = @consul.request(httpreq)
        rescue Exception => e
          Hiera.debug("[hiera-consul]: Could not connect to Consul")
          raise Exception, e.message unless @config[:failure] == 'graceful'
          return answer
        end

        unless result.is_a?(Net::HTTPSuccess)
          Hiera.debug("[hiera-consul]: HTTP response code was #{result.code}")
          return answer
        end

        Hiera.debug("[hiera-consul]: Answer was #{result.body}")
        answer = parse_result(result.body)

        answer
      end
    end
  end
end
