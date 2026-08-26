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