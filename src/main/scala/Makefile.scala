import scala.collection.mutable.ArrayBuffer
import scala.collection.mutable
import scala.io.Source

import java.nio.file.Path
import java.nio.file.Files


class Target(val name: String, val dependencies: Array[String], val commands: Array[String])

class Makefile(val path: Path, val targets: Array[Target]) {

    /**
      * Get the directory this makefile is stored in, the directory returned is absolute.
      */
    def directory = this.path.toAbsolutePath.getParent()

    /**
      * Calculate the scheduling order for this makefile. This method doesn't schedule
      * files that are up-to-date with their dependencies and also with the makefile.
      * For each target, if a dependency is not defined as a target but its file is not
      * existing, then 
      */
    def calc_scheduling(initial_targets: Array[String]): Array[Array[Target]] = {

        class TargetOrder(
            var target: Option[Target],
            var order: Int,
        )

        // A constant list with all makefile-defined targets.
        val allTargets = this.targets.map(t => (t.name, t)).toMap

        // This is an array of targets to add 
        var newTargets = initial_targets.toBuffer
        // All targets have an order of zero initially.
        var tmpTargets = Map[String, TargetOrder]()
        var maxOrder = 0

        // Apply the algorithm while at least one target has changed order.
        // NOTE: This algorithm has not a good complexity because a small order changed
        // in a target common to many other will trigger a lot a order change in cascade.
        var changed = true;
        while (changed) {

            tmpTargets ++= newTargets.map(name => (name, new TargetOrder(allTargets.get(name), 0)))
            newTargets = ArrayBuffer()

            changed = false;
            tmpTargets = tmpTargets.map { case (name, to) => 
                to.target.map { target => {
                    // Targets without dependencies can just skip the mapping because they
                    // keep the default order '0'.
                    if (target.dependencies.isEmpty) {
                        (name, to)
                    } else {

                        // Find the max order of among the target dependencies and then 
                        // add one because we should execute one step after the last 
                        // dependency.
                        val newOrder = target.dependencies
                            .map(dep => {
                                // Dependencies that are not target are just like targets 
                                // without dependencies, so they have an order of 0.
                                tmpTargets.get(dep)
                                    .map(_.order)
                                    .getOrElse {
                                        // Not found in current targets, so we add it to 
                                        // the new targets to be added later.
                                        newTargets += dep
                                        0
                                    }
                            })
                            .max + 1
                        
                        // If the order has changed, notify it.
                        if (newOrder != to.order) {
                            changed = true;
                            maxOrder = maxOrder.max(newOrder)
                            (name, new TargetOrder(to.target, newOrder))
                        } else {
                            (name, to)
                        }

                    }
                }}.getOrElse((name, to))  // If not makefile-defined target, skip.
            }

            if (maxOrder > 100) {
                throw new RuntimeException("too much recursion")
            }

        }

        val seqTargets = (0 to maxOrder).map(i => ArrayBuffer[(String, Option[Target])]()).toArray
        tmpTargets.foreach { case (name, to) => seqTargets(to.order) += ((name, to.target)) }

        val makefileModTime = Files.getLastModifiedTime(this.path).toMillis();
        val dir = this.directory

        seqTargets.map { targets =>
            // Start by filtering and checking targets that are out-of-date.
            targets.filter { case (name, target) => 

                val path = dir.resolve(name)

                target match {
                    case Some(target) => {
                        // If there is a target, we check if a file is already exiting 
                        // at the path, if so we check if the file is outdated regarding
                        // its dependencies and the makefile mod time.
                        if (Files.isRegularFile(path)) {
                            val modTime = Files.getLastModifiedTime(path).toMillis()
                            if (makefileModTime > modTime) {
                                // The makefile has been modified since this file has been 
                                // constructed, commands may have been modified.
                                true
                            } else {
                                // Keep the target only if it is outdated. If no 
                                // dependencies, then this should return false and 
                                // therefore skip that target.
                                target.dependencies.find { dep =>
                                    val depPath = dir.resolve(dep)
                                    if (Files.isRegularFile(depPath)) {
                                        val depModTime = Files.getLastModifiedTime(depPath).toMillis()
                                        // If the dependency file has been modified after.
                                        depModTime > modTime
                                    } else {
                                        false
                                    }
                                }.isDefined
                            }
                        } else {
                            // File is not yet existing, keep the target.
                            true
                        }
                    }
                    case None => {
                        // If there is no makefile-defined target, the file must exists.
                        if (!Files.isRegularFile(path)) {
                            throw new RuntimeException(s"no target found to make '$name'")
                        }
                        // We don't keep such targets in the final scheduling.
                        false
                    }
                }

            }.map { case (name, target) => 
                // We know that all "none" are filtered-out, so it's safe.
                target.get
            }
        }.filter {
            // Do not keep empty sequence.
            !_.isEmpty
        }.map {
            // Finally remap everything to a fixed array.
            _.toArray
        }

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
