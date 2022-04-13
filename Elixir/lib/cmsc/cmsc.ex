defmodule CMSC do
  @moduledoc """
  Documentation for `Cmsc`.
  """

  @entry_regex ~r/^([A-Z0-9]+) \((.*)\)$/

  def load_triples() do
    tc = load_tchars()

    pinyin_dict = load_pinyin_dict()

    jp = load_jyutping_dict()
    IO.puts(map_size(jp))

    tc
    |> Enum.map(fn {tunicode, char} ->
      tupcase = String.upcase(tunicode)
      %{^tupcase => pinyin} = pinyin_dict
      %{^char => jyutping} = jp
      %CMSC.Triple{character: char, pinyin: String.split(pinyin, ","), jyutping: jyutping}
    end)
  end

  defp load_tchars() do
    File.stream!("#{__DIR__}/../data/traditional.txt")
      |> Enum.map(fn line ->
        [_, _, tunicode, tchar] = String.split(line, " ", trim: true)
        {tunicode, String.trim(tchar)}
      end)
  end

  defp load_pinyin_dict() do
    File.stream!("#{__DIR__}/../data/unicode_to_hanyu_pinyin.txt")
      |> Enum.map(fn line ->
        [_, unicode, pinyin | _] = Regex.run(@entry_regex, line)
        {unicode, pinyin}
      end)
      |> Map.new()
  end

  defp load_jyutping_dict() do
    Poison.decode!(File.read!("#{__DIR__}/../data/chars_to_jyutping.json"))
  end
end
