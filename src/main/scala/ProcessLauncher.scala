import sys.process._

object ProcessLauncher {
  /**
   * Sequential process launcher
   * @param commands list of string to execute
   */
  def execute(commands: Seq[String]): Unit = {
    commands.foreach { command =>
        val exitCode = command.!
        if (exitCode != 0) {
            throw new RuntimeException(s"command '$command' failed with the exited code: $exitCode")
            sys.exit(1)
        }
    }
  }
}
