-- SQL file to create the business_cards table
CREATE TABLE IF NOT EXISTS `business_cards` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `owner_citizenid` varchar(50) NOT NULL,
    `owner_name` varchar(100) NOT NULL,
    `title` varchar(50) NOT NULL,
    `description` text NOT NULL,
    `job_title` varchar(100) DEFAULT NULL,
    `phone` varchar(20) DEFAULT NULL,
    `email` varchar(100) DEFAULT NULL,
    `template` varchar(50) NOT NULL DEFAULT 'Professional',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `owner_citizenid` (`owner_citizenid`),
    KEY `created_at` (`created_at`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;