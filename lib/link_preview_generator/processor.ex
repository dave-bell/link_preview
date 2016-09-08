defmodule LinkPreviewGenerator.Processor do
  @moduledoc """
    TODO
  """
  alias LinkPreviewGenerator.{Redirector, OriginalUrl}
  alias LinkPreviewGenerator.Parsers.{Opengraph, Html}


  @doc """
    TODO
  """
  @spec call(String.t) :: LinkPreviewGenerator.success | LinkPreviewGenerator.failure
  def call(url) do
    with  {:ok, processed_url}   <- OriginalUrl.normalize_if_allowed(url),
          {:ok, response, page}  <- Redirector.handle(processed_url, url),
          {:ok, parsed_body}     <- parse_body(response.body)
    do
      parsers = Application.get_env(:link_preview_generator, :parsers, [Opengraph, Html])
      page = page |> collect_data(parsers, parsed_body)

      {:ok, page}
    else
      {:error, reason} ->
        {:error, reason}
      _  ->
        {:error, :unknown}
    end
  end

  defp parse_body(body) do
    {:ok, Floki.parse(body)}
  catch
    _, _ -> {:error, :floki_raised}
  end

  defp collect_data(page, parsers, parsed_body) do
    functions = [:title, :description, :images]

    Enum.reduce(parsers, page, &apply_each_function(&1, &2, functions, parsed_body))
  end

  defp apply_each_function(parser, page, functions, parsed_body) do
    Enum.reduce(functions, page, &Kernel.apply(parser, &1, [&2, parsed_body]))
  end

end
