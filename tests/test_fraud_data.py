import pandas as pd

from finsight.fraud_data import (
    calculate_year_limits,
    split_features_target,
)


def test_calculate_year_limits_is_proportional_to_yearly_counts():
    non_fraud_counts = {2010: 100, 2011: 300}

    limits = calculate_year_limits(non_fraud_counts, total_limit=1000)

    assert limits == {2010: 250, 2011: 750}


def test_calculate_year_limits_sums_to_total_limit():
    non_fraud_counts = {2010: 831529, 2011: 863428, 2012: 885421}
    limits = calculate_year_limits(non_fraud_counts, total_limit=300000)

    assert abs(sum(limits.values()) - 300000) <= len(limits)


def test_split_features_target_selects_only_requested_features():
    df = pd.DataFrame({
        "transaction_key": [1, 2],
        "amount": [10.0, 20.0],
        "mcc_key": [5, 7],
        "is_fraud": [False, True],
    })

    X, y = split_features_target(df, ["amount", "mcc_key"])

    assert list(X.columns) == ["amount", "mcc_key"]
    assert y.tolist() == [False, True]


def test_split_features_target_returns_a_copy():
    df = pd.DataFrame({"amount": [10.0], "is_fraud": [False]})

    X, _ = split_features_target(df, ["amount"])
    X.loc[0, "amount"] = 999.0

    assert df.loc[0, "amount"] == 10.0
