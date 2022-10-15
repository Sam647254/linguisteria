using JSON
using OrderedCollections
using Unicode
using DataFrames

include("../helpers.jl")
include("./syllables.jl")
include("./chars.jl")
include("./tones_plot.jl")

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
   triples = load_characters()
   syllables = syllable_mapping(triples)
   tones = extract_tones(triples)
   stats = syllable_stats(triples)

   open("$(dirname(@__FILE__))/output/syllables.json", "w") do f
      write(f, json(syllables))
   end

   open("$(dirname(@__FILE__))/output/tones.json", "w") do f
      write(f, json(tones))
   end

   open("$(dirname(@__FILE__))/output/stats.json", "w") do f
      write(f, json(stats))
   end
end