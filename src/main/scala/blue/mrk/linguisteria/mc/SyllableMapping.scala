package mrk.blue.linguisteria
package blue.mrk.linguisteria.mc

case class SyllableMapping(mc: SyllablePartMapping, cm: SyllablePartMapping)

case class SyllablePartMapping(initials: Map[String, SoundMapping], rimes: Map[String, SoundMapping])

type SoundMapping = Map[String, Set[String]]