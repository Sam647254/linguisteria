using JSON
using OrderedCollections
using Unicode
using DataFrames
using PlotlyJS

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
triples = map(tchars) do pair
   jyutping = jp[pair[1]]
   (pair[1], pair[2], jyutping)
end

# 5. Map the tones
CANTONESE_TONE_REGEX = r".*([0-9]).*"
MANDARIN_TONES = ['\u0304', '\u0301', '\u030C', '\u0300']

triples_tones = map(triples) do triple
   pinyin = triple[2]
   jyutping = triple[3]
   cantonese_tone = parse(Int, match(CANTONESE_TONE_REGEX, jyutping).captures[1])
   mandarin_tone = map(pinyin) do p
      normalized = Unicode.normalize(p, decompose=true)
      findfirst(tone -> contains(normalized, tone), MANDARIN_TONES)
   end
   (triple[1], mandarin_tone, cantonese_tone)
end

triples_single_tones = filter(triples_tones) do t
   length(t[2]) == 1
end

# helper function
function groupby(f::Function, items)
   collection = Dict()
   for item in items
      key = f(item)
      if key === nothing
         continue
      else
         push!(get!(collection, key, []), item)
      end
   end
   return collection
end

mandarin_tone_groups = groupby(t -> t[2] |> only, triples_single_tones)
mandarin_tone_counts =
   OrderedDict(tone => Dict(tone => length(entries)/length(characters)
      for (tone, entries) in groupby(t -> t[3], characters))
      for (tone, characters) in mandarin_tone_groups)

tones_matrix = zeros(4, 6)

for (mandarin_tone, cantonese_tones) in mandarin_tone_counts
   for (cantonese_tone, stat) in cantonese_tones
      tones_matrix[mandarin_tone, cantonese_tone] = stat
   end
end

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

tones_df = DataFrame(tones_matrix, CANTONESE_TONE_LABELS)
tones_df."Mandarin tone" = MANDARIN_TONE_LABELS
tones_plot = plot(
   [bar(tones_df, x=Symbol("Mandarin tone"), y=Symbol(y), name=y)
      for y in CANTONESE_TONE_LABELS],
   Layout(
      paper_bgcolor="transparent",
      plot_bgcolor="transparent",
      yaxis=attr(gridcolor="#e0e6f8"),
      font=attr(color="#e0e6f8"),
      width=800,
      height=500
   )
)
