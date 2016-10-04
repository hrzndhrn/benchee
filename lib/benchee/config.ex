defmodule Benchee.Config do
  @moduledoc """
  Functions to handle the configuration of Benchee, exposes `init` function.
  """

  alias Benchee.Conversion.Duration

  @doc """
  Returns the initial benchmark configuration for Benchee, composed of defauls
  and an optional custom configuration.
  Configuration times are given in seconds, but are converted to microseconds.

  Possible options:

    * `time`       - total run time in seconds of a single benchmark (determines
    how often it is executed). Defaults to 5.
    * `warmup`     - the time in seconds for which the benchmarking function
    should be run without gathering results. Defaults to 2.
    * `parallel`   - each job will be executed in `parallel` number processes.
    Gives you more data in the same time, but also puts a load on the system
    interfering with benchmark results. Defaults to 1.
    * `formatters` - list of formatter function you'd like to run to output the
    benchmarking results of the suite when using `Benchee.run/2`. Functions need
    to accept one argument (which is the benchmarking suite with all data) and
    then use that to produce output. Used for plugins. Defaults to the builtin
    console formatter calling `Benche.Formatters.Console.output/1`.
    * `print`      - a map from atoms to `true` or `false` to configure if the
    output identified by the atom will be printed. All options are enabled by
    default (true). Options are:
      * `:benchmarking`  - print when Benchee starts benchmarking a new job
      (Benchmarking name ..)
      * `:configuration` - a summary of configured benchmarking options
      including estimated total run time is printed before benchmarking starts
      * `:fast_warning`   - warnings are displayed if functions are executed
      too fast leading to inaccurate measures
    * `console` - options for the built-in console formatter. Like the
    `print` options the boolean options are also enabled by default:
      * `:comparison`   - if the comparison of the different benchmarking jobs
      (x times slower than) is shown (true/false)
      * `:unit_scaling` - which strategy should be used to scale the units in
      the output. When the documentation says "best fit unit" what is meant is
      the unit in which the duration/count can be represented so that it is the
      largest unit that can represent teh value and be at least 1. E.g.
      1_200_000 will be scalled to `1.2 M` while `800_000` is scaled to
      `800 K`. Which of all those "best fit" units will be selected to scale
      all results to that unit is a matter of the strategy. There are four
      different strategies defaulting to `:best`:
          * `:best`    - the most frequent best fit unit will be used, a tie
          will result in the larger unit being selected.
          * `largest`  - the largest best fit unit will be used (i.e. Thousand
          and seconds if values are large enough).
          * `smallest` - the smallest best fit unit will be used (i.e.
          millisecond and one)
          * `none`     - no unit scaling will occur, e.g. the units will be the
          base units microseconds and one (this is equivalent to the behaviour
          benchee had pre 0.5.0)


  ## Examples

      iex> Benchee.init
      %{
        config:
          %{
            parallel: 1,
            time: 5_000_000,
            warmup: 2_000_000,
            formatters: [&Benchee.Formatters.Console.output/1],
            print: %{
              benchmarking: true,
              fast_warning: true,
              configuration: true
            },
            console: %{ comparison: true, unit_scaling: :best }
          },
        jobs: %{}
      }

      iex> Benchee.init %{time: 1, warmup: 0.2}
      %{
        config:
          %{
            parallel: 1,
            time: 1_000_000,
            warmup: 200_000.0,
            formatters: [&Benchee.Formatters.Console.output/1],
            print: %{
              benchmarking: true,
              fast_warning: true,
              configuration: true
            },
            console: %{ comparison: true, unit_scaling: :best }
          },
        jobs: %{}
      }

      iex> Benchee.init %{parallel: 2, time: 1, warmup: 0.2, formatters: [&IO.puts/2], print: %{fast_warning: false}, console: %{unit_scaling: :smallest}}
      %{
        config:
          %{
            parallel: 2,
            time: 1_000_000,
            warmup: 200_000.0,
            formatters: [&IO.puts/2],
            print: %{
              benchmarking: true,
              fast_warning: false,
              configuration: true
            },
            console: %{ comparison: true, unit_scaling: :smallest }
          },
        jobs: %{}
      }
  """
  @default_config %{
    parallel:   1,
    time:       5,
    warmup:     2,
    formatters: [&Benchee.Formatters.Console.output/1],
    print:      %{
                  benchmarking:  true,
                  configuration: true,
                  fast_warning:  true
                },
    console:    %{
                  comparison:   true,
                  unit_scaling: :best
                }
  }
  @time_keys [:time, :warmup]
  def init(config \\ %{}) do
    print   = print_config config
    console = console_config config
    config  = convert_time_to_micro_s(Map.merge(@default_config, config))
    config  = %{config | print: print, console: console}
    :ok     = :timer.start
    %{config: config, jobs: %{}}
  end

  defp convert_time_to_micro_s(config) do
    Enum.reduce @time_keys, config, fn(key, new_config) ->
      {_, new_config} = Map.get_and_update! new_config, key, fn(seconds) ->
        {seconds, Duration.microseconds({seconds, :second})}
      end
      new_config
    end
  end

  defp print_config(%{print: config}) do
    Map.merge @default_config.print, config
  end
  defp print_config(_no_print_config) do
    @default_config.print
  end

  defp console_config(%{console: config}) do
    Map.merge @default_config.console, config
  end
  defp console_config(_no_console_config) do
    @default_config.console
  end
end
