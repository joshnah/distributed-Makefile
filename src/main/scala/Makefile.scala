import scala.collection.mutable.ArrayBuffer
import scala.collection.mutable
import scala.io.Source

import java.nio.file.Path


class Target(val dependencies: Array[String], val commands: Array[String])

class Makefile(val targets: Map[String, Target]) {

}

object Makefile {

    def parse(file: Path): Makefile = {

        class ParserTarget(
            var name: String,
            var dependencies: Array[String],
            var commands: ArrayBuffer[String] = new ArrayBuffer,
        )

        class ParserState(
            var target: Option[ParserTarget] = None,
            var targets: mutable.Map[String, Target] = mutable.Map()
        )

        val state = Source.fromFile(file.toUri())
            .getLines
            .zipWithIndex
            .map { case (line, index) => (line.stripTrailing(), index) }
            .filter { case (line, index) => !line.isEmpty() && !line.startsWith("#") }
            .foldLeft(new ParserState) { case (state, (line, index)) =>

                if (line(0).isWhitespace) {
                    state.target match {
                        case Some(target) => {
                            target.commands += line.stripLeading()
                        }
                        case None => throw new RuntimeException("missing target")
                    }
                } else {

                    state.target.map { target => 
                        state.targets(target.name) = new Target(target.dependencies, target.commands.toArray)
                    }
                    
                    val parts = line.split(":", 2)
                    val name = parts(0)
                    val dependencies = parts(1).split(" +")
                    state.target = Some(new ParserTarget(name, dependencies))
                    
                }

                state

            }
        
        // Process the last target.
        state.target.map { target => 
            state.targets(target.name) = new Target(target.dependencies, target.commands.toArray)
        }

        new Makefile(state.targets.toMap)

    }

}

