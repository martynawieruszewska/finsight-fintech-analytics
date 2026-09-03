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
The increase in transactions per active user indicates that growth in transaction activity was driven not only by changes in the active customer base, but also by higher transaction intensity among active users.

Month-to-month fluctuations suggest that transaction activity can vary even when the number of active users remains relatively stable.


## 3. Transaction Value

**Observation:**  
Transaction value shows a long-term upward trend. Gross transaction value increased from approximately 4.90M at the beginning of the analyzed period to 5.57M at the end, while net transaction value increased from approximately 4.37M to 4.99M.

Monthly values initially appeared to show a recurring seasonal pattern, with noticeable declines in February followed by recoveries in March. However, after normalizing net transaction value by the number of days in each month, the February decline largely disappears.

For example, in 2019 average daily net transaction value was approximately 161.9K in January, 162.1K in February, and 163.8K in March.

**Business interpretation:**  
Transaction value increased over the analyzed period, indicating growth in overall platform activity. The recurring February decline in monthly transaction value is primarily explained by the shorter length of the month rather than a meaningful decrease in daily transaction value.

This demonstrates the importance of normalizing time-based KPIs before interpreting recurring monthly patterns as seasonality.


## 4. Fraud Transaction Analysis

**Observation:**  
Approximately 67% of all transactions have a known fraud label. Among labeled transactions, approximately 0.15% are classified as fraudulent.

Fraudulent transactions show substantially higher values across the transaction value distribution. Their median positive transaction value is 74.00 compared with 31.89 for non-fraudulent transactions, while the corresponding averages are 125.37 and 50.47.

The difference is also visible across the transaction value distribution:

- 25th percentile: 23.09 vs 11.07
- Median: 74.00 vs 31.89
- 75th percentile: 152.43 vs 66.25

Fraud label coverage remains stable at approximately 67% across the analyzed period. However, fraud occurrence varies considerably over time, including extended periods with no transactions labeled as fraudulent.

**Business interpretation:**  
Although fraudulent transactions represent only a small proportion of labeled transactions, their substantially higher transaction values suggest that fraud may have a disproportionate financial impact relative to its frequency.

The consistently higher values across multiple percentiles indicate that the difference is not driven solely by a small number of extreme transactions. Transaction amount may therefore be a useful feature for further fraud analysis and predictive modeling.

Periods with zero observed fraud should be interpreted cautiously, as they may reflect characteristics of the dataset or labeling process rather than the complete absence of fraudulent activity.


## 5. Cards per User

**Observation:**  
Users hold an average of 3.07 cards. The most common number of cards per user is three, held by 449 users, representing 22.45% of all users.

Most users hold between one and four cards, while higher card ownership becomes progressively less common. Only a small share of users hold seven or more cards.

**Business interpretation:**  
Card ownership is concentrated around a relatively small number of cards per customer, with three cards being the most common configuration.

Users with unusually high card ownership form a small segment that could be investigated further to determine whether card ownership is associated with differences in transaction frequency, spending patterns, or product usage.


## 6. Long-Term Transaction Trends

**Observation:**  
Three-month rolling averages reveal a gradual increase in platform activity while reducing short-term monthly fluctuations.

The rolling average of net transaction value increased from approximately 4.34M in early 2010 to around 5.0M in the later years of the analyzed period. However, growth gradually slowed and transaction value remained relatively stable around this level toward the end of the period.

At the same time, the three-month rolling average of transactions per active user increased from approximately 91–94 transactions in the early period to around 97–98 transactions in later years.

**Business interpretation:**  
The long-term trend indicates increasing transaction intensity among active users over the analyzed period.

While transaction frequency continued to increase, transaction value gradually approached a more stable level during the later years. This suggests that transaction intensity continued to strengthen even as growth in overall transaction value slowed.


## 7. Merchant Category Transaction Patterns

**Observation:**  
Transaction activity varies substantially across merchant categories. Grocery Stores and Supermarkets generate the highest transaction volume, with approximately 1.59M transactions and an average ticket of 25.73.

In contrast, Money Transfer generates fewer transactions, approximately 589K, but the highest gross transaction value among the major categories, reaching approximately 53.16M with an average ticket of 91.89.

**Business interpretation:**  
High transaction volume does not necessarily translate into the highest transaction value. Everyday spending categories such as groceries are characterized by frequent, relatively low-value transactions, while categories such as Money Transfer generate considerably more value per transaction.

This highlights the importance of considering transaction volume, total value, and average ticket size together when evaluating the commercial importance of merchant categories.


## 8. Fraud Risk Across Merchant Categories

**Observation:**  
Fraud activity differs considerably across merchant categories. Among categories with at least 10,000 labeled transactions, Passenger Railways has the highest fraud rate at 1.45%, compared with an overall fraud rate of approximately 0.15%.

However, Department Stores generate the highest absolute number of fraudulent transactions, with 2,251 fraud cases and a fraud rate of 0.71%.

**Business interpretation:**  
Fraud rate and fraud volume capture different dimensions of fraud exposure. Categories with the highest relative fraud risk do not necessarily generate the largest number of fraudulent transactions.

Department Stores stand out because they combine an elevated fraud rate with a large transaction base, resulting in substantial fraud volume.

This suggests that fraud monitoring strategies should consider both the probability of fraud within a category and the absolute number of fraud cases rather than relying on fraud rate alone.


## 9. Customer Segmentation

**Observation:**  
RFM segmentation shows that the customer base is dominated by recently active users. Among 1,219 customers with transaction history, 28.96% are classified as Champions, 26.50% as Promising, 21.82% as Active Customers, and 19.85% as Loyal Customers.

Together, these four high-recency segments represent 97.13% of customers included in the RFM analysis. This is consistent with the underlying Recency distribution, where the vast majority of customers made a transaction within the final two days of the dataset.

Only 0.16% of customers are classified as At Risk and 0.98% as Need Attention. Rather than indicating unusually strong customer retention, this result primarily reflects the highly concentrated Recency distribution and should therefore be interpreted cautiously.

**Business interpretation:**  
A key opportunity lies in differentiating recently active customers by transaction frequency and monetary value.

Champions and Loyal Customers represent strong candidates for retention and loyalty initiatives, while Promising and Active Customers may provide opportunities to increase transaction frequency and customer value through targeted engagement.

The very small At Risk and Need Attention segments should not be interpreted as evidence of exceptionally low churn risk without further analysis, as their size is strongly influenced by the structure of the Recency variable.