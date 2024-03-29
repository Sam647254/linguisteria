include("../helpers.jl")

using DataStructures
using Unicode

struct LwomazhSyllable
   initial::String
   initial_phoneme::String
   c_initial::String
   final::String
   c_final::String
   full::String
   tone::Int
end

struct LoamaziSyllable
   initial::String
   final::String
   m_final::String
   final_plosive::String
   full::String
   tone::Int
end

PINYIN_SYLLABIC_FRICATIVES = Dict([
   "zi" => ("z", "zh", "zh"),
   "ci" => ("ts", "zh", "tszh"),
   "si" => ("s", "zh", "szh"),
   "zhi" => ("j", "rh", "jh"),
   "chi" => ("ch", "rh", "ch"),
   "shi" => ("sh", "rh", "sh"),
   "ri" => ("r", "rh", "rh"),
])

PINYIN_SYLLABIC_NASALS = Set(["n", "ng"])

PINYIN_INITIALS = [
   "zh",
   "ch",
   "sh",
   "b",
   "p",
   "m",
   "f",
   "d",
   "t",
   "n",
   "z",
   "c",
   "s",
   "l",
   "r",
   "j",
   "q",
   "x",
   "g",
   "k",
   "h"
]

PINYIN_FINALS = Set([
   "e",
   "a",
   "ei",
   "ai",
   "ou",
   "ao",
   "en",
   "an",
   "ong",
   "eng",
   "ang",
   "er",
   "yi",
   "ye",
   "ya",
   "you",
   "yao",
   "yin",
   "yan",
   "ying",
   "yong",
   "yang",
   "wu",
   "wo",
   "wa",
   "wei",
   "wai",
   "wen",
   "wan",
   "weng",
   "wang",
   "yo",
   "yu",
   "yue",
   "yun",
   "yuan",
   "n",
   "ng",
])

PINYIN_NONNULL_INITIAL_FINALS = Dict([
   "i" => "yi",
   "ie" => "ye",
   "ia" => "ya",
   "iu" => "you",
   "iao" => "yao",
   "in" => "yin",
   "ian" => "yan",
   "ing" => "ying",
   "iong" => "yong",
   "iang" => "yang",
   "u" => "wu",
   "o" => "wo",
   "uo" => "wo",
   "ua" => "wa",
   "ui" => "wei",
   "uai" => "wai",
   "un" => "wen",
   "uan" => "wan",
   "uang" => "wang",
   "u:" => "yu",
   "u:e" => "yue",
   "u:n" => "yun",
   "u:an" => "yuan"
])

PINYIN_INITIALS_TO_LWOMAZH = Dict([
   "c" => "ts",
   "zh" => "j",
   "j" => "jy-",
   "q" => "chy-",
   "x" => "shy-",
])

PINYIN_INITIALS_TO_LWOMAZH_PHONEME = Dict([
   "j" => "j",
   "q" => "ch",
   "x" => "sh",
])

PINYIN_INITIALS_TO_LWOMAZH_FULL = Dict([
   "zh" => "j",
   "q" => "ch",
   "x" => "sh",
])

PINYIN_FINALS_TO_LWOMAZH = Dict(
   "ao" => "au",
   "yi" => "i",
   "yao" => "yau",
   "yin" => "in",
   "ying" => "ing",
   "wu" => "u",
   "yu" => "eu",
   "yun" => "eun",
   "yuan" => "yuen",
   "ng" => "ngh",
)

function parse_pinyin(pinyin::AbstractString)::LwomazhSyllable
   syllable = pinyin[1:end-1]
   tone = parse(Int, pinyin[end:end])

   if haskey(PINYIN_SYLLABIC_FRICATIVES, syllable)
      (initial, final, full) = get(PINYIN_SYLLABIC_FRICATIVES, syllable, syllable)
      return LwomazhSyllable(initial, initial, initial, final, final, full, tone)
   end

   if syllable in PINYIN_SYLLABIC_NASALS
      return LwomazhSyllable(syllable, syllable, syllable, syllable * "h", syllable * "h", syllable * "h", tone)
   end

   initial_index = findfirst(i -> startswith(syllable, i), PINYIN_INITIALS)
   initial = initial_index === nothing ? "" : PINYIN_INITIALS[initial_index]

   final = begin
      remaining = if initial === ""
         syllable
      else
         syllable[length(initial)+1:end]
      end

      if startswith(remaining, "u") && initial in ["j", "q", "x"]
         PINYIN_NONNULL_INITIAL_FINALS[replace(remaining, "u" => "u:")]
      elseif haskey(PINYIN_NONNULL_INITIAL_FINALS, remaining)
         PINYIN_NONNULL_INITIAL_FINALS[remaining]
      elseif remaining in PINYIN_FINALS
         remaining
      else
         nothing
      end
   end

   if final === nothing
      error("Invalid pinyin: $pinyin")
   end

   lwomazh_initial = get(PINYIN_INITIALS_TO_LWOMAZH, initial, initial)
   lwomazh_final = get(PINYIN_FINALS_TO_LWOMAZH, final, final)
   lwomazh_full = get(PINYIN_INITIALS_TO_LWOMAZH_FULL, initial, something(initial, "")) * get(PINYIN_FINALS_TO_LWOMAZH, final, final)

   (c_initial, c_final) = if (lwomazh_final[1] == 'y' || lwomazh_final[1] == 'w') && isempty(lwomazh_initial)
      ("($(lwomazh_final[1:1]))", "($(lwomazh_final[2:end]))")
   elseif startswith(lwomazh_full, "kw") || startswith(lwomazh_full, "gw")
      ("($(lwomazh_full[1:2]))", "(w)$(lwomazh_final[2:end])")
   elseif lwomazh_full == "u"
      ("(w)", "u")
   elseif lwomazh_full == "i"
      ("(y)", "i")
   else
      (lwomazh_initial, lwomazh_final)
   end

   LwomazhSyllable(
      lwomazh_initial,
      get(PINYIN_INITIALS_TO_LWOMAZH_PHONEME, initial, lwomazh_initial),
      c_initial,
      lwomazh_final,
      c_final,
      lwomazh_full,
      tone
   )
end

JYUTPING_SYLLABIC_NASALS = ["m", "ng"]

JYUTPING_INITIALS = [
   "ng",
   "gw",
   "kw",
   "b",
   "p",
   "m",
   "f",
   "d",
   "t",
   "n",
   "s",
   "l",
   "z",
   "c",
   "j",
   "g",
   "k",
   "w",
   "h"
]

JYUTPING_INITIALS_TO_LOAMAZI = Dict([
   "c" => "ts/ch",
   "j" => "y",
   "z" => "z/j",
])

JYUTPING_FINALS = [
   "aa",
   "aai",
   "aau",
   "aam",
   "aan",
   "aang",
   "aap",
   "aat",
   "aak",
   "a",
   "ai",
   "au",
   "am",
   "an",
   "ang",
   "ap",
   "at",
   "ak",
   "e",
   "ei",
   "eu",
   "em",
   "eng",
   "et",
   "ep",
   "ek",
   "i",
   "iu",
   "im",
   "in",
   "ing",
   "ip",
   "it",
   "ik",
   "m",
   "ng",
   "o",
   "oi",
   "ou",
   "on",
   "ong",
   "ot",
   "ok",
   "u",
   "ui",
   "un",
   "ung",
   "ut",
   "uk",
   "eoi",
   "eon",
   "eot",
   "oe",
   "oeng",
   "oet",
   "oek",
   "yu",
   "yun",
   "yun",
   "yut"
]

JYUTPING_FINALS_TO_LOAMAZI = Dict([
   "aa" => "a",
   "aai" => "ai",
   "aau" => "au",
   "aam" => "am",
   "aan" => "an",
   "aang" => "ang",
   "aap" => "ap",
   "aat" => "at",
   "aak" => "ak",
   "a" => "ea",
   "ai" => "eai",
   "au" => "eau",
   "am" => "eam",
   "an" => "ean",
   "ang" => "eang",
   "ap" => "eap",
   "at" => "eat",
   "ak" => "eak",
   "e" => "ae",
   "eu" => "aeu",
   "em" => "aem",
   "eng" => "aeng",
   "ep" => "aep",
   "ek" => "aek",
   "o" => "oa",
   "oi" =>"oai",
   "on" => "oan",
   "ong" => "oang",
   "ot" => "oat",
   "ok" => "oak",
   "ung" => "ong",
   "ut" => "ut",
   "uk" => "ok",
   "eoi" => "oei",
   "eon" => "oen",
   "eot" => "oet",
   "yu" => "eu",
   "yun" => "eun",
   "yut" => "eut",
   "m" => "mh",
   "ng" => "ngh",
])

function parse_jyutping(jyutping::AbstractString)::LoamaziSyllable
   syllable = jyutping[1:end-1]
   tone = parse(Int, jyutping[end:end])

   if syllable in JYUTPING_SYLLABIC_NASALS
      return LoamaziSyllable(syllable, syllable * "h", syllable * "h", "", syllable * "h", tone)
   end

   initial_index = findfirst(i -> startswith(syllable, i), JYUTPING_INITIALS)
   initial = initial_index === nothing ? "" : JYUTPING_INITIALS[initial_index]

   (final, final_plosive) = begin
      remaining = syllable[length(something(initial, ""))+1:end]
      final_plosive = if any(p -> endswith(remaining, p), ["p", "t", "k"])
         remaining[end:end]
      else
         ""
      end

      if remaining in JYUTPING_FINALS
         (remaining[1:end-length(default(final_plosive, ""))], final_plosive)
      else
         (nothing, nothing)
      end
   end

   if final === nothing
      error("Invalid jyutping: $jyutping")
   end

   initial = get(JYUTPING_INITIALS_TO_LOAMAZI, initial, initial)
   initial_full = if initial == "ts/ch"
      if startswith(final, "yu") || startswith(final, "oe")
         "ch"
      else
         "ts"
      end
   elseif initial == "z/j"
      if startswith(final, "yu") || startswith(final, "oe")
         "j"
      else
         "z"
      end
   else
      initial
   end

   final = get(JYUTPING_FINALS_TO_LOAMAZI, final, final)

   m_final = if initial == "kw" || initial == "gw"
      "(kw/gw)" * final
   elseif initial == "w" || initial == "y"
      "($initial)$final"
   else
      final
   end

   LoamaziSyllable(initial, final, m_final, final_plosive, initial_full * final * final_plosive, tone)
end

function syllable_mapping(characters)
   monophones = filter(t -> length(t.mandarin) == 1 && length(t.cantonese) == 1, characters)
   syllable_triples = map(monophones) do t
      (t.character, t.mandarin |> only, t.cantonese |> only)
   end

   mc_initial_mapping = DefaultDict(() -> DefaultDict(Set))
   mc_final_mapping = DefaultDict(() -> DefaultDict(Set))

   cm_initial_mapping = DefaultDict(() -> DefaultDict(Set))
   cm_final_mapping = DefaultDict(() -> DefaultDict(Set))

   for (c, pinyin, jyutping) in syllable_triples
      push!(mc_initial_mapping[pinyin.initial][jyutping.initial], c)
      push!(mc_final_mapping[pinyin.final][jyutping.m_final], c)

      push!(cm_initial_mapping[jyutping.initial][pinyin.c_initial], c)
      push!(cm_final_mapping[jyutping.final][pinyin.c_final], c)
   end

   Dict(
      "mc" => Dict("initialMapping" => mc_initial_mapping, "finalMapping" => mc_final_mapping),
      "cm" => Dict("initialMapping" => cm_initial_mapping, "finalMapping" => cm_final_mapping)
   )
end

# Stats calculated:
# - Least common syllable (including unique ones)

function compute_stats(pairs)
   mapping = DefaultDict(Set)

   for (syllable, character) in pairs
      set = mapping[syllable]
      push!(set, character)
   end
   return sort(mapping |> collect, by = p -> length(p[2]))
end

function syllable_stats(triples)
   m_no_tones = map(triples) do t
      map(t.mandarin) do p
         p.full => t.character
      end
   end |> Iterators.flatten
   
   m_tones = map(triples) do t
      map(t.mandarin) do p
         p.full * string(p.tone) => t.character
      end
   end |> Iterators.flatten

   c_no_tones = map(triples) do t
      map(t.cantonese) do l
         l.full => t.character
      end
   end |> Iterators.flatten

   c_tones = map(triples) do t
      map(t.cantonese) do l
         l.full * string(l.tone) => t.character
      end
   end |> Iterators.flatten

   Dict(
      "m_no_tones" => compute_stats(m_no_tones),
      "m_tones" => compute_stats(m_tones),
      "c_no_tones" => compute_stats(c_no_tones),
      "c_tones" => compute_stats(c_tones),
   )
end