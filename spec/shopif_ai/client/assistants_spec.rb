RSpec.describe ShopifAi::Client do
  describe "#assistants" do
    let(:assistant_id) do
      VCR.use_cassette("#{cassette} setup") do
        ShopifAi::Client.new.assistants.create(
          parameters: {
            model: "gpt-4",
            name: "OpenAI-Ruby test assistant"
          }
        )["id"]
      end
    end

    describe "#list", :vcr do
      let(:response) { ShopifAi::Client.new.assistants.list }
      let(:cassette) { "assistants list" }

      before { assistant_id }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response.dig("data", 0, "object")).to eq("assistant")
        end
      end
    end

    describe "#retrieve" do
      let(:cassette) { "assistants retrieve" }
      let(:response) { ShopifAi::Client.new.assistants.retrieve(id: assistant_id) }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq("assistant")
        end
      end
    end

    describe "#create" do
      let(:cassette) { "assistants create" }
      let(:response) do
        ShopifAi::Client.new.assistants.create(parameters: { model: "gpt-4",
                                                           name: "OpenAI-Ruby test assistant" })
      end

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq "assistant"
        end
      end
    end

    describe "#modify" do
      let(:cassette) { "assistants modify" }
      let(:response) do
        ShopifAi::Client.new.assistants.modify(
          id: assistant_id,
          parameters: { model: "gpt-3.5-turbo", name: "Test Assistant for OpenAI-Ruby" }
        )
      end

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq "assistant"
        end
      end
    end

    describe "#delete" do
      let(:cassette) { "assistants delete" }
      let(:response) do
        ShopifAi::Client.new.assistants.delete(id: assistant_id)
      end

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq "assistant.deleted"
        end
      end
    end
  end
end
