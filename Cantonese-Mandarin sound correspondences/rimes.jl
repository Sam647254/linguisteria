include("../helpers.jl")

using Unicode

struct PinyinSyllable
   initial::Union{String, Nothing}
   final::String
end

struct JyutpingSyllable
   initial::Union{String, Nothing}
   final::String
   final_plosive::Union{String, Nothing}
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
   "ü" => "yu",
   "üe" => "yue",
   "ün" => "yun",
   "üan" => "yuan"
])

function parse_pinyin(pinyin::AbstractString)
   normalized = Unicode.normalize(pinyin, decompose=true) |> collect
   syllable = Unicode.normalize(filter(l -> isletter(l) || l == '\u0308', normalized) |> String,
      compose=true)

   if syllable in PINYIN_SYLLABIC_FRICATIVES
      return PinyinSyllable(syllable[1:end-1], "_")
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
         PINYIN_NONNULL_INITIAL_FINALS[replace(remaining, "u" => "ü")]
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

   pseudo_initial = if initial === nothing &&
      ((startswith(final, "y") && !startswith(final, "yu")) || startswith(final, "w"))
      final[1:1]
   end

   PinyinSyllable(default(pseudo_initial, initial), final)
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
   syllable = filter(isletter, jyutping |> collect) |> String
   
   if syllable in JYUTPING_SYLLABIC_NASALS
      return JyutpingSyllable(nothing, syllable, nothing)
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

   if final === nothing
      error("Invalid jyutping: $jyutping")
   end

   JyutpingSyllable(initial, final, final_plosive)
end

function syllable_mapping(triples)
   monophones = filter(t -> length(t[2]) == 1, triples)
   syllable_triples = map(monophones) do t
      (t[1], parse_pinyin(t[2] |> only), parse_jyutping(t[3]))
   end
end