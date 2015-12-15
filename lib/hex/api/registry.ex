defmodule Hex.API.Registry do
  alias Hex.API

  def get(opts \\ []) do
    headers =
      if etag = opts[:etag] do
        %{'if-none-match' => etag}
      end

    Hex.Shell.info "etag headers: #{inspect headers}"
    API.request(:get, API.cdn_url("registry.ets.gz"), headers || [])
  end
end
