defmodule CMSC do
  @moduledoc """
  Documentation for `Cmsc`.
  """

  @entry_regex ~r/^([A-Z0-9]+) \((.*)\)$/

  def load_triples() do
    tc =
      File.stream!("#{__DIR__}/../data/traditional.txt")
      |> Stream.map(fn line ->
        [_, _, tunicode, tchar] = String.split(line, " ")
        {tunicode, tchar}
      end)

    pinyin_dict =
      File.stream!("#{__DIR__}/../data/unicode_to_hanyu_pinyin.txt")
      |> Stream.map(fn line ->
        [_, unicode, pinyin | _ ] = Regex.run(@entry_regex, line)
        {unicode, pinyin}
      end)
  end
end
