-- SQL file to create the invoices table
CREATE TABLE IF NOT EXISTS `invoices` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `sender_citizenid` varchar(50) NOT NULL,
    `sender_name` varchar(100) NOT NULL,
    `sender_type` enum('player', 'business') NOT NULL DEFAULT 'player',
    `sender_business_id` int(11) DEFAULT NULL,
    `sender_business_name` varchar(100) DEFAULT NULL,
    `receiver_citizenid` varchar(50) NOT NULL,
    `receiver_name` varchar(100) NOT NULL,
    `receiver_type` enum('player', 'business') NOT NULL DEFAULT 'player',
    `receiver_business_id` int(11) DEFAULT NULL,
    `receiver_business_name` varchar(100) DEFAULT NULL,
    `amount` decimal(10, 2) NOT NULL,
    `description` text NOT NULL,
    `tax_rate` decimal(5, 4) NOT NULL DEFAULT 0.1000,
    `tax_amount` decimal(10, 2) NOT NULL DEFAULT 0.00,
    `commission_rate` decimal(5, 4) DEFAULT NULL,
    `commission_amount` decimal(10, 2) DEFAULT NULL,
    `commission_recipient_id` varchar(50) DEFAULT NULL,
    `commission_recipient_name` varchar(100) DEFAULT NULL,
    `commission_type` enum('flat', 'percentage') DEFAULT 'percentage',
    `total_amount` decimal(10, 2) NOT NULL,
    `net_amount` decimal(10, 2) NOT NULL COMMENT 'Amount after taxes and commissions',
    `invoice_number` varchar(50) DEFAULT NULL,
    `due_date` timestamp NULL DEFAULT NULL,
    `status` enum(
        'pending',
        'paid',
        'expired',
        'cancelled'
    ) NOT NULL DEFAULT 'pending',
    `payment_method` enum('cash', 'bank', 'business') DEFAULT 'bank',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` timestamp NULL DEFAULT NULL,
    `paid_at` timestamp NULL DEFAULT NULL,
    `notes` text DEFAULT NULL,
    `auto_pay_taxes` boolean DEFAULT false,
    `auto_pay_commission` boolean DEFAULT true,
    PRIMARY KEY (`id`),
    KEY `sender_citizenid` (`sender_citizenid`),
    KEY `receiver_citizenid` (`receiver_citizenid`),
    KEY `sender_business_id` (`sender_business_id`),
    KEY `receiver_business_id` (`receiver_business_id`),
    KEY `commission_recipient_id` (`commission_recipient_id`),
    KEY `status` (`status`),
    KEY `created_at` (`created_at`),
    KEY `invoice_number` (`invoice_number`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Create businesses table if it doesn't exist (for basic business support)
CREATE TABLE IF NOT EXISTS `businesses` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `owner_citizenid` varchar(50) NOT NULL,
    `business_type` varchar(50) DEFAULT NULL,
    `tax_id` varchar(50) DEFAULT NULL,
    `bank_account` varchar(50) DEFAULT NULL,
    `phone` varchar(20) DEFAULT NULL,
    `email` varchar(100) DEFAULT NULL,
    `address` text DEFAULT NULL,
    `status` enum(
        'active',
        'inactive',
        'suspended'
    ) NOT NULL DEFAULT 'active',
    `default_commission_rate` decimal(5, 4) DEFAULT 0.0500 COMMENT 'Default 5% commission',
    `auto_tax_payment` boolean DEFAULT true,
    `tax_exempt` boolean DEFAULT false,
    `commission_account` varchar(50) DEFAULT NULL COMMENT 'Account for receiving commissions',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `owner_citizenid` (`owner_citizenid`),
    KEY `status` (`status`),
    UNIQUE KEY `name` (`name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Create commission tracking table
CREATE TABLE IF NOT EXISTS `invoice_commissions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `invoice_id` int(11) NOT NULL,
    `recipient_citizenid` varchar(50) NOT NULL,
    `recipient_name` varchar(100) NOT NULL,
    `recipient_type` enum(
        'player',
        'business',
        'government'
    ) NOT NULL DEFAULT 'player',
    `commission_type` enum('flat', 'percentage') NOT NULL DEFAULT 'percentage',
    `commission_rate` decimal(5, 4) DEFAULT NULL,
    `commission_amount` decimal(10, 2) NOT NULL,
    `status` enum(
        'pending',
        'paid',
        'cancelled'
    ) NOT NULL DEFAULT 'pending',
    `paid_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `invoice_id` (`invoice_id`),
    KEY `recipient_citizenid` (`recipient_citizenid`),
    KEY `status` (`status`),
    FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Create tax payments table
CREATE TABLE IF NOT EXISTS `invoice_tax_payments` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `invoice_id` int(11) NOT NULL,
    `tax_type` varchar(50) NOT NULL DEFAULT 'sales_tax',
    `tax_rate` decimal(5, 4) NOT NULL,
    `tax_amount` decimal(10, 2) NOT NULL,
    `paid_to` varchar(100) DEFAULT 'government',
    `status` enum('pending', 'paid', 'exempt') NOT NULL DEFAULT 'pending',
    `paid_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `invoice_id` (`invoice_id`),
    KEY `status` (`status`),
    FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;