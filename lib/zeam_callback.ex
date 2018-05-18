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

  defmodule Worker do
  	def add_message(env, tid, mes) do
  	  %{:queue => [{:message, tid, mes} | env[:queue]], :threads => env[:threads], :next_tid => env[:next_tid]}
  	end

  	def add_thread(env, tid, func) do
  	  %{:queue => env[:queue] ++ [{:thread, tid, func}], :threads => env[:threads], :next_tid => env[:next_tid]}
  	end

  	def spawn(env, func) do
  	  queue = env[:queue]
  	  threads = env[:threads]
  	  tid = env[:next_tid]
  	  if threads[tid] do
  	    spawn(%{:queue => queue, :threads => threads, :next_tid => tid + 1})
  	  else
  	  	%{:queue => [{tid, func} | queue], :threads => Map.put(threads, tid, &(&1)), :next_tid => tid + 1}
  	  end
  	end

    def worker(receptor) do
      worker(receptor, %{:queue => [], :threads => %{}, :next_tid => 0})
    end

    def worker(receptor, env) do
      receive do
        {:queue} ->
          send(receptor, {:queue, env})
          worker(receptor, env)
        {:ping} ->
          send(receptor, {:ping})
          worker(receptor, env)
        {:send, tid, mes} ->
          new_env = add_message(env, tid, mes)
          send(receptor, {:queue, new_env})
          worker(receptor, new_env)
        {:spawn, func} ->
          new_env = spawn(env, func)
          send(receptor, {:queue, new_env})
          worker(receptor, new_env)
        {:spawn, func, pid} ->
          new_env = spawn(env, func)
          send(receptor, {:queue, new_env})
          send(pid, {:tid, new_env[:next_tid] - 1})
          worker(receptor, new_env)
        {:spawn, func, pid, tid} ->
          new_env = spawn(env, func)
          send(receptor, {:queue, new_env})
          send(pid, {:send, tid, {:tid, new_env[:next_tid] - 1}})
          worker(receptor, new_env)
        {:set_handler, tid, func} ->
          new_env = %{:queue => env[:queue], :threads => Map.put(env[:threads], tid, func), :next_tid => env[:next_tid]}
          send(receptor, {:queue, new_env})
          worker(receptor, new_env)
        {:call_handler, tid, mes} ->
          env[:threads][tid].(mes)
          send(receptor, {:ping})
          worker(receptor, env)
        {:add_queue, tid, func} ->
          new_env = add_thread(env, tid, func)
          send(receptor, {:queue, new_env})
          worker(receptor, new_env)
      after
        0 ->
          case env[:queue] do
            [] ->
              Process.sleep(10)
              worker(receptor, env)
            [head | queue] ->
  	        new_env = %{:queue => queue, :threads => env[:threads], :next_tid => env[:next_tid]}
  	        send(receptor, {:queue, new_env})
  	        case head do
  	          {:message, tid, mes} -> env[:threads][tid].(mes)
  	          {:thread, tid, func} -> func.(tid)
  	          _ -> Process.sleep(10)
  	        end
  	        worker(receptor, new_env)
  	      end
      end
    end
  end

  defmodule Receptor do
  	def new() do
  	  spawn(Receptor, :receptor, [])
  	end

    def receptor() do
      receptor(spawn(Worker, :worker, [self()]))
    end

    def receptor(worker) do
      send(worker, {:queue})
      receptor(worker, nil)
    end

    def receptor(worker, env) do
      receive do
        {:queue, new_env} ->
          send(worker, {:ping})
          receptor(worker, new_env)
        {:ping} ->
          send(worker, {:ping})
          receptor(worker, env)
        {:spawn, func, pid, tid} ->
          send(worker, {:spawn, func, pid, tid})
          receptor(worker, env)
        {:spawn, func, pid} ->
          send(worker, {:spawn, func, pid})
          receptor(worker, env)
        {:spawn, func} ->
          send(worker, {:spawn, func})
          receptor(worker, env)
        {:send, tid, msg} ->
          send(worker, {:send, tid, msg}) # TODO 該当がない場合の処理
          receptor(worker, env)
      after
        1_000 ->
          "nothing after 1s" # TODO workerの再起動
          receptor(worker, env)
      end
    end
  end
end
