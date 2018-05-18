defmodule ZeamCallback do
  @moduledoc """
  Documentation for ZeamCallback.
  """

  @doc """
  test of callback thread.

  ## Examples

      iex> import ExUnit.CaptureIO
      iex> capture_io(fn -> ZeamCallback.call(fn (a) -> (IO.puts a) end, "function", fn () -> (IO.puts "callbacked") end) end)
      "function\\ncallbacked\\n"

  """
  def call(function, arg, callback) do
    function.(arg)
    callback.()
  end
end
