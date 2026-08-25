RSpec.describe ShopifAi::Client do
  context "with clients with different access tokens" do
    before do
      ShopifAi.configure do |config|
        config.organization_id = "organization_id0"
        config.extra_headers = { "test" => "X-Default" }
      end
    end

    after do
      # Necessary otherwise the dummy organization_id bleeds into other specs
      # that actually hit the API and causes them to fail.
      ShopifAi.configure do |config|
        config.organization_id = nil
        config.extra_headers = {}
      end
    end

    let!(:c0) { ShopifAi::Client.new }
    let!(:c1) do
      ShopifAi::Client.new(
        api_type: "azure",
        access_token: "access_token1",
        organization_id: "organization_id1",
        request_timeout: 60,
        uri_base: "https://oai.hconeai.com/",
        extra_headers: { "test" => "X-Test" }
      )
    end
    let!(:c2) do
      ShopifAi::Client.new(
        access_token: "access_token2",
        organization_id: nil,
        request_timeout: 1,
        uri_base: "https://example.com/"
      )
    end

    it "does not confuse the clients" do
      expect(c0.azure?).to eq(false)
      expect(c0.access_token).to eq(ENV.fetch("OPENAI_ACCESS_TOKEN", "dummy-token"))
      expect(c0.organization_id).to eq("organization_id0")
      expect(c0.request_timeout).to eq(ShopifAi::Configuration::DEFAULT_REQUEST_TIMEOUT)
      expect(c0.uri_base).to eq(ShopifAi::Configuration::DEFAULT_URI_BASE)
      expect(c0.send(:headers).values).to include("Bearer #{c0.access_token}")
      expect(c0.send(:headers).values).to include(c0.organization_id)
      expect(c0.send(:conn).options.timeout).to eq(ShopifAi::Configuration::DEFAULT_REQUEST_TIMEOUT)
      expect(c0.send(:uri, path: "")).to include(ShopifAi::Configuration::DEFAULT_URI_BASE)
      expect(c0.send(:headers).values).to include("X-Default")
      expect(c0.send(:headers).values).not_to include("X-Test")

      expect(c1.azure?).to eq(true)
      expect(c1.access_token).to eq("access_token1")
      expect(c1.organization_id).to eq("organization_id1")
      expect(c1.request_timeout).to eq(60)
      expect(c1.uri_base).to eq("https://oai.hconeai.com/")
      expect(c1.send(:headers).values).to include(c1.access_token)
      expect(c1.send(:conn).options.timeout).to eq(60)
      expect(c1.send(:uri, path: "")).to include("https://oai.hconeai.com/")
      expect(c1.send(:headers).values).not_to include("X-Default")
      expect(c1.send(:headers).values).to include("X-Test")

      expect(c2.azure?).to eq(false)
      expect(c2.access_token).to eq("access_token2")
      expect(c2.organization_id).to eq("organization_id0") # Fall back to default.
      expect(c2.request_timeout).to eq(1)
      expect(c2.uri_base).to eq("https://example.com/")
      expect(c2.send(:headers).values).to include("Bearer #{c2.access_token}")
      expect(c2.send(:headers).values).to include(c2.organization_id)
      expect(c2.send(:conn).options.timeout).to eq(1)
      expect(c2.send(:uri, path: "")).to include("https://example.com/")
      expect(c2.send(:headers).values).to include("X-Default")
      expect(c2.send(:headers).values).not_to include("X-Test")
    end

    context "hitting other classes" do
      after do
        c0.files.list
        c1.files.list
        c2.files.list

        c0.finetunes.list
        c1.finetunes.list
        c2.finetunes.list

        c0.images.generate
        c1.images.generate
        c2.images.generate

        c0.models.list
        c1.models.list
        c2.models.list
      end

      it "does not confuse the clients" do
        expect(c0).to receive(:get).with(path: "/files", parameters: {}).once
        expect(c1).to receive(:get).with(path: "/files", parameters: {}).once
        expect(c2).to receive(:get).with(path: "/files", parameters: {}).once

        expect(c0).to receive(:get).with(path: "/fine_tuning/jobs").once
        expect(c1).to receive(:get).with(path: "/fine_tuning/jobs").once
        expect(c2).to receive(:get).with(path: "/fine_tuning/jobs").once

        expect(c0).to receive(:json_post).with(path: "/images/generations", parameters: {}).once
        expect(c1).to receive(:json_post).with(path: "/images/generations", parameters: {}).once
        expect(c2).to receive(:json_post).with(path: "/images/generations", parameters: {}).once

        expect(c0).to receive(:get).with(path: "/models").once
        expect(c1).to receive(:get).with(path: "/models").once
        expect(c2).to receive(:get).with(path: "/models").once
      end
    end
  end

  context "when using admin endpoints" do
    let(:admin_token) { "admin-token" }

    context "with admin token configured" do
      let(:client) do
        ShopifAi::Client.new(admin_token: admin_token)
      end

      it "creates a new client instance with admin token as access token" do
        admin_client = client.admin
        expect(admin_client).not_to eq(client)
        expect(admin_client.access_token).to eq(admin_token)
        expect(client.access_token).not_to eq(admin_token) # Original unchanged
      end

      it "rebuilds memoized endpoints for the admin client" do
        authorization_headers = []
        client = ShopifAi::Client.new(
          access_token: "user-token",
          admin_token: admin_token,
          api_version: "",
          uri_base: "https://example.test"
        ) do |faraday|
          faraday.adapter :test do |stubs|
            stubs.get("/threads/thread-id") do |env|
              authorization_headers << env.request_headers["Authorization"]
              [200, { "Content-Type" => "application/json" }, "{}"]
            end
          end
        end
        client.threads

        client.admin.threads.retrieve(id: "thread-id")

        expect(authorization_headers).to eq(["Bearer #{admin_token}"])
      end
    end

    context "when using both beta and admin" do
      let(:client) do
        ShopifAi::Client.new(admin_token: admin_token)
      end

      it "allows chaining beta and admin" do
        admin_beta_client = client.beta(assistants: "v2").admin
        expect(admin_beta_client.access_token).to eq(admin_token)
        expect(admin_beta_client.send(:headers)["OpenAI-Beta"]).to eq "assistants=v2"
      end

      it "allows chaining admin and beta" do
        admin_beta_client = client.admin.beta(assistants: "v2")
        expect(admin_beta_client.access_token).to eq(admin_token)
        expect(admin_beta_client.send(:headers)["OpenAI-Beta"]).to eq "assistants=v2"
      end
    end
  end

  context "when using beta APIs" do
    let(:client) { ShopifAi::Client.new.beta(assistants: "v2") }

    it "sends the appropriate header value" do
      expect(client.send(:headers)["OpenAI-Beta"]).to eq "assistants=v2"
    end
  end

  context "when building HTTP connections" do
    let(:client) { ShopifAi::Client.new }

    it "reuses normal and multipart connections" do
      connection = client.send(:conn)
      multipart_connection = client.send(:conn, multipart: true)

      expect(client.send(:conn)).to equal(connection)
      expect(client.send(:conn, multipart: true)).to equal(multipart_connection)
      expect(multipart_connection).not_to equal(connection)
    end

    it "builds the middleware stack once under concurrent first requests" do
      build_count = 0
      count_mutex = Mutex.new
      middleware_initialize = Faraday::Middleware.instance_method(:initialize)
      middleware_class = Class.new(Faraday::Middleware) do
        define_method(:initialize) do |app|
          count_mutex.synchronize { build_count += 1 }
          sleep 0.01
          middleware_initialize.bind(self).call(app)
        end
      end
      concurrent_client = ShopifAi::Client.new(uri_base: "https://example.test") do |faraday|
        faraday.use middleware_class
        faraday.adapter :test do |stubs|
          stubs.get("/v1/ping") { [200, { "Content-Type" => "application/json" }, "{}"] }
        end
      end

      responses = Array.new(8) do
        Thread.new { concurrent_client.send(:get, path: "/ping") }
      end.map(&:value)

      expect(responses).to all(eq({}))
      expect(build_count).to eq(1)
    end

    it "does not share connections with duplicated clients" do
      connection = client.send(:conn)
      multipart_connection = client.send(:conn, multipart: true)
      duplicate = client.dup

      expect(duplicate.send(:conn)).not_to equal(connection)
      expect(duplicate.send(:conn, multipart: true)).not_to equal(multipart_connection)
    end
  end

  context "with a block" do
    let(:client) do
      ShopifAi::Client.new do |client|
        client.response :logger, Logger.new($stdout), bodies: true
      end
    end

    it "applies the configured middleware to both connections" do
      connection = client.send(:conn)
      multipart_connection = client.send(:conn, multipart: true)

      expect(connection.builder.handlers).to include Faraday::Response::Logger
      expect(multipart_connection.builder.handlers).to include Faraday::Response::Logger
    end
  end

  context "when calling inspect" do
    let(:api_key) { "sk-123456789" }
    let(:connection_header) { "Bearer connection-secret" }
    let(:organization_id) { "org-123456789" }
    let(:extra_headers) { { "Other-Auth": "key-123456789" } }
    let(:uri_base) { "https://example.com/" }
    let(:request_timeout) { 500 }
    let(:client) do
      ShopifAi::Client.new(
        uri_base: uri_base,
        request_timeout: request_timeout,
        access_token: api_key,
        organization_id: organization_id,
        extra_headers: extra_headers
      ) do |connection|
        connection.headers["Authorization"] = connection_header
      end
    end

    it "does not expose sensitive information" do
      client.send(:conn)
      client.send(:conn, multipart: true)
      expect(client.inspect).not_to include(api_key)
      expect(client.inspect).not_to include(organization_id)
      expect(client.inspect).not_to include(extra_headers[:"Other-Auth"])
      expect(client.inspect).not_to include(connection_header)
    end

    it "does expose non-sensitive information" do
      expect(client.inspect).to include(uri_base.inspect)
      expect(client.inspect).to include(request_timeout.inspect)
      expect(client.inspect).to include(client.object_id.to_s)
      expect(client.inspect).to include(client.class.to_s)
    end
  end
end
