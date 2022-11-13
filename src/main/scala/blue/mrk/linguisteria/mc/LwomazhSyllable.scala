package blue.mrk.linguisteria
package mc

case class LwomazhSyllable(
   initial: String,
   initialPhoneme: Option[String],
   cInitial: String,
   rime: String,
   cRime: String,
   full: String,
   tone: Int
)

object LwomazhSyllable {
   private final val PinyinSyllablicFricatives = Map(
      ("zi", ("z", "z")),
      ("ci", ("ts", "z")),
      ("si", ("s", "z")),
      ("zhi", ("j", "r")),
      ("chi", ("ch", "r")),
      ("shi", ("sh", "r")),
      ("ri", ("r", "r"))
   )

   private final val PinyinSyllablicNasals = Set("n", "ng")

   private final val PinyinInitials = List(
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
   )

   private final val PinyinInitialsToLwomazhPhoneme = Map(
      ("j", "j"),
      ("q", "ch"),
      ("x", "sh"),
   )

   private final val PinyinNonNullInitialFinals = Map(
      ("i", "yi"),
      ("ie", "ye"),
      ("ia", "ya"),
      ("iu", "you"),
      ("iao", "yao"),
      ("in", "yin"),
      ("ian", "yan"),
      ("ing", "ying"),
      ("iong", "yong"),
      ("iang", "yang"),
      ("u", "wu"),
      ("o", "wo"),
      ("uo", "wo"),
      ("ua", "wa"),
      ("ui", "wei"),
      ("uai", "wai"),
      ("un", "wen"),
      ("uan", "wan"),
      ("uang", "wang"),
      ("u:", "yu"),
      ("u:e", "yue"),
      ("u:n", "yun"),
      ("u:an", "yuan"),
   )

   private final val PinyinFinals = Set(
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
   )

   private final val PinyinInitialsToLwomazh = Map(
      ("c", "ts"),
      ("zh", "j"),
      ("j", "jy-"),
      ("q", "chy-"),
      ("x", "shy-"),
   )

   private final val PinyinInitialsToLwomazhFull = Map(
      ("zh", "j"),
      ("q", "ch"),
      ("x", "sh"),
   )

   private final val PinyinRimesToLwomazh = Map(
      ("ao", "au"),
      ("yi", "i"),
      ("yao", "yau"),
      ("yin", "in"),
      ("ying", "ing"),
      ("wu", "u"),
      ("yu", "eu"),
      ("yun", "eun"),
      ("yuan", "yuen"),
      ("ng", "ngh"),
   )

   def parse(input: String): Option[LwomazhSyllable] =
      val syllable = input.substring(0, input.length - 1)
      val tone = input.substring(input.length - 1).toInt

      PinyinSyllablicFricatives.get(syllable).map { case (initial, rime) =>
         LwomazhSyllable(
            initial,
            initialPhoneme = Some(initial),
            cInitial = initial,
            rime,
            cRime = rime,
            full = if initial == rime then rime else initial + rime,
            tone,
         )
      }.orElse {
         if PinyinSyllablicNasals.contains(syllable) then
            Some(LwomazhSyllable(
               initial = syllable,
               initialPhoneme = Some(syllable),
               cInitial = syllable,
               rime = syllable + "h",
               cRime = syllable + "h",
               full = syllable + "h",
               tone = tone
            ))
         else None
      }.orElse {
         val initial = PinyinInitials.find(syllable.startsWith).getOrElse("")
         val rime = {
            val remaining = if initial == "" then syllable else syllable.substring(initial.length)

            if remaining.startsWith("u") && PinyinInitialsToLwomazhPhoneme.contains(initial) then
               PinyinNonNullInitialFinals.get(remaining.replace("u", "u:"))
            else
               PinyinNonNullInitialFinals.get(remaining).orElse(Some(remaining).filter(PinyinFinals.contains))
         }
         rime.map { rime =>
            val lwomazhInitial = PinyinInitialsToLwomazh.getOrElse(initial, initial)
            val lwomazhRime = PinyinRimesToLwomazh.getOrElse(rime, rime)
            val lwomazhFull = PinyinInitialsToLwomazhFull.getOrElse(initial, initial) +
               PinyinRimesToLwomazh.getOrElse(rime, rime)

            val (cInitial, cRime) = if (lwomazhRime(0) == 'y' || lwomazhRime(0) == 'w') && lwomazhInitial == "" then
               val glide = lwomazhRime.substring(0, 1)
               val rest = lwomazhRime.substring(1)
               (f"($glide)", f"($glide)$rest")
            else if lwomazhFull.startsWith("kw") || lwomazhFull.startsWith("gw") then
               val onset = lwomazhFull.substring(0, 2)
               val rest = lwomazhRime.substring(1)
               (f"($onset)", f"(w)$rest")
            else lwomazhFull match
               case "u" => ("(w)", "u")
               case "i" => ("(y)", "i")
               case _ => (lwomazhInitial, lwomazhRime)

            LwomazhSyllable(
               lwomazhInitial,
               PinyinInitialsToLwomazhPhoneme.get(initial),
               cInitial,
               lwomazhRime,
               cRime,
               lwomazhFull,
               tone
            )
         }
      }
}