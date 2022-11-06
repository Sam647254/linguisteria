package mrk.blue.linguisteria
package mc

case class LoamaziSyllable(
   initial: String,
   rime: String,
   mRime: String, // Used to mark that kwang is kw-ang in Cantonese, but k-wang in Mandarin
   full: String,
   tone: Int
)

object LoamaziSyllable {
   def parse(input: String): Option[LoamaziSyllable] = ???
}