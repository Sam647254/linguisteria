import { groupBy, mapEntries } from "https://deno.land/std@0.116.0/collections/mod.ts";
import { PJChar } from "./data/index.ts";

const PINYIN_SYLLABIC_FRICATIVES = [
   "zi",
   "ci",
   "si",
   "zhi",
   "chi",
   "shi",
   "ri",
];

const PINYIN_INITIALS = [
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
   "h",
];

const PINYIN_FINALS = [
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
   "yuan",
];

const PINYIN_NONNULL_INITIAL_FINALS: Record<string, string> = {
   "i": "yi",
   "ie": "ye",
   "ia": "ya",
   "iu": "you",
   "iao": "yao",
   "in": "yin",
   "ian": "yan",
   "ing": "ying",
   "iong": "yong",
   "iang": "yang",
   "u": "wu",
   "o": "wo",
   "uo": "wo",
   "ua": "wa",
   "ui": "wei",
   "uai": "wai",
   "un": "wen",
   "uan": "wan",
   "uang": "wang",
   "ü": "yu",
   "üe": "yue",
   "ün": "yun",
   "üan": "yuan",
};

export interface PinyinSyllable {
   initial?: string;
   final: string;
   full: string;
}

function parsePinyin(pinyin: string): PinyinSyllable {
   const normalized = pinyin.normalize("NFD").split("").filter((l) => l.match(/[a-z\u0308]/g))
      .join("")
      .normalize("NFC");

   if (PINYIN_SYLLABIC_FRICATIVES.indexOf(normalized) >= 0) {
      return {
         initial: normalized.substring(0, normalized.length - 1),
         final: "_",
         full: normalized,
      };
   }

   const initial = PINYIN_INITIALS.find((i) => normalized.startsWith(i));

   const final = (() => {
      const remaining = initial == null ? normalized : normalized.substring(initial.length);

      if (remaining.startsWith("u") && ["j", "q", "x"].indexOf(initial ?? "") >= 0) {
         return PINYIN_NONNULL_INITIAL_FINALS[remaining.replace("u", "ü")];
      } else if (Object.hasOwn(PINYIN_NONNULL_INITIAL_FINALS, remaining)) {
         return PINYIN_NONNULL_INITIAL_FINALS[remaining];
      } else if (PINYIN_FINALS.indexOf(remaining) >= 0) {
         return remaining;
      }

      return null;
   })();

   if (final == null) {
      throw new Error(`Invalid pinyin: ${pinyin}`);
   }

   const pseudoInitial = (() => {
      if ((initial == "k" || initial == "g") && (final.startsWith("w") || final.startsWith("u"))) {
         return initial + "w";
      }

      if (initial == null && (final.startsWith("w") || final.startsWith("y"))) {
         return final.substr(0, final.startsWith("yu") ? 2 : 1);
      }
   })();

   return {
      initial: pseudoInitial ?? initial,
      final,
      full: normalized,
   };
}

export interface JyutpingSyllable {
   initial?: string;
   final: string;
   finalPlosive?: string;
   full: string;
}

const JYUTPING_SYLLABIC_NASALS = ["m", "ng"];

const JYUTPING_INITIALS = [
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
   "h",
];

const JYUTPING_FINALS = [
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
   "yut",
];

function parseJyutping(jyutping: string): JyutpingSyllable {
   const syllable = jyutping.split("").filter((c) => c.toUpperCase() != c.toLowerCase()).join("");
   if (JYUTPING_SYLLABIC_NASALS.indexOf(syllable) >= 0) {
      return {
         initial: syllable,
         final: syllable,
         full: syllable,
      };
   }

   const initial = JYUTPING_INITIALS.find((i) => syllable.startsWith(i));

   const { final, finalPlosive } = (() => {
      const remaining = syllable.substring(initial?.length ?? 0);
      const finalPlosive = ["p", "t", "k"].find((p) => remaining.endsWith(p));
      if (JYUTPING_FINALS.indexOf(remaining) >= 0) {
         return {
            final: remaining.substring(0, remaining.length - (finalPlosive?.length ?? 0)),
            finalPlosive,
         };
      }
      return {};
   })();

   const finalWithOnset = initial === "j" || initial === "w" ? initial + final : null;

   if (final == null) {
      throw new Error(`Invalid jyutping: ${jyutping}`);
   } else {
      return {
         initial,
         final: finalWithOnset ?? final,
         finalPlosive,
         full: syllable,
      };
   }
}

type PartMapping = Record<string, Record<string, string[]>>;

export interface SyllableMapping {
   initialMapping: PartMapping;
   finalMapping: PartMapping;
}

export interface BidirectionalSyllableMapping {
   mc: SyllableMapping;
   cm: SyllableMapping;
}

interface ParsedCharacter {
   character: string;
   pinyin: PinyinSyllable;
   jyutping: JyutpingSyllable;
}

function groupPart(
   characters: ParsedCharacter[],
   key: "pinyin" | "jyutping",
   part: "initial" | "final",
): PartMapping {
   const outer = groupBy(characters, (c) => c[key][part] ?? "");
   return mapEntries(outer, (entry) => {
      const [syllablePart, characters] = entry;
      const groups = groupBy(
         characters,
         (c) => c[key === "pinyin" ? "jyutping" : "pinyin"][part] ?? "",
      );
      const inner = mapEntries(groups, (entry) => [entry[0], entry[1].map((c) => c.character)]);
      return [syllablePart, inner];
   });
}

export function mapSyllables(characters: PJChar[]): BidirectionalSyllableMapping {
   const monophones = characters.filter((c) => c.pinyin.length === 1);
   const syllableCharacters = monophones.map((c): ParsedCharacter => ({
      character: c.character,
      pinyin: parsePinyin(c.pinyin[0]),
      jyutping: parseJyutping(c.jyutping),
   }));

   return {
      mc: {
         initialMapping: groupPart(syllableCharacters, "pinyin", "initial"),
         finalMapping: groupPart(syllableCharacters, "pinyin", "final"),
      },
      cm: {
         initialMapping: groupPart(syllableCharacters, "jyutping", "initial"),
         finalMapping: groupPart(syllableCharacters, "jyutping", "final"),
      },
   };
}
