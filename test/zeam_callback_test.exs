defmodule Bar do
  def func(a) do
  	IO.puts a
  end
end

defmodule ZeamCallbackTest do
  use ExUnit.Case
  doctest ZeamCallback
end
