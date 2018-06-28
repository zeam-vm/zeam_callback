defmodule ZeamEvaluation do

  def diff([], _kw), do: []

  def diff([kw1_tuple | kw1_tail], kw2) do
    kw_key = elem(kw1_tuple, 0)
    kw1_value = elem(kw1_tuple, 1)
    kw2_value = kw2[kw_key]
    [{kw_key, kw2_value - kw1_value}] ++ diff(kw1_tail, kw2)
  end

  def pr_init do
    0
  end

  def pr_call(_pid, number) when number <= 0, do: []

  def pr_call(pid, number) when number > 0 do
    spawn(fn -> Process.sleep(10000) end)
    [ number | pr_call(pid, number - 1)]
  end

  def cb_init do
    ZeamCallback.Receptor.new
  end

  def cb_call(_pid, number) when number <= 0, do: []

  def cb_call(pid, number) when number > 0 do
    send(pid, {:spawn, fn(_tid) -> Process.sleep(1000) end})
    [ number | cb_call(pid, number - 1)]
  end

  def memory_benchmark(func_init, func_call, number) do
    #:erlang.garbage_collect()
    #Process.sleep(200)
    before_memory = :erlang.memory
    func_call.(func_init.(), number)
    #:erlang.garbage_collect()
    #Process.sleep(200)
    after_memory = :erlang.memory
    IO.inspect diff(before_memory, after_memory)[:total]
  end

  def all_benchmarks do
    [
      #{&cb_init/0, &cb_call/2,   100, "callback"},
      #{&cb_init/0, &cb_call/2,  1000, "callback"},
      #{&cb_init/0, &cb_call/2,  2000, "callback"},
      #{&cb_init/0, &cb_call/2,  5000, "callback"},
      #{&cb_init/0, &cb_call/2, 10000, "callback"},
      #{&pr_init/0, &pr_call/2,   100, "process"},
      #{&pr_init/0, &pr_call/2,  1000, "process"},
      #{&pr_init/0, &pr_call/2,  2000, "process"},
      #{&pr_init/0, &pr_call/2,  5000, "process"},
      {&pr_init/0, &pr_call/2, 10000, "process"},
    ]
    |> Enum.map(fn (x) ->
      IO.puts "#{elem(x, 3)}: #{elem(x, 2)}"
      memory_benchmark(elem(x, 0), elem(x, 1), elem(x, 2))
    end)
  end
end