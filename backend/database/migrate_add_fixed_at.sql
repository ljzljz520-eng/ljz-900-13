-- 为 records 增加整改图上传时间字段（可重复执行，缺啥补啥）
-- 执行示例：
-- docker compose exec -T db mysql -uroot -proot hygiene_audit < backend/database/migrate_add_fixed_at.sql

SET NAMES utf8mb4;
USE hygiene_audit;

SET @db = DATABASE();

SET @sql = (SELECT IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'records' AND COLUMN_NAME = 'fixed_at') = 0,
  'ALTER TABLE `records` ADD COLUMN `fixed_at` datetime DEFAULT NULL AFTER `fix_image`',
  'SELECT 1'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 回填历史数据：已上传整改图但没有 fixed_at 的记录，用 created_at 兜底
UPDATE `records`
SET `fixed_at` = `created_at`
WHERE `fixed_at` IS NULL AND `fix_image` IS NOT NULL AND `fix_image` <> '';
