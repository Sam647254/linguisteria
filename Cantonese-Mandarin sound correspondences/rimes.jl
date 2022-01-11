include("../helpers.jl")

using Unicode

struct PinyinSyllable
   initial::Union{String, Nothing}
   pseudo_initial::Union{String, Nothing}
   final::String
   pseudo_final::String
   original::String
end

struct JyutpingSyllable
   initial::Union{String, Nothing}
   pseudo_initial::Union{String, Nothing}
   final::String
   pseudo_final::String
   final_plosive::Union{String, Nothing}
   original::String
end

PINYIN_SYLLABIC_FRICATIVES = Set([
   "zi",
   "ci",
   "si",
   "zhi",
   "chi",
   "shi",
   "ri"
])

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
   "yuan"
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

function parse_pinyin(pinyin::AbstractString)
   syllable = pinyin[1:end-1]

   if syllable in PINYIN_SYLLABIC_FRICATIVES
      return PinyinSyllable(syllable[1:end-1], syllable[1:end-1], "_", "_", syllable)
   end

   initial_index = findfirst(i -> startswith(syllable, i), PINYIN_INITIALS)
   initial = initial_index === nothing ? nothing : PINYIN_INITIALS[initial_index]
   
   final = begin
      remaining = if initial === nothing
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

   pseudo_initial = if initial === nothing && (startswith(final, "y") || startswith(final, "w"))
      final[1:1]
   elseif (initial === "g" || initial === "k") && startswith(final, "w")
      initial * "w"
   else
      initial
   end

   pseudo_final = if pseudo_initial === "kw" || pseudo_initial === "gw"
      final[2:end]
   elseif initial === nothing && (startswith(final, "w") || (startswith(final, "y") && !startswith(final, "yu")))
      final[2:end]
   else
      final
   end

   PinyinSyllable(initial, pseudo_initial, final, pseudo_final, syllable)
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

function parse_jyutping(jyutping::String)
   syllable = jyutping[1:end-1]
   
   if syllable in JYUTPING_SYLLABIC_NASALS
      return JyutpingSyllable(nothing, nothing, syllable, syllable, nothing, syllable)
   end

   initial_index = findfirst(i -> startswith(syllable, i), JYUTPING_INITIALS)
   initial = initial_index === nothing ? nothing : JYUTPING_INITIALS[initial_index]

   (final, final_plosive) = begin
      remaining = syllable[length(default(initial, ""))+1:end]
      final_plosive = if any(p -> endswith(remaining, p), ["p", "t", "k"])
         remaining[end:end]
      else
         nothing
      end

      if remaining in JYUTPING_FINALS
         (remaining[1:end-length(default(final_plosive, ""))], final_plosive)
      else
         nothing
      end
   end

   pseudo_initial = if initial === "kw" || initial === "gw"
      initial[1:1]
   else
      initial
   end

   if final === nothing
      error("Invalid jyutping: $jyutping")
   end

   pseudo_final = if initial === "w" || (initial === "j" && !startswith(final, "yu"))
      initial * final
   elseif initial === "kw" || initial === "gw"
      "w" * final
   else
      final
   end

   JyutpingSyllable(initial, pseudo_initial, final, pseudo_final, final_plosive, syllable)
end

function syllable_mapping(triples)
   monophones = filter(t -> length(t[2]) == 1, triples)
   syllable_triples = map(monophones) do t
      (t[1], parse_pinyin(t[2] |> only), parse_jyutping(t[3]))
   end

   mc_initial_mapping = Dict()
   mc_final_mapping = Dict()

   cm_initial_mapping = Dict()
   cm_final_mapping = Dict()

   for (c, pinyin, jyutping) in syllable_triples
      push!(get!(get!(mc_initial_mapping, pinyin.pseudo_initial, Dict()), jyutping.initial, Set()), c)
      push!(get!(get!(mc_final_mapping, pinyin.pseudo_final, Dict()), jyutping.final, Set()), c)

      push!(get!(get!(cm_initial_mapping, jyutping.pseudo_initial, Dict()), pinyin.initial, Set()), c)
      push!(get!(get!(cm_final_mapping, jyutping.pseudo_final, Dict()), pinyin.final, Set()), c)
   end

   Dict(
      "mc" => (mc_initial_mapping, mc_final_mapping),
      "cm" => (cm_initial_mapping, cm_final_mapping)
   )
end