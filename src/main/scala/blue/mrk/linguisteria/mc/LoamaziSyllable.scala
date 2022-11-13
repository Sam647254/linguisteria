package blue.mrk.linguisteria.mc

case class LoamaziSyllable(
   initial: String,
   rime: String,
   mRime: String, // Used to mark that kwang is kw-ang in Cantonese, but k-wang in Mandarin
   finalPlosive: String,
   full: String,
   tone: Int
)

object LoamaziSyllable {
   private final val JyutpingSyllableNasals = Set("m", "ng")
   private final val JyutpingInitials = Set(
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
   )
   private final val JyutpingInitialsToLoamazi = Map(
      ("c", "ts/ch"),
      ("j", "y"),
      ("z", "z/j"),
   )

   private final val JyutpingFinals = Set(
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
      "yut",
   )

   private val JyutpingFinalsToLoamazi = Map(
      ("aa", "a"),
      ("aai", "ai"),
      ("aau", "au"),
      ("aam", "am"),
      ("aan", "an"),
      ("aang", "ang"),
      ("aap", "ap"),
      ("aat", "at"),
      ("aak", "ak"),
      ("a", "ea"),
      ("ai", "eai"),
      ("au", "eau"),
      ("am", "eam"),
      ("an", "ean"),
      ("ang", "eang"),
      ("ap", "eap"),
      ("at", "eat"),
      ("ak", "eak"),
      ("e", "ae"),
      ("eu", "aeu"),
      ("em", "aem"),
      ("eng", "aeng"),
      ("ep", "aep"),
      ("ek", "aek"),
      ("o", "oa"),
      ("oi", "oai"),
      ("on", "oan"),
      ("ong", "oang"),
      ("ot", "oat"),
      ("ok", "oak"),
      ("ung", "ong"),
      ("ut", "ut"),
      ("uk", "ok"),
      ("eoi", "oei"),
      ("eon", "oen"),
      ("eot", "oet"),
      ("yu", "eu"),
      ("yun", "eun"),
      ("yut", "eut"),
      ("m", "mh"),
      ("ng", "ngh"),
   )

   def parse(input: String): Option[LoamaziSyllable] =
      val syllable = input.substring(0, input.length - 1)
      val tone = input.substring(input.length - 1).toInt

      if JyutpingSyllableNasals.contains(syllable) then
         return Some(LoamaziSyllable(
            initial = syllable,
            rime = syllable,
            mRime = syllable,
            finalPlosive = "",
            full = syllable,
            tone
         ))

      val initial = JyutpingInitials.find(syllable.startsWith).getOrElse("")
      {
         val remaining = syllable.substring(initial.length)
         val final_plosive = {
            val last = remaining.charAt(remaining.length - 1)
            if last == 'p' || last == 't' || last == 'k' then last.toString else ""
         }

         if JyutpingFinals.contains(remaining) then
            Some((remaining.substring(0, remaining.length - final_plosive.length)), final_plosive)
         else
            None
      }.map { case (rime, finalPlosive) =>
         val loamaziInitial = JyutpingInitialsToLoamazi.getOrElse(initial, initial)
         val frontRoundedVowel = rime.startsWith("yu") || rime.startsWith("oe")
         val normalizedInitial = (initial, frontRoundedVowel) match
            case ("ts/ch", true) => "ch"
            case ("ts/ch", false) => "ts"
            case ("z/j", true) => "j"
            case ("z/j", false) => "z"
            case _ => initial
         val loamaziRime = JyutpingFinalsToLoamazi.getOrElse(rime, rime)
         val mRime = initial match
            case "kw" | "gw" => "(w)" + rime
            case "w" if rime != "u" => "(w)" + rime
            case "j" if rime != "i" || rime != "yu" => "(y)" + rime
            case _ => rime

         LoamaziSyllable(
            initial = loamaziInitial,
            rime = loamaziRime,
            mRime = mRime,
            finalPlosive = finalPlosive,
            full = normalizedInitial + loamaziRime + finalPlosive,
            tone = tone
         )
      }
}