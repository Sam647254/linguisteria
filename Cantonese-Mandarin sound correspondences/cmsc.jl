using JSON
using OrderedCollections
using Unicode
using DataFrames
using PlotlyJS

include("../helpers.jl")
include("./rimes.jl")

function load_triples()
   # Steps:
   # 1. Parse the file of Simplified Chinese-Pinyin entries
   ENTRY_REGEX = r"^.*\[\[(.*)\]\]</span>\|\|(.*)$"

   sc = readlines("$(dirname(@__FILE__))/simplified.txt")

   schars = filter(
      x -> x !== nothing,
      map(sc) do line
         matches = match(ENTRY_REGEX, line)
         if matches === nothing
            nothing
         else
            (matches.captures[1], split(matches.captures[2], ", "))
         end
      end
   )

   # 2. Convert the characters to traditional characters. It is possible that a single Simplified
   # character maps to multiple traditional characters, in which case the list will grow.
   s_to_t = readlines("$(dirname(@__FILE__))/STCharacters.txt")
   st_dict = Dict(
      map(s_to_t) do line
         (simplified, traditional) = split(line, '\t')
         return (simplified, split(traditional, ' '))
      end
   )

   tchars = map(schars) do pair
      traditional = get(st_dict, pair[1], [pair[1]])
      map(t -> (t, pair[2]), traditional)
   end |> Iterators.flatten |> collect

   # 3. Read the Jyutping dictionary
   jp = JSON.parsefile("$(dirname(@__FILE__))/chars_to_jyutping.json")

   # 4. Match the two pronunciations
   map(tchars) do pair
      jyutping = jp[pair[1]]
      (pair[1], pair[2], jyutping)
   end
end

# 5. Map the tones
CANTONESE_TONE_REGEX = r".*([0-9]).*"
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

triples = load_triples()

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