import scala.collection.mutable.ArrayBuffer
import org.apache.spark.{SparkConf, SparkContext}
import sys.process._

import java.nio.file.Paths
import java.nio.file.Files


object Main {

    def main(args: Array[String]): Unit = {
        val conf = new SparkConf().setAppName("Theo's Spark Makefile")
        val sc = new SparkContext(conf)

        var parseArgs = args;
        var makefilePath = Paths.get("Makefile")
        var initialTargets = ArrayBuffer[String]()

        while (!parseArgs.isEmpty) {

            if (parseArgs(0) == "-f") {
                if (parseArgs.length < 2) {
                    Console.err.println("error: missing makefile path after -f argument")
                    sys.exit(1)
                }
                makefilePath = Paths.get(parseArgs(1))
                parseArgs = parseArgs.drop(2)
            } else if (parseArgs(0).startsWith("-")) {
                Console.err.println(s"error: unknown argument: ${parseArgs(0)}")
                sys.exit(1)
            } else {
                initialTargets += parseArgs(0)
                parseArgs = parseArgs.drop(1)
            }

        }

        if (!Files.isRegularFile(makefilePath)) {
            Console.err.println(s"error: makefile not found at: $makefilePath")
            sys.exit(1)
        }

        if (initialTargets.isEmpty) {
            initialTargets = ArrayBuffer[String]("all")
        }

        val makefile = Makefile.parse(makefilePath)

        println(s"initial targets: ${initialTargets.mkString(", ")}")

        // println(s"targets (${makefile.targets.size}):")
        // for (target <- makefile.targets) {
        //     println(s"${target.name}: ${target.dependencies.mkString(" ")}")
        //     for (command <- target.commands) {
        //         println(s"    $command")
        //     }
        // }

        val scheduling = makefile.calc_scheduling(initialTargets.toArray)
        println(s"scheduling (${scheduling.length}):")
        for (case (targets, index) <- scheduling.zipWithIndex) {
            println(s"#$index: ${targets.map(_.name).mkString(", ")}")
        }

        // iterate over scheduling and execute each target
        for (level <- scheduling) {
            val rdd = sc.parallelize(level.map(_.commands)) // transmet all the commands of the level
            rdd.foreach((commands)=> {
                commands.foreach((command)=> {
                    val exitCode = command.!
                    if (exitCode != 0) {
                        throw new RuntimeException(s"command '$command' failed with the exited code: $exitCode")
                        sys.exit(1)
                    }
                })
            })
            
        }
        // Loop forever to keep the Spark context alive so the web UI is alive.
        while (true){}

    }

}
