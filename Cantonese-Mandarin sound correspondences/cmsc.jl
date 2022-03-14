using JSON
using OrderedCollections
using Unicode
using DataFrames
using PlotlyJS

include("../helpers.jl")
include("./rimes.jl")
include("./tones_plot.jl")

function load_triples()
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

   # 4. Match the two pronunciations
   map(tchars) do (tunicode, tchar)
      pinyin = pinyin_dict[uppercase(tunicode)]
      jyutping = jp[tchar]
      (tchar, pinyin, jyutping)
   end
end

# 5. Map the tones
TONE_REGEX = r".*([0-9]).*"
MANDARIN_TONES = ['\u0304', '\u0301', '\u030C', '\u0300']

# Plot the tone correspondences
MANDARIN_TONE_LABELS = [
   "Flat (ā)",
   "Rising (á)",
   "Dipping (ǎ)",
   "Falling (à)"
]

CANTONESE_TONE_LABELS = [
   "High flat (1)",
   "Mid rising (2)",
   "Mid flat (3)",
   "Low falling (4)",
   "Low rising (5)",
   "Low flat (6)"
]

function save_tone_mapping_to_json(prefix)
   (mc, cm) = extract_tones(triples)
   open("$(prefix)_mc.json", "w") do f
      write(f, json(mc))
   end

   open("$(prefix)_cm.json", "w") do f
      write(f, json(cm))
   end
end

function save_syllable_mapping_to_json(filename_prefix)
   (initial_mapping, final_mapping, full_syllable_mapping) = syllable_mapping(triples)
   open("$(filename_prefix)_im.json", "w") do f
      write(f, json(initial_mapping))
   end

   open("$(filename_prefix)_fm.json", "w") do f
      write(f, json(final_mapping))
   end

   open("$(filename_prefix)_fsm.json", "w") do f
      write(f, json(full_syllable_mapping))
   end
end

function main()
   triples = load_triples()
   syllables = syllable_mapping(triples)
   tones = extract_tones(triples)

   open("$(dirname(@__FILE__))/output/syllables.json", "w") do f
      write(f, json(syllables))
   end

   open("$(dirname(@__FILE__))/output/tones.json", "w") do f
      write(f, json(tones))
   end
end

main()