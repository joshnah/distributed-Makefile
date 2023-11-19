import org.apache.spark.{SparkConf, SparkContext}

object DAGExample {
  def compileTask(
      task: (String, Seq[String]),
      completedTargets: Set[String]
  ): (String, Boolean) = {
    val (target, dependencies) = task
    println(
      s"Compiling $target with dependencies ${dependencies.mkString(", ")}"
    )

    // compilation logic

    // Return a tuple with target and a boolean indicating successful compilation
    (target, true)
  }

  def cleanupTask: ((String, Boolean)) => Unit = { case (target, success) =>
    println(s"Cleaning up after compilation of $target")
  }

  // Check if a task can be submitted for compilation
  def submitTask(
      task: (String, Seq[String]),
      completedTargets: Set[String]
  ): Boolean = {
    val (target, dependencies) = task
    target.nonEmpty && !completedTargets.contains(target) && dependencies
      .forall(completedTargets.contains)
  }

  def main(args: Array[String]): Unit = {
    val conf = new SparkConf().setAppName("DAGExample")
    val sc = new SparkContext(conf)

    var tasks: Seq[(String, Seq[String])] = Seq(
      ("B", Seq()),
      ("A", Seq("B")),
      ("C", Seq("A", "B"))
    )

    var completedTargets = Set[String]()

    var continueLoop = true
    while (tasks.nonEmpty && continueLoop) {
      // Create an RDD from remaining tasks
      val remainingTasksRDD = sc.parallelize(tasks)

      // Filter tasks that can be submitted (dependencies are completed)
      val tasksToSubmit = remainingTasksRDD
        .filter(task => submitTask(task, completedTargets))
        .collect()

      // If no tasks can be submitted, exit the loop
      if (tasksToSubmit.isEmpty) {
        continueLoop = false
      } else {
        // Execute the compilation tasks using Spark transformations
        val compiledResults = sc
          .parallelize(tasksToSubmit)
          .map(task => compileTask(task, completedTargets))

        // Collect data once
        val collectedResults = compiledResults.collect()
        // display collected results
        println("Collected results:")
        collectedResults.foreach(println)

        // Add completed targets to the set
        completedTargets ++= collectedResults.filter(_._2).map(_._1)

        // Cleanup completed tasks
        collectedResults.foreach(cleanupTask)
      }
    }

    // Stop the SparkContext
    sc.stop()
  }
}
