ThisBuild / version := "0.1.0-SNAPSHOT"

ThisBuild / scalaVersion := "3.2.1"

lazy val root = (project in file("."))
   .settings(
      name := "Linguisteria",
      idePackagePrefix := Some("blue.mrk.linguisteria"),
      // https://mvnrepository.com/artifact/com.typesafe.play/play-json
      libraryDependencies += "com.typesafe.play" %% "play-json" % "2.10.0-RC7"
   )
