package blue.mrk.linguisteria

import play.api.libs.json.{JsValue, Json, Writes}

case class SyllableMapping(mc: SyllablePartMapping, cm: SyllablePartMapping)

object SyllableMapping:
   implicit val writes: Writes[SyllableMapping] = Json.writes[SyllableMapping]

case class SyllablePartMapping(initials: Map[String, SoundMapping], rimes: Map[String, SoundMapping])

object SyllablePartMapping:
   implicit val writes: Writes[SyllablePartMapping] = Json.writes[SyllablePartMapping]

type SoundMapping = Map[String, Seq[Char]]
implicit val soundMappingWrites: Writes[SoundMapping] = (o: SoundMapping) => Json.obj(
   o.toSeq.map { case (sound, value) =>
      (sound, Json.toJson(value.map(_.toString)))
   }:_*
)

case class ToneMapping(mc: Map[Int, Map[Int, Int]], cm: Map[Int, Map[Int, Int]])
implicit val toneMappingWrites: Writes[ToneMapping] = Json.writes[ToneMapping]

case class SyllableStats(mNoTones: SoundMapping, mTones: SoundMapping, cNoTones: SoundMapping, cTones: SoundMapping)

object SyllableStats:
   implicit val writes: Writes[SyllableStats] = Json.writes[SyllableStats]