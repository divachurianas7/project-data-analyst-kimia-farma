
# transaction_id ; date ; branch_id --> ada di kf_final_transaction
# branch_name ; kota ; provinsi --> ada di kf_kantor_cabang
SELECT
  ft.transaction_id,
  ft.date,
  ft.branch_id,
  kc.branch_name,
  kc.kota,
  kc.provinsi
FROM `rakamin-kf-analytics-488600.kimia_farma.kf_final_transaction` AS ft
LEFT JOIN `rakamin-kf-analytics-488600.kimia_farma.kf_kantor_cabang` AS kc
  ON ft.branch_id = kc.branch_id;


CREATE OR REPLACE TABLE `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa` AS
SELECT
  ft.transaction_id,
  ft.date,
  ft.branch_id,
  kc.branch_name,
  kc.kota,
  kc.provinsi,
  kc.rating AS rating_cabang,

  ft.customer_name,
  ft.product_id,
  p.product_name,
  p.price AS actual_price,
  ft.discount_percentage,

  -- Persentase gross laba
  CASE
    WHEN p.price <= 50000 THEN 0.10
    WHEN p.price > 50000 AND p.price <= 100000 THEN 0.15
    WHEN p.price > 100000 AND p.price <= 300000 THEN 0.20
    WHEN p.price > 300000 AND p.price <= 500000 THEN 0.25
    ELSE 0.30
  END AS persentase_gross_laba,

  -- Nett sales (harga setelah diskon)
  p.price * (1 - ft.discount_percentage) AS nett_sales,

  -- Nett profit
  (p.price * (1 - ft.discount_percentage)) *
  CASE
    WHEN p.price <= 50000 THEN 0.10
    WHEN p.price > 50000 AND p.price <= 100000 THEN 0.15
    WHEN p.price > 100000 AND p.price <= 300000 THEN 0.20
    WHEN p.price > 300000 AND p.price <= 500000 THEN 0.25
    ELSE 0.30
  END AS nett_profit,

  ft.rating AS rating_transaksi

FROM `rakamin-kf-analytics-488600.kimia_farma.kf_final_transaction` ft
LEFT JOIN `rakamin-kf-analytics-488600.kimia_farma.kf_kantor_cabang` kc
  ON ft.branch_id = kc.branch_id
LEFT JOIN `rakamin-kf-analytics-488600.kimia_farma.kf_product` p
  ON ft.product_id = p.product_id;


# Snapshot Data (KPI Cards)
SELECT
  COUNT(DISTINCT transaction_id) AS total_transaksi,
  SUM(nett_sales) AS total_nett_sales,
  SUM(nett_profit) AS total_nett_profit
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`;

# Perbandingan Pendapatan Kimia Farma dari tahun ke tahun
SELECT
  EXTRACT(YEAR FROM date) AS tahun,
  SUM(nett_sales) AS total_pendapatan
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY tahun
ORDER BY tahun;

# Top 10 Total transaksi cabang provinsi
SELECT
  provinsi,
  branch_name,
  COUNT(DISTINCT transaction_id) AS total_transaksi
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY provinsi, branch_name
ORDER BY total_transaksi DESC
LIMIT 10;

# Top 10 Nett sales cabang provinsi
SELECT
  provinsi,
  branch_name,
  SUM(nett_sales) AS total_nett_sales
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY provinsi, branch_name
ORDER BY total_nett_sales DESC
LIMIT 10;

# Top 5 Cabang Dengan Rating Tertinggi, namun Rating Transaksi Terendah
SELECT
  branch_name,
  provinsi,
  AVG(rating_cabang) AS avg_rating_cabang,
  AVG(rating_transaksi) AS avg_rating_transaksi
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY branch_name, provinsi
HAVING avg_rating_cabang >= 4
ORDER BY avg_rating_transaksi ASC
LIMIT 5;

# Indonesia's Geo Map Untuk Total Profit Masing-masing Provinsi
SELECT
  provinsi,
  SUM(nett_profit) AS total_profit
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY provinsi;

SELECT
  provinsi,
  SUM(nett_profit) AS total_profit
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY provinsi
ORDER BY total_profit DESC
LIMIT 1;

# Produk yang Paling Menguntungkan
SELECT
  product_name,
  SUM(nett_profit) AS total_profit
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY product_name
ORDER BY total_profit DESC;

SELECT
  product_name,
  SUM(nett_profit) AS total_profit
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY product_name
ORDER BY total_profit DESC
LIMIT 5;

#Total Transaksi
SELECT
  COUNT(DISTINCT transaction_id) AS total_transaksi
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`;

#Total Pendapatan Bersih
SELECT
  SUM(nett_sales) AS total_nett_sales
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`;

#Total Keuntungan Bersih
SELECT
  SUM(nett_profit) AS total_nett_profit
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`;

SELECT
  provinsi,
  SUM(nett_sales) AS total_nett_sales
FROM `rakamin-kf-analytics-488600.kimia_farma.tabel_analisa`
GROUP BY provinsi
ORDER BY total_nett_sales DESC
LIMIT 5;
