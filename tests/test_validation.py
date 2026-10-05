import pandas as pd
import pytest

from finsight.validation import (
    check_foreign_keys,
    check_duplicates,
    check_key_duplicates,
    check_missing_values,
    check_amounts,
)


def test_check_foreign_keys_counts_orphan_records():
    transactions = pd.DataFrame({"client_id": [1, 2, 3, 99]})
    users = pd.DataFrame({"id": [1, 2, 3]})

    assert check_foreign_keys(transactions, users, "client_id", "id") == 1


def test_check_foreign_keys_returns_zero_when_all_keys_match():
    transactions = pd.DataFrame({"client_id": [1, 1, 2]})
    users = pd.DataFrame({"id": [1, 2]})

    assert check_foreign_keys(transactions, users, "client_id", "id") == 0


def test_check_duplicates_counts_fully_duplicated_rows():
    df = pd.DataFrame({"id": [1, 1, 2], "amount": [10.0, 10.0, 5.0]})

    assert check_duplicates(df) == 1


def test_check_key_duplicates_ignores_other_columns():
    df = pd.DataFrame({"id": [1, 1, 2], "amount": [10.0, 20.0, 5.0]})

    assert check_duplicates(df) == 0
    assert check_key_duplicates(df, "id") == 1


def test_check_missing_values_per_column():
    df = pd.DataFrame({"a": [1, None, 3], "b": [None, None, "x"]})

    missing = check_missing_values(df)

    assert missing["a"] == 1
    assert missing["b"] == 2


def test_check_amounts_counts_negative_and_zero_values():
    df = pd.DataFrame({"amount": [-5.0, 0.0, 0.0, 12.5]})

    result = check_amounts(df, "amount")

    assert result["negative_count"] == 1
    assert result["zero_count"] == 2


def test_check_amounts_rejects_non_numeric_column():
    df = pd.DataFrame({"amount": ["$10.00", "$5.00"]})

    with pytest.raises(TypeError):
        check_amounts(df, "amount")