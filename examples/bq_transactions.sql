CREATE TABLE
  `<PROJECT>.<DATASET>.transactions` ( transaction_id INT64,
    exchange_rate FLOAT64,
    transaction_amount NUMERIC,
    account_balance BIGNUMERIC,
    is_fraudulent BOOL,
    transaction_type STRING,
    customer_signature BYTES,
    transaction_date DATE,
    approval_datetime DATETIME,
    record_inserted_at TIMESTAMP,
    execution_time TIME,
    additional_metadata JSON,
    tags ARRAY<STRING>,
    account_holder_info STRUCT< customer_id INT64,
    customer_name STRING,
    is_premium_customer BOOL > );

INSERT INTO
  `<PROJECT>.<DATASET>.transactions`
WITH
  numbers AS (
  SELECT
    x AS id
  FROM
    UNNEST(GENERATE_ARRAY(1, 100)) AS x ),
  DATA AS (
  SELECT
    id AS transaction_id,
    ROUND(RAND() * 2 + 0.8, 4) AS exchange_rate,
    CAST(ROUND(RAND() * 10000, 2) AS NUMERIC) AS transaction_amount,
    CAST(ROUND(RAND() * 1000000, 2) AS BIGNUMERIC) AS account_balance,
    RAND() < 0.05 AS is_fraudulent,
  IF
    (RAND() < 0.5, 'deposit', 'withdrawal') AS transaction_type,
    CAST(CONCAT('sig_', CAST(id AS STRING)) AS BYTES) AS customer_signature,
    DATE_SUB(CURRENT_DATE(), INTERVAL CAST(FLOOR(RAND()*365) AS INT64) DAY) AS transaction_date,
    DATETIME_SUB(CURRENT_DATETIME(), INTERVAL CAST(FLOOR(RAND()*100000) AS INT64) SECOND) AS approval_datetime,
    CURRENT_TIMESTAMP() AS record_inserted_at,
    TIME( CAST(FLOOR(RAND() * 24) AS INT64), CAST(FLOOR(RAND() * 60) AS INT64), CAST(FLOOR(RAND() * 60) AS INT64) ) AS execution_time,
    PARSE_JSON(TO_JSON_STRING(STRUCT(id AS reference_id,
          'sample' AS note))) AS additional_metadata,
    [ [ 'finance',
    'audit',
    'risk'][
  OFFSET
    (CAST(FLOOR(RAND()*3) AS INT64))] ] AS tags,
    STRUCT( 1000 + id AS customer_id,
      CONCAT('Customer_', CAST(id AS STRING)) AS customer_name,
      RAND() < 0.2 AS is_premium_customer ) AS account_holder_info
  FROM
    numbers )
SELECT
  *
FROM
  DATA;