package blue.mrk.linguisteria
package mc

import play.api.libs.json.{JsArray, JsBoolean, JsNull, JsNumber, JsObject, JsString, Json}

import java.io.FileWriter
import scala.io.Source
import scala.util.{Try, Using}

object MC:
   private final val PinyinEntryRegex = "^([A-Z0-9]+) \\((.*)\\)$".r
   private final val CharRegex = "(\\p{sc=Han})".r
   private final val JyutpingRegex = "([a-z]+[0-9])".r

   def loadCharacters(): Try[Seq[CharInfo]] =
      for
         tChars <- Using(Source.fromFile("data/traditional.txt")) { file =>
            file.getLines().map { line =>
               val parts = line.split(' ')
               (parts(2), parts(3))
            }.toSeq
         }

         pinyinDict <- Using(Source.fromFile("data/unicode_to_hanyu_pinyin.txt")) { file =>
            file.getLines().map {
               case PinyinEntryRegex(unicode, pinyin) => (unicode, pinyin.split(','))
            }.toMap
         }

         jyutping <- Using(Source.fromFile("data/chars_to_jyutping.json")) { file =>
            val json = Json.parse(file.mkString)
            json.as[JsObject].value.toSeq.flatMap { case (entry, jyutping) =>
               CharRegex.findAllIn(entry).zip(JyutpingRegex.findAllIn(jyutping.as[String]))
            }.groupMap(_._1)(_._2)
         }

      yield tChars.map { case (tUnicode, tChar) =>
         val mandarin = pinyinDict(tUnicode.toUpperCase).map(LwomazhSyllable.parse(_).get)
         val cantonese = jyutping(tChar).map { jp => LoamaziSyllable.parse(jp).getOrElse { throw IllegalArgumentException(jp) } }
         CharInfo(tChar(0), mandarin, cantonese)
      }

   def createSyllableMapping(chars: Seq[CharInfo]): SyllableMapping =
      val monophones = extractMonophones(chars)

      val mcInitialMapping = monophones.groupMap(_.mandarin.head.initial)(identity)
         .map { case (mInitial, cChars) => (mInitial, cChars.groupMap(_.cantonese.head.initial)(_.character)) }
      val mcRimeMapping = monophones.groupMap(_.mandarin.head.rime)(identity)
         .map { case (mInitial, cChars) => (mInitial, cChars.groupMap(_.cantonese.head.mRime)(_.character)) }
      val cmInitialMapping = monophones.groupMap(_.cantonese.head.rime)(identity)
         .map { case (mInitial, mChars) => (mInitial, mChars.groupMap(_.mandarin.head.cInitial)(_.character)) }
      val cmRimeMapping = monophones.groupMap(_.cantonese.head.rime)(identity)
         .map { case (mInitial, mChars) => (mInitial, mChars.groupMap(_.mandarin.head.cRime)(_.character)) }

      SyllableMapping(
         mc = SyllablePartMapping(mcInitialMapping, mcRimeMapping),
         cm = SyllablePartMapping(cmInitialMapping, cmRimeMapping),
      )

   def createToneMapping(chars: Seq[CharInfo]): ToneMapping =
      val monophones = extractMonophones(chars)
      val mc = monophones.groupMap(_.mandarin.head.tone)(_.cantonese.head.tone).map { case (mTone, cTones) =>
         (mTone, cTones.groupMapReduce(identity)(_ => 1)(_ + _))
      }
      val cm = monophones.groupMap(_.cantonese.head.tone)(_.mandarin.head.tone).map { case (cTone, mTones) =>
         (cTone, mTones.groupMapReduce(identity)(_ => 1)(_ + _))
      }
      ToneMapping(mc, cm)

   def createSyllableStats(chars: Seq[CharInfo]): SyllableStats =
      val mNoTones = chars.flatMap { c => c.mandarin.map((_, c.character)) }.groupMap(_._1.full)(_._2)
         .map { case (syllable, chars) => (syllable, chars.distinct) }
      val mTones = chars.flatMap { c => c.mandarin.map((_, c.character)) }
         .groupMap { case (syllable, char) => syllable.full + syllable.tone }(_._2)

      val cNoTones = chars.flatMap { c => c.cantonese.map((_, c.character)) }.groupMap(_._1.full)(_._2)
         .map { case (syllable, chars) => (syllable, chars.distinct) }
      val cTones = chars.flatMap { c => c.cantonese.map((_, c.character)) }
         .groupMap { case (syllable, char) => syllable.full + syllable.tone }(_._2)
      SyllableStats(mNoTones, mTones, cNoTones, cTones)

   private def extractMonophones(chars: Seq[CharInfo]) =
      chars.filter { c => c.mandarin.length == 1 || c.cantonese.length == 1 }

@main def main(): Unit =
   val chars = MC.loadCharacters().get
   println(s"Loaded characters: ${chars.length}")

   Using(new FileWriter("output/syllables.json")) { writer =>
      writer.write(Json.toJson(MC.createSyllableMapping(chars)).toString)
   }.get

   Using(new FileWriter("output/tones.json")) { writer =>
      writer.write(Json.toJson(MC.createToneMapping(chars)).toString)
   }.get

   Using(new FileWriter("output/stats.json")) { writer =>
      writer.write(Json.toJson(MC.createSyllableStats(chars)).toString)
   }.get