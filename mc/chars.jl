include("../helpers.jl")
include("./syllables.jl")

using DataStructures
using JSON

struct CharInfo
   character::String
   mandarin::Vector{LwomazhSyllable}
   cantonese::Vector{LoamaziSyllable}
end

function load_characters()
   # Steps:
   # 1. Parse the file of Traditional Chinese characters and their Unicode codepoints
   tc = readlines("$(dirname(@__FILE__))/data/traditional.txt")
   tchars::Vector{Tuple{AbstractString,AbstractString}} = map(tc) do line
      _, _, tunicode, tchar = split(line, ' ')
      (tunicode, tchar)
   end

   ENTRY_REGEX = r"^([A-Z0-9]+) \((.*)\)$"
   pinyin_dict_file = readlines("$(dirname(@__FILE__))/data/unicode_to_hanyu_pinyin.txt")
   pinyin_dict = map(pinyin_dict_file) do line
      matches = match(ENTRY_REGEX, line)
      unicode = matches.captures[1]
      pinyin = split(matches.captures[2], ',')

      (unicode, pinyin)
   end |> Dict

   # 3. Read the Jyutping dictionary
   jp = JSON.parsefile("$(dirname(@__FILE__))/data/chars_to_jyutping.json")
   SYLLABLE_REGEX = r"([a-z]+[0-9])"
   jp_dictionary = DefaultDict(Set)
   for (char, jyutping) in jp
      char_pairs = zip(split(replace(char, "，" => "", "：" => ""), ""), eachmatch(SYLLABLE_REGEX, jyutping))
      for (c, j) in char_pairs
         push!(jp_dictionary[c], parse_jyutping(j.match))
      end
   end

   # 4. Match the two pronunciations
   map(tchars) do (tunicode, tchar)
      mandarin = map(parse_pinyin, pinyin_dict[uppercase(tunicode)])
      cantonese = jp_dictionary[tchar] |> collect
      CharInfo(tchar, mandarin, cantonese)
   end
end