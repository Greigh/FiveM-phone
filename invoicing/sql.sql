-- SQL file to create the invoices table
CREATE TABLE IF NOT EXISTS `invoices` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `sender_citizenid` varchar(50) NOT NULL,
    `sender_name` varchar(100) NOT NULL,
    `receiver_citizenid` varchar(50) NOT NULL,
    `receiver_name` varchar(100) NOT NULL,
    `amount` decimal(10, 2) NOT NULL,
    `description` text NOT NULL,
    `tax_rate` decimal(5, 4) NOT NULL DEFAULT 0.1000,
    `status` enum('pending', 'paid', 'expired') NOT NULL DEFAULT 'pending',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` timestamp NULL DEFAULT NULL,
    `paid_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `sender_citizenid` (`sender_citizenid`),
    KEY `receiver_citizenid` (`receiver_citizenid`),
    KEY `status` (`status`),
    KEY `created_at` (`created_at`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;