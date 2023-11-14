package main.scala

import scala.io.Source
import scala.io.StdIn
import util.control.Breaks._ // Scala 2.8+
import scala.collection.mutable.ArrayBuffer

import java.nio.file.Files
import java.nio.file.Paths
import sys.process._

// Makefile parser
object Parser {
    def main(args: Array[String]): Unit = {
        
        // TODO: While loop until having correct path instead of sys.exit(0)
        println("Enter the makefile path to execute")
        
        val makefileDir = Paths.get(StdIn.readLine())

        // Handles errors from the user input
        if (!Files.exists(makefileDir)) {
            println("The directory path given is unrecognized.")
            sys.exit(0)
        }

        val makefilePath = makefileDir.resolve("Makefile")
        if (!Files.exists(makefilePath)) {
            println("No Makefile found inside the path given.")
            sys.exit(0)
        }

        val bufferedSource = Source.fromFile(makefilePath.toString())
        val targets = ArrayBuffer[File]()
        val prerequisites = ArrayBuffer[File]()
        val commands = ArrayBuffer[String]()
        var isRuleContext = false
        var ruleSplitted: Array[String] = null
        var numberOfCmd = 0

        for ((line, index) <- bufferedSource.getLines.zipWithIndex) {
            if (line contains ":") {
                // A new rule has been detected. Create a rule and reset local variables.
                if (isRuleContext) {
                    // Rule.addRule(new Rule(targets.toList, prerequisites.toList, commands.toList))
                    Rule.updateRuleCache(targets.toList, prerequisites.toList, commands.toList)
                    // TODO: firstRule is either the first rule in the Makefile, either a specific target (need another user input)
                    if (Rule.getFirstRule().isEmpty) {
                        Rule.setFirstRule(new Rule(targets.toList, prerequisites.toList, commands.toList))
                    }
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
                    breakable {
                        for (itemHeader <- words) {
                            // Comment detected: the rest of the line is ignored.
                            if (itemHeader == "#") {
                                break
                            }
                            val filePath = makefilePath.resolve(itemHeader)
                            val fileExists = Files.exists(filePath)
                            // TODO: check if it's better to convert into millis (or alternatives..) for comparison.
                            val modifiedTime =  if (fileExists) Files.getLastModifiedTime(filePath) else null
                            if (i == 0) {
                                targets += File.getFileInstance(itemHeader, modifiedTime)
                            } else {
                                prerequisites += File.getFileInstance(itemHeader, modifiedTime)
                            }
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

        // Create the last rule.
        if (targets.nonEmpty) {
            Rule.updateRuleCache(targets.toList, prerequisites.toList, commands.toList)
        }

        bufferedSource.close()
        println("First rule : " + Rule.getFirstRule())

        // Rule.getFirstRule.map(rule => 
        //     // Parallelize the function below  for rule.dependencies.
            
        //     rule.dependencies.foreach(dependency => {
        //         // Get the rules related to this dependency
        //         var dependencyRules = Rule.getRuleInstance(dependency.name)
        //     //     if (!dependencyRules.isEmpty){
        //     //         dependencyRules.foreach(depRule => {

        //     //         })
        //     //         if (!r.commands.isEmpty){
        //     //             r.commands.foreach(cmd => {
        //     //                 var res = cmd !!
        //     //             })
        //     //         }
        //     //     }
        //     })
        // )

    }
}
