select * from logins;
select * from marketing_campaigns;
select *from support_tickets;
select * from transactions;
select * from uninstalls;
select * from users;

-- checking the null values present in tables
SELECT
  SUM(user_id IS NULL) AS user_id_nulls,
  SUM(login_date IS NULL) AS login_date_nulls,
  SUM(device IS NULL) AS phone_nulls,
  SUM(ip_address IS NULL) AS gender_nulls
FROM logins;

-- 1. How many active users in the last 30 days?
SELECT count(user_id) as total_login,
COUNT(DISTINCT user_id) AS active_users
FROM logins
WHERE login_date >= CURRENT_DATE - INTERVAL 30 day ;

-- 2. How many users are inactive for more than 60 days?
SELECT u.user_id, u.signup_date, u.city, l.last_login
FROM users u
LEFT JOIN (
    SELECT user_id, MAX(login_date) AS last_login
    FROM logins
    GROUP BY user_id
) l ON u.user_id = l.user_id
WHERE l.last_login IS NULL OR l.last_login < CURDATE() - INTERVAL 60 DAY;

-- 3. Users Who Uninstalled Within 30 Days of Signup
SELECT COUNT(*) AS early_uninstalls
FROM users u
JOIN uninstalls un ON u.user_id = un.user_id
WHERE uninstall_date <= DATE_ADD(signup_date, INTERVAL 30 DAY);

-- 4. Users with No Transactions in the Last 90 Days (Churned)
SELECT * FROM users u
LEFT JOIN (
    SELECT user_id, MAX(txn_date) AS last_txn
    FROM transactions
    GROUP BY user_id
) t ON u.user_id = t.user_id
WHERE last_txn IS NULL OR last_txn < CURDATE() - INTERVAL 90 DAY;

--  Monthly Churn Rate
SELECT  
    uninstall_month,
    COUNT(*) AS churned_users,
    COALESCE(txn_data.active_users, 0) AS active_users,
    ROUND(
        100 * COUNT(*) / COALESCE(txn_data.active_users, 1), 2
    ) AS churn_rate_percent
FROM (
    SELECT user_id, DATE_FORMAT(uninstall_date, '%Y-%m') AS uninstall_month
    FROM uninstalls
) AS u
LEFT JOIN (
    SELECT DATE_FORMAT(txn_date, '%Y-%m') AS txn_month, COUNT(*) AS active_users
    FROM transactions
    GROUP BY txn_month
) AS txn_data ON u.uninstall_month = txn_data.txn_month
GROUP BY uninstall_month
ORDER BY uninstall_month;

-- 6. Most Successful Campaign Type
SELECT 
    campaign_type,
    COUNT(*) AS total_sent,
    SUM(success) AS total_success,
    ROUND(100 * SUM(success) / COUNT(*), 2) AS success_rate_percent
FROM marketing_campaigns
GROUP BY campaign_type
ORDER BY success_rate_percent DESC;

-- 7. Users Who Returned After Uninstall When Sent a Campaign;
SELECT COUNT(DISTINCT c.user_id) AS returned_users
FROM marketing_campaigns c
JOIN logins l ON c.user_id = l.user_id
WHERE l.login_date > c.sent_date;

-- 8. Average Transaction Value by Type
SELECT 
    txn_type,
    ROUND(AVG(amount), 2) AS avg_amount,
    COUNT(*) AS txn_count
FROM transactions
WHERE status = 'Success'
GROUP BY txn_type;

-- 9. Top 5 Cities by Transaction Volume

SELECT 
    u.city,
    COUNT(t.txn_id) AS total_txns,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM users u
JOIN transactions t ON u.user_id = t.user_id
GROUP BY u.city
ORDER BY total_amount DESC
LIMIT 5;

-- 10. Users with More Than 3 Failed Transactions
SELECT user_id,
       COUNT(*) AS failed_txns
FROM transactions
WHERE status = 'Failed'
GROUP BY user_id
HAVING COUNT(*) > 3;

-- 11. Most Common Support Ticket Types
SELECT 
    issue_type,
    COUNT(*) AS total_tickets
FROM support_tickets
GROUP BY issue_type
ORDER BY total_tickets DESC;

-- 12. Unresolved Tickets That May Have Caused Uninstalls

SELECT COUNT(DISTINCT t.user_id) AS unresolved_tickets_and_uninstalled
FROM support_tickets t
JOIN uninstalls u ON t.user_id = u.user_id
WHERE t.resolved = 0;



