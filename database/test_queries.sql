-- ================================================================
-- Test Queries for Database Design Document Screenshots
-- Team: CodeCrafters
-- Purpose: Generate real query results for documentation
-- ================================================================

USE momo_sms_db;

-- ================================================================
-- SECTION 1: Basic Query Demonstrations
-- ================================================================

-- Query 1: User Transaction History
SELECT 
    'Query 1: User Transaction History for +250788123456' AS query_title;

SELECT * FROM v_transaction_details 
WHERE sender_phone = '+250788123456' OR receiver_phone = '+250788123456'
ORDER BY transaction_date DESC
LIMIT 5;

-- Query 2: Daily Transaction Volume Analysis
SELECT 
    'Query 2: Daily Transaction Volume (Last 7 Days)' AS query_title;

SELECT 
    DATE(transaction_date) as transaction_date,
    COUNT(*) as transaction_count,
    SUM(amount) as total_volume,
    AVG(amount) as average_amount,
    SUM(fee_amount) as total_fees
FROM transactions 
WHERE status = 'SUCCESS' 
    AND transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
GROUP BY DATE(transaction_date)
ORDER BY transaction_date DESC;

-- ================================================================
-- SECTION 2: Advanced Analytics Demonstrations
-- ================================================================

-- Query 3: Top Users by Transaction Volume
SELECT 
    'Query 3: Top 5 Users by Total Transaction Volume' AS query_title;

SELECT 
    u.full_name,
    u.phone_number,
    COUNT(*) as transaction_count,
    SUM(CASE WHEN t.sender_user_id = u.user_id THEN t.amount ELSE 0 END) as total_sent,
    SUM(CASE WHEN t.receiver_user_id = u.user_id THEN t.amount ELSE 0 END) as total_received,
    (SUM(CASE WHEN t.sender_user_id = u.user_id THEN t.amount ELSE 0 END) + 
     SUM(CASE WHEN t.receiver_user_id = u.user_id THEN t.amount ELSE 0 END)) as total_volume
FROM users u
JOIN transactions t ON (u.user_id = t.sender_user_id OR u.user_id = t.receiver_user_id)
WHERE t.status = 'SUCCESS'
GROUP BY u.user_id, u.full_name, u.phone_number
ORDER BY total_volume DESC
LIMIT 5;

-- Query 4: Category Performance Analysis
SELECT 
    'Query 4: Transaction Category Performance Analysis' AS query_title;

SELECT 
    c.category_name,
    c.category_code,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_volume,
    AVG(t.amount) as average_amount,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions WHERE status = 'SUCCESS')), 2) as percentage_of_transactions,
    ROUND((SUM(t.amount) * 100.0 / (SELECT SUM(amount) FROM transactions WHERE status = 'SUCCESS')), 2) as percentage_of_volume
FROM transaction_categories c
JOIN transactions t ON c.category_id = t.category_id
WHERE t.status = 'SUCCESS'
GROUP BY c.category_id, c.category_name, c.category_code
ORDER BY total_volume DESC;

-- ================================================================
-- SECTION 3: System Monitoring Demonstrations
-- ================================================================

-- Query 5: System Logs Analysis
SELECT 
    'Query 5: System Error Analysis (Last 7 Days)' AS query_title;

SELECT 
    DATE(timestamp) as log_date,
    log_level,
    log_source,
    COUNT(*) as log_count,
    MIN(timestamp) as first_occurrence,
    MAX(timestamp) as last_occurrence
FROM system_logs
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(timestamp), log_level, log_source
ORDER BY log_date DESC, log_count DESC;

-- ================================================================
-- SECTION 4: Security Constraint Demonstrations
-- ================================================================

-- Constraint Test 1: Phone Number Validation
SELECT 
    'Constraint Test 1: Phone Number Validation' AS test_title;

-- This should show existing valid phone numbers
SELECT phone_number, full_name, account_status 
FROM users 
ORDER BY created_at DESC;

-- Constraint Test 2: Transaction Amount Validation
SELECT 
    'Constraint Test 2: Transaction Amounts (All Positive)' AS test_title;

SELECT transaction_id, amount, fee_amount, status
FROM transactions 
WHERE amount > 0 AND fee_amount >= 0
ORDER BY amount DESC
LIMIT 10;

-- Constraint Test 3: Business Logic - No Self Transactions
SELECT 
    'Constraint Test 3: Verify No Self-Transactions' AS test_title;

SELECT 
    transaction_id,
    sender_user_id,
    receiver_user_id,
    CASE 
        WHEN sender_user_id = receiver_user_id THEN 'SELF_TRANSACTION'
        WHEN sender_user_id IS NULL OR receiver_user_id IS NULL THEN 'NULL_USER_ALLOWED'
        ELSE 'VALID_DIFFERENT_USERS'
    END as validation_status
FROM transactions
ORDER BY transaction_id;

-- ================================================================
-- SECTION 5: Performance Index Demonstrations
-- ================================================================

-- Index Performance Test 1: User Lookup by Phone
SELECT 
    'Index Performance Test 1: User Lookup by Phone Number' AS performance_test;

EXPLAIN SELECT user_id, full_name, account_status 
FROM users 
WHERE phone_number = '+250788123456';

-- Index Performance Test 2: Transaction Date Range Query
SELECT 
    'Index Performance Test 2: Transaction Date Range Query' AS performance_test;

EXPLAIN SELECT COUNT(*), SUM(amount) 
FROM transactions 
WHERE transaction_date >= '2024-09-01' 
  AND transaction_date <= '2024-09-30'
  AND status = 'SUCCESS';

-- Index Performance Test 3: Category Analysis Query
SELECT 
    'Index Performance Test 3: Category-Based Analysis' AS performance_test;

EXPLAIN SELECT c.category_name, COUNT(*), AVG(t.amount)
FROM transactions t
JOIN transaction_categories c ON t.category_id = c.category_id
WHERE t.status = 'SUCCESS'
GROUP BY c.category_id, c.category_name;

-- ================================================================
-- SECTION 6: Database Statistics and Health Check
-- ================================================================

-- Database Statistics
SELECT 
    'Database Statistics and Health Check' AS stats_title;

SELECT 
    'Table Statistics' as info_type,
    'users' as table_name, 
    COUNT(*) as record_count 
FROM users
UNION ALL
SELECT 'Table Statistics', 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'Table Statistics', 'transaction_categories', COUNT(*) FROM transaction_categories
UNION ALL
SELECT 'Table Statistics', 'system_logs', COUNT(*) FROM system_logs
UNION ALL
SELECT 'Table Statistics', 'user_transaction_roles', COUNT(*) FROM user_transaction_roles
UNION ALL
SELECT 'Table Statistics', 'transaction_tags', COUNT(*) FROM transaction_tags
UNION ALL
SELECT 'Table Statistics', 'transaction_tag_assignments', COUNT(*) FROM transaction_tag_assignments;

-- Data Quality Checks
SELECT 
    'Data Quality Check: Transaction Integrity' AS quality_check;

SELECT 
    COUNT(*) as total_transactions,
    COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) as successful_transactions,
    COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending_transactions,
    COUNT(CASE WHEN status = 'FAILED' THEN 1 END) as failed_transactions,
    ROUND(COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) * 100.0 / COUNT(*), 2) as success_rate_percentage
FROM transactions;

-- ================================================================
-- SECTION 7: Stored Procedure Demonstration
-- ================================================================

-- Test GetUserTransactionHistory stored procedure
SELECT 
    'Stored Procedure Test: GetUserTransactionHistory for User ID 1' AS procedure_test;

CALL GetUserTransactionHistory(1, 10);

-- Test GetDailyTransactionSummary stored procedure
SELECT 
    'Stored Procedure Test: GetDailyTransactionSummary for 2024-09-17' AS procedure_test;

CALL GetDailyTransactionSummary('2024-09-17');

-- ================================================================
-- END OF TEST QUERIES
-- ================================================================

SELECT 'All test queries completed successfully!' AS final_message,
       NOW() as execution_time;