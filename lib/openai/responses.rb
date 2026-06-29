module OpenAI
  class Responses
    def initialize(client:)
      @client = client
    end

    def create(parameters: {}, extra_headers: {})
      @client.json_post(path: "/responses", parameters: parameters, extra_headers: extra_headers)
    end

    def retrieve(response_id:, extra_headers: {})
      @client.get(path: "/responses/#{response_id}", extra_headers: extra_headers)
    end

    def delete(response_id:, extra_headers: {})
      @client.delete(path: "/responses/#{response_id}", extra_headers: extra_headers)
    end

    def input_items(response_id:, parameters: {}, extra_headers: {})
      @client.get(
        path: "/responses/#{response_id}/input_items",
        parameters: parameters,
        extra_headers: extra_headers
      )
    end
  end
end
