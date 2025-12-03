1. For every user in the system, get the user_id and last booked room_no 

SELECT u.user_id, b.room_no
FROM users u
LEFT JOIN bookings b
    ON b.user_id = u.user_id
WHERE b.booking_date = (
        SELECT MAX(booking_date)
        FROM bookings
        WHERE user_id = u.user_id
    );



2. Get booking_id and total billing amount of every booking created in November, 2021 

SELECT 
    b.booking_id,
    SUM(bc.item_quantity * i.item_rate) AS total_amount
FROM bookings b
JOIN booking_commercials bc ON bc.booking_id = b.booking_id
JOIN items i ON i.item_id = bc.item_id
WHERE YEAR(b.booking_date) = 2021
  AND MONTH(b.booking_date) = 11
GROUP BY b.booking_id;
 
 3.Get bill_id and bill amount of all the bills raised in October, 2021 having bill amount >1000

 SELECT 
    bc.bill_id,
    SUM(bc.item_quantity * i.item_rate) AS bill_amount
FROM booking_commercials bc
JOIN items i ON i.item_id = bc.item_id
WHERE YEAR(bc.bill_date) = 2021
  AND MONTH(bc.bill_date) = 10
GROUP BY bc.bill_id
HAVING bill_amount > 1000;

4. Determine the most ordered and least ordered item of each month of year 2021 

SELECT month, item_id, item_name, total_qty, 'most' AS which
FROM (
  -- most
  SELECT mi.month, mi.item_id, it.item_name, mi.total_qty
  FROM (
      SELECT DATE_FORMAT(bill_date, '%Y-%m') AS month,
             item_id,
             SUM(item_quantity) AS total_qty
      FROM booking_commercials
      WHERE YEAR(bill_date) = 2021
      GROUP BY DATE_FORMAT(bill_date, '%Y-%m'), item_id
  ) AS mi
  JOIN items it ON it.item_id = mi.item_id
  JOIN (
      SELECT month, MAX(total_qty) AS max_qty
      FROM (
          SELECT DATE_FORMAT(bill_date, '%Y-%m') AS month,
                 item_id,
                 SUM(item_quantity) AS total_qty
          FROM booking_commercials
          WHERE YEAR(bill_date) = 2021
          GROUP BY DATE_FORMAT(bill_date, '%Y-%m'), item_id
      ) AS inner_tbl
      GROUP BY month
  ) AS top_per_month
    ON top_per_month.month = mi.month
   AND top_per_month.max_qty = mi.total_qty

  UNION ALL

  SELECT mi.month, mi.item_id, it.item_name, mi.total_qty
  FROM (
      SELECT DATE_FORMAT(bill_date, '%Y-%m') AS month,
             item_id,
             SUM(item_quantity) AS total_qty
      FROM booking_commercials
      WHERE YEAR(bill_date) = 2021
      GROUP BY DATE_FORMAT(bill_date, '%Y-%m'), item_id
  ) AS mi
  JOIN items it ON it.item_id = mi.item_id
  JOIN (
      SELECT month, MIN(total_qty) AS min_qty
      FROM (
          SELECT DATE_FORMAT(bill_date, '%Y-%m') AS month,
                 item_id,
                 SUM(item_quantity) AS total_qty
          FROM booking_commercials
          WHERE YEAR(bill_date) = 2021
          GROUP BY DATE_FORMAT(bill_date, '%Y-%m'), item_id
      ) AS inner_tbl
      GROUP BY month
  ) AS bottom_per_month
    ON bottom_per_month.month = mi.month
   AND bottom_per_month.min_qty = mi.total_qty
) AS final
ORDER BY month, which;



5.Find the customers with the second highest bill value of each month of year 2021 
CREATE TEMPORARY TABLE bill_summary AS
SELECT
    bill_id,
    MONTH(bill_date) AS month_no,
    SUM(bc.item_quantity * i.item_rate) AS amount,
    MIN(booking_id) AS booking_id
FROM booking_commercials bc
JOIN items i ON i.item_id = bc.item_id
GROUP BY bill_id, MONTH(bill_date);



SELECT 
    bs.month_no,
    bs.bill_id,
    b.user_id,
    bs.amount
FROM bill_summary bs
JOIN bookings b ON bs.booking_id = b.booking_id
WHERE (bs.month_no, bs.amount) IN (
    SELECT month_no,
           (
              SELECT DISTINCT amount
              FROM bill_summary bs2
              WHERE bs2.month_no = bs1.month_no
              ORDER BY amount DESC
              LIMIT 1 OFFSET 1  
           ) AS second_highest
    FROM bill_summary bs1
);
