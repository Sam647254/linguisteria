include("../helpers.jl")

using Unicode

struct LwomazhSyllable
   initial::String
   final::String
   full::String
   tone::Int
end

struct LoamaziSyllable
   initial::String
   final::String
   final_plosive::String
   full::String
   tone::Int
end

PINYIN_SYLLABIC_FRICATIVES = Dict([
   "zi" => "z",
   "ci" => "tsz",
   "si" => "sz",
   "zhi" => "j",
   "chi" => "c",
   "shi" => "s",
   "ri" => "r",
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
      lwomazh = get(PINYIN_SYLLABIC_FRICATIVES, syllable, syllable)
      return LwomazhSyllable(lwomazh, "h", lwomazh * "h", tone)
   end

   if syllable in PINYIN_SYLLABIC_NASALS
      return LwomazhSyllable("", syllable * "h", syllable * "h", tone)
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

   pseudo_initial = if initial === "" && (startswith(final, "y") || startswith(final, "w"))
      final[1:1]
   elseif (initial === "g" || initial === "k") && startswith(final, "w")
      initial * "w"
   else
      initial
   end

   pseudo_final = if pseudo_initial === "kw" || pseudo_initial === "gw"
      final[2:end]
   elseif initial === "" && (startswith(final, "w") || (startswith(final, "y") && !startswith(final, "yu")))
      final[2:end]
   else
      final
   end

   LwomazhSyllable(
      get(PINYIN_INITIALS_TO_LWOMAZH, initial, initial),
      get(PINYIN_FINALS_TO_LWOMAZH, final, final),
      get(PINYIN_INITIALS_TO_LWOMAZH_FULL, initial, something(initial, "")) * get(PINYIN_FINALS_TO_LWOMAZH, final, final),
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
   "yut" => "eut"
])

function parse_jyutping(jyutping::String)::LoamaziSyllable
   syllable = jyutping[1:end-1]
   tone = parse(Int, jyutping[end:end])

   if syllable in JYUTPING_SYLLABIC_NASALS
      return LoamaziSyllable(syllable, "h", "", syllable * "h", tone)
   end

   initial_index = findfirst(i -> startswith(syllable, i), JYUTPING_INITIALS)
   initial = initial_index === nothing ? "" : JYUTPING_INITIALS[initial_index]

   (final, final_plosive) = begin
      remaining = syllable[length(default(initial, ""))+1:end]
      final_plosive = if any(p -> endswith(remaining, p), ["p", "t", "k"])
         remaining[end:end]
      else
         ""
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

   initial = get(JYUTPING_INITIALS_TO_LOAMAZI, initial, initial)
   initial_full = if initial == "ts/ch"
      if startswith("eu", final) || startswith("oe", final)
         "ch"
      else
         "ts"
      end
   elseif initial == "z/j"
      if startswith("eu", final) || startswith("oe", final)
         "j"
      else
         "z"
      end
   else
      initial
   end

   final = get(JYUTPING_FINALS_TO_LOAMAZI, final, final)

   LoamaziSyllable(initial, final, final_plosive, initial_full * final * final_plosive, tone)
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
      "mc" => Dict("initialMapping" => mc_initial_mapping, "finalMapping" => mc_final_mapping),
      "cm" => Dict("initialMapping" => cm_initial_mapping, "finalMapping" => cm_final_mapping)
   )
end