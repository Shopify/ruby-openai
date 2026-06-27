RSpec.describe ShopifAi::Client do
  describe "#threads" do
    let(:thread_id) do
      VCR.use_cassette("#{cassette} setup") do
        ShopifAi::Client.new.threads.create(parameters: {})["id"]
      end
    end

    describe "#retrieve" do
      let(:cassette) { "threads retrieve" }
      let(:response) { ShopifAi::Client.new.threads.retrieve(id: thread_id) }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq("thread")
        end
      end
    end

    describe "#create" do
      let(:cassette) { "threads create" }
      let(:response) do
        ShopifAi::Client.new.threads.create(parameters: {})
      end

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq "thread"
        end
      end
    end

    describe "#modify" do
      let(:cassette) { "threads modify" }
      let(:response) do
        ShopifAi::Client.new.threads.modify(
          id: thread_id,
          parameters: { metadata: { modified: "true" } }
        )
      end

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq "thread"
        end
      end
    end

    describe "#delete" do
      let(:cassette) { "threads delete" }
      let(:response) do
        ShopifAi::Client.new.threads.delete(id: thread_id)
      end

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq "thread.deleted"
        end
      end
    end
  end
end
