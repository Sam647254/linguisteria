package mrk.blue.linguisteria
package mc

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

   def parse(input: String): Option[LoamaziSyllable] =
      val syllable = input.substring(0, input.length - 1)
      val tone = input.substring(input.length - 1).toInt

      if JyutpingSyllableNasals.contains(syllable) then
         return Some(LoamaziSyllable(
            initial = syllable,
            rime = syllable + "h",
            mRime = syllable + "h",
            finalPlosive = "",
            full = syllable + "h",
            tone
         ))

      val initial = JyutpingInitials.find(syllable.startsWith)
      ???
}