from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

# Create Spark session with Hive metastore support
# Configuration is loaded from spark-defaults.conf
spark = SparkSession.builder \
    .appName("MinIO + Hive Metastore Test") \
    .enableHiveSupport() \
    .getOrCreate()

print("✓ Spark session created with Hive support")

# Create a sample DataFrame
data = [
    ("Alice", 34, "Engineering"),
    ("Bob", 45, "Sales"),
    ("Charlie", 29, "Engineering"),
    ("Diana", 38, "Marketing")
]

schema = StructType([
    StructField("name", StringType(), True),
    StructField("age", IntegerType(), True),
    StructField("department", StringType(), True)
])

df = spark.createDataFrame(data, schema)
print("\n✓ Sample DataFrame created:")
df.show()

# Save as a Hive table (this registers in metastore + writes to S3)
table_name = "default.employees"
table_location = "s3a://datalake/warehouse/employees"

print(f"\nSaving to Hive table: {table_name}")
print(f"Location: {table_location}")

# Drop table if exists
spark.sql(f"DROP TABLE IF EXISTS {table_name}")

# Create table with explicit location
df.write \
    .mode("overwrite") \
    .option("path", table_location) \
    .saveAsTable(table_name)

print("✓ Table saved to Hive metastore")

# Verify by reading back using SQL
print(f"\nReading back using Spark SQL:")
result = spark.sql(f"SELECT * FROM {table_name}")
result.show()

# Show table info
print("\n✓ Table metadata:")
spark.sql(f"DESCRIBE FORMATTED {table_name}").show(truncate=False)

print(f"\nRecord count: {result.count()}")

print("\n✅ Data is now available in both Spark and Trino!")
print("   Run test_trino.py to verify Trino can see the table.")
