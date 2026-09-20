from pandas.api.types import is_numeric_dtype


# --- Relationship Validation ---

# Check foreign key integrity
def check_foreign_keys(left_df, right_df, left_key, right_key):
    merged = left_df.merge(
        right_df,
        left_on=left_key,
        right_on=right_key,
        how="left",
        indicator=True
    )

    orphan_count = (merged["_merge"] == "left_only").sum()

    return orphan_count


# --- Duplicates ---

# Check full row duplicates
def check_duplicates(df):
     return df.duplicated().sum()


# Check primary key duplicates
def check_key_duplicates(df, key):
    return df[key].duplicated().sum()


# --- Missing Values ---
def check_missing_values(df):
    return df.isna().sum()


# --- Check Validation ---
def check_amounts(df, column):
    if not is_numeric_dtype(df[column]):
        raise TypeError(f"Column '{column}' must be numeric.")

    negative_count = (df[column] < 0).sum()
    zero_count = (df[column] == 0).sum()

    return {
    "negative_count": negative_count,
    "zero_count": zero_count
}