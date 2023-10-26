import scala.io.Source

object Hello {
    def main(args: Array[String]) = {
        val bufferedSource = Source.fromFile("makefiles/matrix/Makefile")
        var cpt = 0
        var split = new Array[String](2)
        var cible = ""
        var prerequisites = ""
            for (line <- bufferedSource.getLines) {
                // cpt += 1
                // // ligne avec les cibles
                // if (cpt % 2 == 1) {
                //     // split = line.split(":")
                //     split = line.split("\\s+")
                //     println(split(0), split(1), cpt)
                //     // print(line.split(":"))
                // }
                // println("sinon" + line + " " + cpt)
                val words = line.split("\\s+")
                for (word <- words) {
                    println(word)
                }
            }

        bufferedSource.close
    }
}
