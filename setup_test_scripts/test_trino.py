import trino

# Connect to Trino (same as you would with Athena)
conn = trino.dbapi.connect(
    host='localhost',
    port=8080,
    user='admin',
    catalog='hive',
    schema='default'
)

cursor = conn.cursor()

print("✓ Connected to Trino")

# List available tables (created by Spark)
cursor.execute("SHOW TABLES")
tables = cursor.fetchall()
print(f"\n✓ Available tables in hive.default:")
for table in tables:
    print(f"  - {table[0]}")

# Query the employees table (created by Spark)
print("\n✓ Querying employees table:")
cursor.execute("SELECT * FROM default.employees")
rows = cursor.fetchall()

for row in rows:
    print(f"  {row}")

# Show table stats
cursor.execute("SELECT COUNT(*) as total FROM default.employees")
count = cursor.fetchone()[0]
print(f"\n✓ Total records: {count}")

# Group by department
cursor.execute("""
    SELECT department, COUNT(*) as count, AVG(age) as avg_age
    FROM default.employees
    GROUP BY department
    ORDER BY count DESC
""")
print("\n✓ Department statistics:")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]} employees, avg age {row[2]:.1f}")

print("\n✅ Trino successfully queried table created by Spark!")

cursor.close()
conn.close()
