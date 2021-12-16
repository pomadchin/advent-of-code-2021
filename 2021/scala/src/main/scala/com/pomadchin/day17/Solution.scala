package com.pomadchin.day17

import scala.io.Source

object Solution:

  def readInput(path: String = "src/main/resources/day17/puzzle1.txt"): Iterator[String] =
    Source.fromFile(path).getLines
