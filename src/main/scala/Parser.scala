package main.scala

import scala.io.Source
import scala.io.StdIn
import util.control.Breaks._ // Scala 2.8+
import scala.collection.mutable.ArrayBuffer

import java.nio.file._;

// Makefile parser
object Parser {
    def main(args: Array[String]) = {
        println("Enter the makefile path to execute")
        val makefilePath = readLine()
        // Handles errors from the user input
        if (!Files.exists(Paths.get(makefilePath))) {
            println("The path given is unrecognized.")
            sys.exit(0)
        }
        val usefulChar = if (makefilePath.last == '/') null else '/'
        val makeSuffix = usefulChar + "Makefile"
        if (!Files.exists(Paths.get(makefilePath + makeSuffix))) {
            println("No Makefile found inside the path given.")
            sys.exit(0)
        }

        val bufferedSource = Source.fromFile(makefilePath + makeSuffix)
        val targets = ArrayBuffer[File]()
        val prerequisites = ArrayBuffer[File]()
        val commands = ArrayBuffer[String]()
        var isRuleContext = false
        var ruleSplitted: Array[String] = null
        var numberOfCmd = 0

        breakable {
            for ((line, index) <- bufferedSource.getLines.zipWithIndex) {
                if (line contains ":") {
                    // A new rule has been detected. Create a rule and reset local variables.
                    if (isRuleContext) {
                        new Rule(targets.toList, prerequisites.toList, commands.toList)
                        targets.clear()
                        prerequisites.clear()
                        commands.clear()
                        numberOfCmd = 0
                    }
                    isRuleContext = true
                    ruleSplitted = line.split(":", 2)
                    // 0 is for the targets and 1 for the prerequisites/dependencies
                    for (i <- 0 to 1) {
                        var words = ruleSplitted(i).split("\\s+").filter(_.nonEmpty)
                        for (itemHeader <- words) {
                            // Comment detected: the rest of the line is ignored.
                            if (itemHeader == "#") {
                                break
                            }
                            val filePath = makefilePath+usefulChar+itemHeader
                            val fileExists = Files.exists(Paths.get(filePath))
                            // TODO: check if it's better to convert into millis (or alternatives..) for comparison.
                            val modified =  if (fileExists) Files.getLastModifiedTime(Paths.get(filePath)) else null
                            if (i == 0) {
                                targets += new File(itemHeader, modified)
                            } else {
                                prerequisites += new File(itemHeader, modified)
                            }
                        }
                    }
                } else {
                    // Found a command before a target. Stop the parsing.
                    if (!isRuleContext) {
                        println(s"makefile:${index+1}: *** commands commence before first target. Stop.")
                        sys.exit(0)
                    }
                    // A command has been detected.
                    if (!line.isEmpty && line.charAt(0) == '\t') {
                        commands += line.substring(1)
                        numberOfCmd += 1
                    }
                }
            }
        }
        // Create the last rule.
        if (targets.nonEmpty) {
            new Rule(targets.toList, prerequisites.toList, commands.toList)
        }
        bufferedSource.close
    }
}
