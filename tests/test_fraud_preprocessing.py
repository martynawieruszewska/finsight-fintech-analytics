import pandas as pd

from finsight.fraud_preprocessing import (
    encode_categorical_features,
    handle_missing_values,
    handle_behavioral_missing_values,
)


def test_encoder_is_fitted_on_training_data_only():
    X_train = pd.DataFrame({
        "amount": [10.0, 20.0],
        "use_chip": ["Swipe Transaction", "Online Transaction"],
    })
    X_val = pd.DataFrame({
        "amount": [30.0],
        "use_chip": ["Chip Transaction"],
    })

    train_encoded, val_encoded = encode_categorical_features(X_train, X_val)

    assert list(train_encoded.columns) == list(val_encoded.columns)
    assert "use_chip_Chip Transaction" not in val_encoded.columns
    assert val_encoded.filter(like="use_chip_").sum(axis=1).iloc[0] == 0


def test_missing_values_are_filled_with_training_medians():
    train = pd.DataFrame({"amount": [1.0, 3.0, None]})
    val = pd.DataFrame({"amount": [None, 100.0]})

    train_filled, val_filled = handle_missing_values(train, val)

    assert train_filled["amount"].tolist() == [1.0, 3.0, 2.0]
    assert val_filled["amount"].tolist() == [2.0, 100.0]


def test_behavioral_missing_values_keep_history_information():
    def make_frame():
        return pd.DataFrame({
            "user_amount_last_24h": [None, 50.0],
            "hours_since_user_transaction": [None, 2.5],
            "hours_since_card_transaction": [None, None],
        })

    train, val = handle_behavioral_missing_values(make_frame(), make_frame())

    for df in (train, val):
        assert df["user_amount_last_24h"].tolist() == [0.0, 50.0]
        assert df["has_user_transaction_history"].tolist() == [0, 1]
        assert df["has_card_transaction_history"].tolist() == [0, 0]