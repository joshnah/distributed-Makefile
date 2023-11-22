import scala.collection.mutable.ArrayBuffer
import scala.collection.mutable
import scala.io.Source

import java.nio.file.Path
import java.nio.file.Files


class Target(val name: String, val dependencies: Array[String], val commands: Array[String])

class Makefile(val path: Path, val targets: Array[Target]) {

    /**
      * This function filters out all targets that points to files (relative to given
      * directory path) if they are up-to-date. The dropped targets are also removed
      * from dependencies of other targets that use them.
      */
    def drop_up_to_date(dir: Path): Makefile = {

        val makefileModTime = Files.getLastModifiedTime(this.path).toMillis();
        
        val newTargets = this.targets
            .map { target => (target, dir.resolve(target.name)) }
            .filter { case (target, path) =>
                if (Files.isRegularFile(path)) {
                    val modTime = Files.getLastModifiedTime(path).toMillis()
                    if (makefileModTime > modTime) {
                        // The makefile has been modified since this file has been 
                        // constructed, commands may have been modified so we keep it.
                        true
                    } else {
                        // Keep the target only if it is outdated.
                        target.dependencies.find { dep =>
                            val depPath = dir.resolve(dep)
                            if (Files.isRegularFile(depPath)) {
                                val depModTime = Files.getLastModifiedTime(depPath).toMillis()
                                // If the dependency file has been modified after the file
                                // target, then the file target must be recomputed.
                                depModTime > modTime
                            } else {
                                false
                            }
                        }.isDefined
                    }
                } else {
                    // Targets that are not (yet?) a file should be executed anyway.
                    true
                }
            }
            .map { case (target, _) => target }

        new Makefile(this.path, newTargets)

    }

    /**
      * Calculate the scheduling order for this makefile. The given directory is used to
      * check 
      */
    def calc_scheduling(dir: Path): Array[Array[Target]] = {

        var targets = this.targets
            .map { target => 

                // // Remove dependencies that are pointing to existing files and have no
                // // existing target for them, such dependencies can be considered already
                // // valid.
                // val dependencies = target.dependencies.filter { dep => 
                    
                // }

                (target, target.dependencies.toBuffer) 
            }
            .toArray
        
        val ret = ArrayBuffer[Array[Target]]()

        while (!targets.isEmpty) {

            val independentTargets = ArrayBuffer[Target]()

            // Remove all target that are independent and push them to independent 
            // targets buffer.
            targets = targets
                .filter { case (target, dependencies) =>
                    if (dependencies.isEmpty) {
                        independentTargets += target
                        false
                    } else {
                        true
                    }
                }
            
            if (independentTargets.isEmpty) {
                throw new RuntimeException("cyclic dependencies")
            }

            // Remove each independent target from dependencies of not-yet-independent 
            // targets, and repeat.
            for (target <- independentTargets) {
                for (case (_, dependencies) <- targets) {
                    dependencies -= target.name;
                }
            }

            ret += independentTargets.toArray

        }

        ret.toArray

    }

}

object Makefile {

    def parse(path: Path): Makefile = {

        class ParserTarget(
            var name: String,
            var dependencies: Array[String],
            var commands: ArrayBuffer[String] = new ArrayBuffer,
        )

        class ParserState(
            var target: Option[ParserTarget] = None,
            var targets: ArrayBuffer[Target] = new ArrayBuffer
        )

        val state = Source.fromFile(path.toUri())
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
                        state.targets += new Target(target.name, target.dependencies, target.commands.toArray)
                    }
                    
                    val parts = line.split(":", 2)
                    val name = parts(0).stripTrailing
                    val dependencies = parts(1).stripLeading.split(" ").filter(!_.isEmpty)
                    state.target = Some(new ParserTarget(name, dependencies))
                    
                }

                state

            }
        
        // Process the last target.
        state.target.map { target => 
            state.targets += new Target(target.name, target.dependencies, target.commands.toArray)
        }

        new Makefile(path, state.targets.toArray)

    }

}
