include("../helpers.jl")

using Unicode

struct MandarinSyllable
   initial::Union{String, Nothing}
   final::String
end

function get_final(syllable::MandarinSyllable)::String
   default(syllable.glide, "") * syllable.nucleus * default(syllable.coda, "")
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

function parse_pinyin(pinyin::String)
   normalized = Unicode.normalize(pinyin) |> collect
   syllable = filter(isletter, normalized) |> String

   if syllable in PINYIN_SYLLABIC_FRICATIVES
      return MandarinSyllable(syllable[1:end-1], "_")
   end

   initial = PINYIN_INITIALS[findfirst(i -> startswith(syllable, i), PINYIN_INITIALS)]
   
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

   MandarinSyllable(initial, final)
end