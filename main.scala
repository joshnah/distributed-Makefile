import org.apache.spark.sql.SparkSession
import scala.io.Source

object SparkTest {
  def main(args: Array[String]): Unit = {
    // Créez une session Spark
    val spark = SparkSession
      .builder()
      .appName("SparkTest")
      .config("spark.master", "local")
      .getOrCreate()

    // Chargez un fichier texte
    val inputFile = "test.txt"
    // val textFile = spark.read.textFile(inputFile)

    // Effectuez une opération de comptage
    for (line <- Source.fromFile(inputFile).getLines()) {
        println(line)
    }

    // Affichez les résultats
    // wordCount.show()

    // Arrêtez la session Spark
    spark.stop()
  }
}
