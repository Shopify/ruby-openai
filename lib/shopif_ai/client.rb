# rubocop:disable Metrics/ClassLength
module ShopifAi
  class Client
    include ShopifAi::HTTP

    SENSITIVE_ATTRIBUTES = %i[@access_token @admin_token @organization_id @extra_headers].freeze
    CONFIG_KEYS = %i[access_token admin_token api_type api_version extra_headers
                     log_errors organization_id request_timeout uri_base].freeze
    attr_reader(*CONFIG_KEYS, :faraday_middleware)
    attr_writer :access_token

    def initialize(config = {}, &faraday_middleware)
      CONFIG_KEYS.each do |key|
        # Set instance variables like api_type & access_token. Fall back to global config
        # if not present.
        instance_variable_set(
          "@#{key}",
          config[key].nil? ? ShopifAi.configuration.send(key) : config[key]
        )
      end
      @faraday_middleware = faraday_middleware
    end

    def chat(parameters: {}, extra_headers: {})
      json_post(path: "/chat/completions", parameters: parameters, extra_headers: extra_headers)
    end

    def embeddings(parameters: {}, extra_headers: {})
      json_post(path: "/embeddings", parameters: parameters, extra_headers: extra_headers)
    end

    def completions(parameters: {}, extra_headers: {})
      json_post(path: "/completions", parameters: parameters, extra_headers: extra_headers)
    end

    def audio
      @audio ||= ShopifAi::Audio.new(client: self)
    end

    def files
      @files ||= ShopifAi::Files.new(client: self)
    end

    def finetunes
      @finetunes ||= ShopifAi::Finetunes.new(client: self)
    end

    def images
      @images ||= ShopifAi::Images.new(client: self)
    end

    def models
      @models ||= ShopifAi::Models.new(client: self)
    end

    def responses
      @responses ||= ShopifAi::Responses.new(client: self)
    end

    def assistants
      @assistants ||= ShopifAi::Assistants.new(client: self)
    end

    def threads
      @threads ||= ShopifAi::Threads.new(client: self)
    end

    def messages
      @messages ||= ShopifAi::Messages.new(client: self)
    end

    def runs
      @runs ||= ShopifAi::Runs.new(client: self)
    end

    def run_steps
      @run_steps ||= ShopifAi::RunSteps.new(client: self)
    end

    def vector_stores
      @vector_stores ||= ShopifAi::VectorStores.new(client: self)
    end

    def vector_store_files
      @vector_store_files ||= ShopifAi::VectorStoreFiles.new(client: self)
    end

    def vector_store_file_batches
      @vector_store_file_batches ||= ShopifAi::VectorStoreFileBatches.new(client: self)
    end

    def batches
      @batches ||= ShopifAi::Batches.new(client: self)
    end

    def realtime
      @realtime ||= ShopifAi::Realtime.new(client: self)
    end

    def moderations(parameters: {}, extra_headers: {})
      json_post(path: "/moderations", parameters: parameters, extra_headers: extra_headers)
    end

    def usage
      @usage ||= ShopifAi::Usage.new(client: self)
    end

    def conversations
      @conversations ||= ShopifAi::Conversations.new(client: self)
    end

    def azure?
      @api_type&.to_sym == :azure
    end

    def admin
      unless admin_token
        e = "You must set an OPENAI_ADMIN_TOKEN= to use administrative endpoints:\n\n  https://platform.openai.com/settings/organization/admin-keys"
        raise AuthenticationError, e
      end

      dup.tap do |client|
        client.access_token = client.admin_token
      end
    end

    def beta(apis)
      dup.tap do |client|
        client.add_headers("OpenAI-Beta": apis.map { |k, v| "#{k}=#{v}" }.join(";"))
      end
    end

    def inspect
      vars = instance_variables.map do |var|
        value = instance_variable_get(var)

        SENSITIVE_ATTRIBUTES.include?(var) ? "#{var}=[REDACTED]" : "#{var}=#{value.inspect}"
      end

      "#<#{self.class}:#{object_id} #{vars.join(', ')}>"
    end
  end
end
# rubocop:enable Metrics/ClassLength
