-- Business analysis queries for warehouse.db.
-- Valuation: unit cost over 50, extended value = unit cost * quantity, highest total first.
-- Price clean: markup 20 means 20 percent. The result floors at 0.
-- SKUs with no cost and no markup are left out of the price clean.
-- The marker below splits the two statements for the local app. sqlite3 ignores it.

SELECT
  sku,
  name,
  unit_cost,
  quantity,
  ROUND(unit_cost * quantity, 2) AS total
FROM products
WHERE unit_cost > 50
ORDER BY unit_cost * quantity DESC, sku;

-- @@

SELECT
  sku,
  name,
  unit_cost,
  markup_percent,
  CASE
    WHEN unit_cost * (1.0 + markup_percent / 100.0) < 0 THEN 0
    ELSE ROUND(unit_cost * (1.0 + markup_percent / 100.0), 2)
  END AS cleaned_cost
FROM products
WHERE unit_cost > 0 OR markup_percent != 0
ORDER BY sku;
