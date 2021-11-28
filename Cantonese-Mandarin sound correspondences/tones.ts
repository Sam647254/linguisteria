import { groupBy, mapEntries, mapValues } from "https://deno.land/std@0.116.0/collections/mod.ts";
import { PJChar } from "./data/index.ts";

export interface ToneMapping {
   mandarinToCantonese: Record<string, Record<string, string[]>>;
   cantoneseToMandarin: Record<string, Record<string, string[]>>;
}

interface PJTonesChar {
   character: string;
   mandarinTones: string[];
   cantoneseTone: string;
}

const CANTONESE_TONE_REGEX = new RegExp(".*([0-9]).*");
const MANDARIN_TONES = ["\u0304", "\u0301", "\u030C", "\u0300"];

export function mapTones(characters: PJChar[]): ToneMapping {
   const toneChars = characters.map(
      ({ character, pinyin, jyutping }): PJTonesChar => {
         const cantoneseTone = (CANTONESE_TONE_REGEX.exec(jyutping) ?? [])[1];
         const mandarinTones = pinyin.map((py) => {
            const normalized = py.normalize("NFD");
            return (MANDARIN_TONES.findIndex((tone) => normalized.indexOf(tone) >= 0) + 1)
               .toString();
         });

         return {
            character,
            mandarinTones,
            cantoneseTone,
         };
      },
   );

   const monophones = toneChars.filter((c) => c.mandarinTones.length === 1);

   const mandarinTones = groupBy(monophones, (c) => c.mandarinTones[0]);
   const mandarinToCantonese = mapEntries(mandarinTones, (entry) => {
      const [mandarinTone, characters] = entry;
      const matchingCharacters = groupBy(characters, (c) => c.cantoneseTone);
      return [
         mandarinTone,
         mapValues(matchingCharacters, (entry) => entry.map((c) => c.character)),
      ];
   });

   const cantoneseTones = groupBy(monophones, (c) => c.cantoneseTone);
   const cantoneseToMandarin = mapEntries(cantoneseTones, (entry) => {
      const [cantoneseTone, characters] = entry;
      const matchingCharacters = groupBy(characters, (c) => c.mandarinTones[0]);
      return [
         cantoneseTone,
         mapValues(matchingCharacters, (entry) => entry.map((c) => c.character)),
      ];
   });

   return {
      mandarinToCantonese,
      cantoneseToMandarin,
   };
}
