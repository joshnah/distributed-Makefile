import org.apache.spark.{SparkConf, SparkContext, TaskContext}
import org.apache.log4j.{Level, Logger}

import scala.collection.mutable.ArrayBuffer
import sys.process.Process

import java.nio.file.Paths
import java.nio.file.Files
import java.io.ByteArrayOutputStream
import java.io.{PrintWriter, File}
import scala.sys.process.ProcessLogger


object Main {

    def main(args: Array[String]): Unit = {

        var parseArgs = args;
        var makefilePath = Paths.get("Makefile")
        var sparkMasterUrl: Option[String] = None
        var initialTargets = ArrayBuffer[String]()
        var startTime: Long = 0
        var endTime: Long = 0
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
        startTime =  System.currentTimeMillis()
        val scheduling = makefile.calc_scheduling(initialTargets.toArray)
        endTime = System.currentTimeMillis()
        val schedulingTime = (endTime - startTime) 
        println(s"### Scheduling time: $schedulingTime miliseconds ###")
        println(s"### Scheduling ${scheduling.length} in total ###\n")
        // for (case (targets, index) <- scheduling.zipWithIndex) {
            //     println(s"Step $index: ${targets.map(_.name).mkString(", ")}\n")
        // }
        // println("### End Scheduling ###\n")

        println("### Run ###")

        val runDir = makefile.directory.toFile()
        def run(command: String) = {
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
                    .set("spark.task.maxFailures", "1")
                    .set("spark.locality.wait", "0")
                    .set("spark.scheduler.mode", "FAIR")
                    .set("spark.dynamicAllocation.enabled", "true")
                    .set("spark.dynamicAllocation.minExecutors", "1")
                    .set("spark.dynamicAllocation.maxExecutors", "100")
                    .set("spark.dynamicAllocation.initialExecutors", "1")
                    .set("spark.dynamicAllocation.executorIdleTimeout", "60s")
                    .set("spark.dynamicAllocation.cachedExecutorIdleTimeout", "60s")
                    .set("spark.dynamicAllocation.sustainedSchedulerBacklogTimeout", "60s")
                    .set("spark.dynamicAllocation.shuffleTracking.enabled", "true")
                    
                    val driverCtx = new SparkContext(conf)
                // Logs coming from all drivers.
                class Log(val id: Long, val command: Boolean, val content: String) extends Serializable
                val logs = driverCtx.collectionAccumulator[Log]("Logs")

                startTime = System.currentTimeMillis()

                // iterate over scheduling and execute each target
                for (case (level, index) <- scheduling.zipWithIndex) {

                    println(s"Parallelizing ${level.length} targets") 
                    val rdd = driverCtx.parallelize(level.map(_.commands)).repartition(100)// transmet all the commands of the level
                    
                    println(s"Number of partitions: ${rdd.getNumPartitions}")
                    val future = rdd.foreachAsync(commands => {

                        val taskCtx = TaskContext.get()
                        val id = taskCtx.taskAttemptId()
                        
                        commands.foreach(command => {

                            val stream = new ByteArrayOutputStream
                            val writer = new PrintWriter(stream)
                            val logger = ProcessLogger(writer.println, writer.println)


                            val exitCode = Process(Seq("bash", "-c", command), runDir).!(logger)
                            println(s"### Command $command finished ###\n")
                            if (exitCode != 0) {
                                writer.close()
                                logs.add(new Log(id, true, command))
                                logs.add(new Log(-1, false, "ERROR: command failed with exit code " + exitCode + "\n"+  stream.toString()))
                                // sys.exit(1)
                            }
                            

                            writer.close()
                            // logs.add(new Log(id, false, stream.toString()))
                            
                        })
                    })

                    var i = 0;
                    while (!future.isCompleted) {
                        while (i < logs.value.size) {
                            val log = logs.value.get(i);
                            // If fail, stop the execution
                            if (log.id == -1) {
                                println(s"${log.content.strip()}")
                                driverCtx.cancelAllJobs()
                                driverCtx.stop()
                                sys.exit(1)
                            } 
                            println(s"${log.content.strip()}")
                            i += 1;
                        }
                    }
                    logs.reset()
                    println(s"### Level $index finished ###\n")
                }

                // Record the end time
                endTime = System.currentTimeMillis()

                // Calculate and print the execution time
                val executionTime = endTime - startTime
                println(s"### Execution time: $executionTime milliseconds ###")

                // write the execution time in a file
                val filePath = "executionTime.txt"
                val executionTimeFile = new File(filePath)

                val writer = new PrintWriter(executionTimeFile)
                writer.write(s"$schedulingTime\n")
                writer.write(s"$executionTime\n")
                writer.close()
                
                driverCtx.stop()

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

