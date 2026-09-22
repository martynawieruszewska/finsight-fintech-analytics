import pandas as pd
from sklearn.preprocessing import OneHotEncoder


# Encode categorical features
def encode_categorical_features(X_train, X_val):
    categorical_columns = X_train.select_dtypes(include=['str']).columns
    encoder = OneHotEncoder(
        sparse_output=False,
        handle_unknown="ignore"
    )

    encoded_data = encoder.fit_transform(X_train[categorical_columns])

    encoded_train = pd.DataFrame(
        encoded_data,
        columns=encoder.get_feature_names_out(categorical_columns),
        index=X_train.index
    )

    final_train = pd.concat(
        [X_train.drop(columns=categorical_columns), encoded_train],
        axis=1
    )

    encoded_val = encoder.transform(X_val[categorical_columns])

    encoded_val = pd.DataFrame(
        encoded_val,
        columns=encoder.get_feature_names_out(categorical_columns),
        index=X_val.index
    )

    final_val = pd.concat(
        [X_val.drop(columns=categorical_columns), encoded_val],
        axis=1
    )

    return final_train, final_val


# Fill missing values using training medians
def handle_missing_values(final_train, final_val):
    medians = final_train.median()
    final_train = final_train.fillna(median)
    final_val = final_val.fillna(median)

    return final_train, final_val