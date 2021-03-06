defmodule Hex.State do
  @name __MODULE__
  @logged_keys ~w(http_proxy HTTP_PROXY https_proxy HTTPS_PROXY)
  @default_home "~/.hex"
  @default_url "https://hex.pm/api"
  @default_cdn "https://s3.amazonaws.com/s3.hex.pm"

  def start_link do
    config = Hex.Config.read
    Agent.start_link(__MODULE__, :init, [config], [name: @name])
  end

  def init(config) do
    %{home: Path.expand(System.get_env("HEX_HOME") || @default_home),
      api: load_config(config, ["HEX_API"], :api_url) || @default_url,
      cdn: load_config(config, ["HEX_CDN"], :cdn_url) || @default_cdn,
      http_proxy: load_config(config, ["http_proxy", "HTTP_PROXY"], :http_proxy),
      https_proxy: load_config(config, ["https_proxy", "HTTPS_PROXY"], :https_proxy),
      offline?: System.get_env("HEX_OFFLINE") == "1",
      cert_check?: System.get_env("HEX_UNSAFE_HTTPS") != "1",
      registry_updated: false}
  end

  def fetch(key) do
    Agent.get(@name, Map, :fetch, [key])
  end

  def fetch!(key) do
    Agent.get(@name, Map, :fetch!, [key])
  end

  def get(key, default \\ nil) do
    Agent.get(@name, Map, :get, [key, default])
  end

  def put(key, value) do
    Agent.update(@name, Map, :put, [key, value])
  end

  def load_config(config, envs, config_key) do
    result =
      envs
      |> Enum.map(&env_exists/1)
      |> Enum.find(&(not is_nil &1))
      || config_exists(config, config_key)

    if result do
      {key, value} = result

      log_value(key, value)
      value
    end
  end

  defp env_exists(key) do
    if value = System.get_env(key) do
      {key, value}
    else
      nil
    end
  end

  defp config_exists(config, key) do
    if value = Keyword.get(config, key) do
      {"config[:#{key}]", value}
    else
      nil
    end
  end

  defp log_value(key, value) do
    if Enum.member?(@logged_keys, key) do
      Hex.Shell.info "Using #{key} = #{value}"
    end
  end
end
