package main.scala

import java.nio.file.attribute.FileTime
import scala.collection.mutable.HashMap
import scala.collection.mutable.ListBuffer


/** A system file
 *
 *  @constructor create a new file with a name and the last modified date.
 *  @param name the file's name
 *  @param lastModified the last time is null if the file doesn't exist yet
 */
class File(val name: String, val lastModified: FileTime){
    override def toString: String = {
        s"File(name: $name, lastModified: $lastModified)"
    }
}

object File {
  // Cache - store all the instances of File
  private val fileCache = new HashMap[String, File]()

  // Method in order to create an instance of File or get the existing one from the cache
  def getFileInstance(name: String, lastModified: FileTime): File = {
    fileCache.getOrElseUpdate(name, new File(name, lastModified))
  }
}

/** A rule from a makefile
 *
 *  @constructor create a new rule with the target(s), the dependencies and the commands.
 *  @param targets list of File to generate
 *  @param dependencies list of File to use
 *  @param commands list of bash commands that used the dependencies to generate the targets
 */
class Rule(val targets: List[File], val dependencies: List[File], val commands: List[String]) {
    override def toString: String = {
        s"Rule(targets: $targets, dependencies: $dependencies, commands: $commands)"
    }
}

object Rule {
    private val ruleCache = new HashMap[String, ListBuffer[Rule]]()
    private var firstRule: Option[Rule] = None

    def updateRuleCache(targets: List[File], dependencies: List[File], commands: List[String]) = {
        targets.foreach(target => {
            this.ruleCache.getOrElseUpdate(target.name, ListBuffer()) += new Rule(targets, dependencies, commands)
        })
    }

    def getRuleInstance(target: String): List[Rule] = {
        return this.ruleCache.getOrElse(target, ListBuffer()).toList
    }
    def getFirstRule(): Option[Rule] = {
        return this.firstRule
    }
    def setFirstRule(rule: Rule) = {
        this.firstRule = Some(rule)
    }
}