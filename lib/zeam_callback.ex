defmodule ZeamCallback do
  @moduledoc """
  Documentation for ZeamCallback.
  """

  @doc """
  test of callback thread.

  ## Examples

    defmodule Bar
      def func(a)
        IO.puts a
      end
    end

      iex> import ExUnit.CaptureIO
      iex> capture_io(fn -> ZeamCallback.call(&Bar.func/1, "function", fn () -> (IO.puts "callbacked") end) end)
      "function\\ncallbacked\\n"

  """
  def call(function, arg, callback) do
    function.(arg)
    callback.()
  end
end
