import * as log from "https://deno.land/std@0.116.0/log/mod.ts";

import { loadCharacters } from "./data/index.ts";
import { mapSyllables } from "./rimes.ts";
import { mapTones } from "./tones.ts";

log.info("Loading dataset...");
const characters = await loadCharacters();
log.info(`Loaded ${characters.length} characters`);

log.info("Creating tone mapping...");
const toneMapping = mapTones(characters);

log.info("Creating syllable mappings");
const syllableMappings = mapSyllables(characters);

log.info("Saving tone mapping...");
await Deno.mkdir("output", { recursive: true });
await Deno.writeTextFile("output/tones.json", JSON.stringify(toneMapping));

log.info("Saving syllable mappings...");
await Deno.writeTextFile("output/syllables.json", JSON.stringify(syllableMappings));

log.info("Done");
