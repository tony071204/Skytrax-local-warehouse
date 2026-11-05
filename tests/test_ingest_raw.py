import duckdb
import pytest

from scripts.ingest_raw import CSV_FILES, main


def create_test_csvs(folder):
    """Create fake csvs to test"""
    for name in CSV_FILES:
        (folder / name).write_text("id,name\n1,a\n2,b\n")

def test_missing_csv_raises_error(tmp_path):
    db_path = tmp_path / "test.duckdb"

    with pytest.raises(FileNotFoundError):
        main(data_dir=tmp_path, db_path=db_path)

def test_creates_all_raw_tables(tmp_path):
    create_test_csvs(tmp_path)
    db_path = tmp_path / "test.duckdb"

    main(data_dir=tmp_path, db_path=db_path)

    con = duckdb.connect(str(db_path))
    tables = {row[0] for row in con.execute("SHOW TABLES").fetchall()}
    con.close()

    expected = {"raw_" + name.replace(".csv", "") for name in CSV_FILES}
    assert tables == expected

def test_row_counts_match_csv(tmp_path):
    create_test_csvs(tmp_path)
    db_path = tmp_path / "test.duckdb"

    main(data_dir=tmp_path, db_path=db_path)

    con = duckdb.connect(str(db_path))
    for name in CSV_FILES:
        table = "raw_" + name.replace(".csv", "")
        n = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        assert n == 2
    con.close()

def test_running_twice_does_not_duplicate_rows(tmp_path):
    create_test_csvs(tmp_path)
    db_path = tmp_path / "test.duckdb"

    main(data_dir=tmp_path, db_path=db_path)
    main(data_dir=tmp_path, db_path=db_path)

    con = duckdb.connect(str(db_path))
    n = con.execute("SELECT COUNT(*) FROM raw_airlines").fetchone()[0]
    con.close()
    assert n == 2