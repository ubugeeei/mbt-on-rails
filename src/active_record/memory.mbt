///|
/// Holds the rows stored for one table in the in-memory adapter.
pub struct MemoryTable {
  name : String
  rows : Array[Record]
}

///|
/// Holds all tables stored by the in-memory adapter.
pub struct MemoryDatabase {
  tables : Array[MemoryTable]
}

///|
/// Returns an empty in-memory database.
pub fn empty_memory_database() -> MemoryDatabase {
  { tables: [] }
}

///|
/// Inserts a record into the in-memory database.
pub fn insert_record(db : MemoryDatabase, row : Record) -> MemoryDatabase {
  let tables : Array[MemoryTable] = []
  let mut inserted = false
  for table in db.tables {
    if table.name == row.table {
      let rows = @support.clone_array(table.rows)
      rows.push(row)
      tables.push({ name: table.name, rows })
      inserted = true
    } else {
      tables.push(table)
    }
  }
  if not(inserted) {
    tables.push({ name: row.table, rows: [row] })
  }
  { tables, }
}

///|
/// Finds records in the in-memory adapter by exact field value.
pub fn find_records(
  db : MemoryDatabase,
  table_name : String,
  column_name : String,
  value : String,
) -> Array[Record] {
  for table in db.tables {
    if table.name == table_name {
      let rows : Array[Record] = []
      for row in table.rows {
        match @support.find_entry(row.fields, column_name) {
          Some(current_value) => if current_value == value { rows.push(row) }
          None => ()
        }
      }
      return rows
    }
  }
  []
}
