# FinSight — Business Insights

## 1. Monthly Active Users

**Observation:**  
Monthly Active Users increased from 1,083 at the beginning of the analyzed period to 1,203 at the end, representing an overall increase of approximately 11.1%.

**Business interpretation:**  
Growth gradually stabilized, with MAU remaining around 1,206 users for several consecutive months. This may indicate that user activity reached a relatively stable level, with limited growth toward the end of the analyzed period.

## 2. Transaction Frequency

**Observation:**  
The average number of transactions per active user increased from 93.45 at the beginning of the analyzed period to 97.57 at the end, representing an overall increase of approximately 4.4%.

**Business interpretation:**  
Transaction frequency shows noticeable month-to-month fluctuations despite a relatively stable active user base. This suggests that changes in transaction activity are driven not only by the number of active users, but also by variations in how frequently existing users transact.

## 3. Transaction Value

**Observation:**  
Transaction value shows a long-term upward trend. Gross transaction value increased from approximately 4.90M at the beginning of the analyzed period to 5.57M at the end, while net transaction value increased from approximately 4.37M to 4.99M.

Monthly values initially appeared to show a recurring seasonal pattern, with noticeable declines in February followed by recoveries in March. However, after normalizing net transaction value by the number of days in each month, the February decline largely disappears.

For example, in 2019 average daily net transaction value was approximately 161.9K in January, 162.1K in February, and 163.8K in March.

**Business interpretation:**  
Transaction value increased over the analyzed period, indicating growth in overall platform activity. The recurring February decline in monthly transaction value is primarily explained by the shorter length of the month rather than a meaningful decrease in daily customer spending.

This demonstrates the importance of normalizing time-based KPIs before interpreting recurring monthly patterns as seasonality.

## 4. Fraud Transaction Analysis

**Observation:**  
Approximately 67% of all transactions have a known fraud label. Among labeled transactions, approximately 0.15% are classified as fraudulent.

Despite their low frequency, fraudulent transactions tend to involve substantially higher transaction values than non-fraudulent transactions. The average positive transaction value is 125.37 for fraudulent transactions compared with 50.47 for non-fraudulent transactions.

The difference is also visible across the transaction value distribution:

- 25th percentile: 23.09 vs 11.07
- Median: 74.00 vs 31.89
- 75th percentile: 152.43 vs 66.25

Fraud label coverage remains stable at approximately 67% across the analyzed period. However, fraud occurrence varies considerably over time, including extended periods with no transactions labeled as fraudulent.

**Business interpretation:**  
Although fraudulent transactions represent only a small proportion of labeled transactions, their typical transaction value is more than twice as high as that of non-fraudulent transactions. This suggests that fraud may have a disproportionate financial impact relative to its frequency.

The consistently higher transaction values across multiple percentiles indicate that this difference is not driven solely by a small number of extreme transactions. Transaction amount may therefore be a useful feature for further fraud analysis and predictive modeling.

Periods with zero observed fraud should be interpreted cautiously, as they may reflect characteristics of the dataset or labeling process rather than the complete absence of fraudulent activity.

## 5. Cards per User

**Observation:**  
Users hold an average of 3.07 cards. The most common number of cards per user is three, held by 449 users, representing 22.45% of all users.

Most users hold between one and four cards, while higher card ownership becomes progressively less common. Only a small share of users hold seven or more cards.

**Business interpretation:**  
Card ownership