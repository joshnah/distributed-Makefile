package main.scala

import java.nio.file.attribute.FileTime;

class File(val name: String, val lastModified: FileTime)
class Rule(val targets: List[File], val dependencies: List[File], val commands: List[String])