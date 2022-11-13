package mrk.blue.linguisteria
package blue.mrk.linguisteria.mc

import play.api.libs.json.{JsArray, JsBoolean, JsNull, JsNumber, JsObject, JsString, Json}

import scala.io.Source
import scala.util.{Try, Using}

object MC {
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

   def syllableMapping(chars: Seq[CharInfo]): Unit = ???

   def extractTones(): Unit = ???

   def createSyllableStats(): Unit = ???
}

@main def main(): Unit =
   val chars = MC.loadCharacters().get
   println(s"Loaded characters: ${chars.length}")