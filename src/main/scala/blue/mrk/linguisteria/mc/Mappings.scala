package blue.mrk.linguisteria
package mc

case class SyllableMapping(mc: SyllablePartMapping, cm: SyllablePartMapping)

case class SyllablePartMapping(initials: Map[String, SoundMapping], rimes: Map[String, SoundMapping])

type SoundMapping = Map[String, Seq[Char]]

case class ToneMapping(mc: Map[Int, Map[Int, Int]], cm: Map[Int, Map[Int, Int]])

case class SyllableStats(mNoTones: SoundMapping, mTones: SoundMapping, cNoTones: SoundMapping, cTones: SoundMapping)