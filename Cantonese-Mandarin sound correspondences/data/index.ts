import { dirname, fromFileUrl, join } from "https://deno.land/std@0.116.0/path/mod.ts";
import { mapNotNullish } from "https://deno.land/std@0.116.0/collections/mod.ts";

const SC_ENTRY_REGEX = /^.*\[\[(.*)\]\]<\/span>\|\|(.*)$/gm;
const DIRNAME = dirname(fromFileUrl(import.meta.url));
const SC_PATH = join(DIRNAME, "simplified.txt");
const ST_PATH = join(DIRNAME, "STCharacters.txt");
const JP_PATH = join(DIRNAME, "./chars_to_jyutping.json");

interface PinyinChar {
   mc: string;
   pinyin: string[];
}

export interface PJChar {
   character: string;
   pinyin: string[];
   jyutping: string;
}

export async function loadCharacters(): Promise<PJChar[]> {
   const sc = (await Deno.readTextFile(SC_PATH)).split("\n");
   const sChars = mapNotNullish(sc, (line): PinyinChar | undefined => {
      const matches = SC_ENTRY_REGEX.exec(line);
      if (matches != null) {
         return {
            mc: matches[1],
            pinyin: matches[2].split(", "),
         };
      }
   });

   const sToT = (await Deno.readTextFile(ST_PATH)).split("\n");

   const stDict: Record<string, string[]> = Object.fromEntries(mapNotNullish(sToT, (line) => {
      const [simplified, traditional] = line.split("\t");
      if (traditional == null) {
         return null;
      }
      return [simplified, traditional.split(" ")];
   }));

   const tChars: PinyinChar[] = sChars.flatMap((mc) => {
      const traditional = stDict[mc.mc] ?? [mc.mc];
      return traditional.map((t) => ({
         mc: t,
         pinyin: mc.pinyin,
      }));
   });

   const jyutping = JSON.parse(await Deno.readTextFile(JP_PATH));

   return tChars.map((tc): PJChar => {
      const jp = jyutping[tc.mc];
      return {
         character: tc.mc,
         pinyin: tc.pinyin,
         jyutping: jp,
      };
   });
}
