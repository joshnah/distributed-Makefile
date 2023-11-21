import scala.collection.mutable.ArrayBuffer

import java.nio.file.Paths
import java.nio.file.Files


object Main {

    def main(args: Array[String]): Unit = {

        var parseArgs = args;
        var makefilePath = Paths.get("Makefile")
        var targets = ArrayBuffer[String]()

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
                targets += parseArgs(0)
                parseArgs = parseArgs.drop(1)
            }

        }

        if (!Files.isRegularFile(makefilePath)) {
            Console.err.println(s"error: makefile not found at: $makefilePath")
            sys.exit(1)
        }

        val makefile = Makefile.parse(makefilePath)

        println(s"initial targets: ${targets.mkString(", ")}")
        println(s"targets (${makefile.targets.size}):")
        for (case (name, target) <- makefile.targets) {
            println(s"$name: ${target.dependencies.mkString(" ")}")
            for (command <- target.commands) {
                println(s"    $command")
            }
        }

    }

}
