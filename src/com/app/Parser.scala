package com.app

import scala.io.Source
import util.control.Breaks._ // Scala 2.8+
import scala.collection.mutable.ArrayBuffer
import com.classes.Rule

object Parser {
    def main(args: Array[String]) = {
        val bufferedSource = Source.fromFile("makefiles/matrix/Makefile")
        val targets = ArrayBuffer[String]()
        val prerequisites = ArrayBuffer[String]()
        val commands = ArrayBuffer[String]()
        var isRuleContext = false
        var ruleSplitted: Array[String] = null
        var numberOfCmd = 0

        breakable {
            for ((line, index) <- bufferedSource.getLines.zipWithIndex) {
                if (line contains ":") {
                    isRuleContext = true
                    // A new rule header has been detected. Create a rule and reset local variables.
                    if (numberOfCmd > 0) {
                        new Rule(targets.toList, prerequisites.toList, commands.toList)
                        targets.clear()
                        prerequisites.clear()
                        numberOfCmd = 0
                    }
                    ruleSplitted = line.split(":", 2)
                    // 0 is for the targets and 1 for the prerequisites/dependencies
                    for (i <- 0 to 1) {
                        var words = ruleSplitted(i).split("\\s+").filter(_.nonEmpty)
                        for (itemHeader <- words) {
                            // Comment detected: the rest of the line is ignored.
                            if (itemHeader == "#") {
                                break
                            }
                            if (i == 0) {
                                targets += itemHeader
                            } else {
                                prerequisites += itemHeader
                            }
                        }
                    }
                } else {
                    if (!isRuleContext) {
                        println(s"makefile:${index+1}: *** commands commence before first target. Stop.")
                        break
                    }
                    if (!line.isEmpty && line.charAt(0) == '\t') {
                        // Remove the tab and add the command to the list
                        commands += line.substring(1)
                        numberOfCmd += 1
                    }

                }
            }
        }

        bufferedSource.close
    }
}
