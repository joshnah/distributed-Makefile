import org.apache.spark.{SparkConf, SparkContext}
import scala.collection.mutable.ArrayBuffer
import sys.process.Process
import org.apache.log4j.{Level, Logger}


import java.nio.file.Paths
import java.nio.file.Files


object Main {

    def main(args: Array[String]): Unit = {

        var parseArgs = args;
        var makefilePath = Paths.get("Makefile")
        var sparkMasterUrl: Option[String] = None
        var initialTargets = ArrayBuffer[String]()

        while (!parseArgs.isEmpty) {

            if (parseArgs(0) == "-f") {
                if (parseArgs.length < 2) {
                    Console.err.println("error: missing makefile path after -f argument")
                    sys.exit(1)
                }
                makefilePath = Paths.get(parseArgs(1))
                parseArgs = parseArgs.drop(2)
            } else if (parseArgs(0) == "-m") {
                if (parseArgs.length < 2) {
                    Console.err.println("error: missing spark master url after -m argument")
                    sys.exit(1)
                }
                sparkMasterUrl = Some(parseArgs(1))
                parseArgs = parseArgs.drop(2)
            } else if (parseArgs(0) == "-h") {
                println("usage: make [-h] [-f <makefile path>] [-m <spark master url>] [target...]")
                println()
                println("  -h                     print this help")
                println("  -f <makefile path>     specify the path to the makefile [default: Makefile]")
                println("  -m <spark master url>  specify the spark master url [default: spark disabled]")
                println("  target...              target names to run first [default: all]")
                sys.exit(0)
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

        val makefile = Makefile.parse(makefilePath)

        if (initialTargets.isEmpty) {
            if (makefile.targets.isEmpty || makefile.targets.find(t => t.name == "all").isDefined) {
                initialTargets = ArrayBuffer[String]("all")
            } else {
                initialTargets = ArrayBuffer[String](makefile.targets(0).name)
            }
        }

        // println(s"initial targets: ${initialTargets.mkString(", ")}")

        // println(s"targets (${makefile.targets.size}):")
        // for (target <- makefile.targets) {
        //     println(s"${target.name}: ${target.dependencies.mkString(" ")}")
        //     for (command <- target.commands) {
        //         println(s"    $command")
        //     }
        // }

        val scheduling = makefile.calc_scheduling(initialTargets.toArray)
        println(s"### Scheduling ${scheduling.length} in total ###")
        for (case (targets, index) <- scheduling.zipWithIndex) {
            println(s"Step $index: ${targets.map(_.name).mkString(", ")}\n")
        }
        println("### End Scheduling ###\n")

        println("### Run ###")
        val runDir = makefile.directory.toFile()
        def run(command: String) = {
            println(s"executing: $command")
            val exitCode = Process(Seq("bash", "-c", command), runDir).!
            if (exitCode != 0) {
                Console.err.println(s"error: command failed with exit code $exitCode: $command")
                sys.exit(1)
            }
        }

        sparkMasterUrl match {
            case Some(masterUrl) => {
                val conf = new SparkConf()
                    .setAppName("Spark Makefile")
                    .setMaster(masterUrl)
                    .set("spark.log.level", "ERROR")

                val sc = new SparkContext(conf)
                val startTime = System.currentTimeMillis()

                // iterate over scheduling and execute each target
                for (level <- scheduling) {
                    val rdd = sc.parallelize(level.map(_.commands)) // transmet all the commands of the level
                    rdd.foreach(commands => {
                        commands.foreach(run)
                    })
                    
                }
                // Record the end time
                val endTime = System.currentTimeMillis()

                // Calculate and print the execution time
                val executionTime = endTime - startTime
                println(s"Execution time: $executionTime milliseconds")
                sc.stop()

                println("### End Run ###\n")

            }
            case None => {

                for (level <- scheduling) {
                    for (target <- level) {
                        target.commands.foreach(run)
                    }
                }

            }
        }

    }

}
