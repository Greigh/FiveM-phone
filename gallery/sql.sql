-- SQL file to create the gallery tables
CREATE TABLE IF NOT EXISTS `gallery_photos` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `owner_citizenid` varchar(50) NOT NULL,
    `owner_name` varchar(100) NOT NULL,
    `title` varchar(100) DEFAULT NULL,
    `description` text DEFAULT NULL,
    `url` text NOT NULL,
    `album_id` int(11) DEFAULT NULL,
    `privacy` enum('public', 'private') NOT NULL DEFAULT 'private',
    `file_size` int(11) NOT NULL DEFAULT 0,
    `file_type` varchar(10) NOT NULL,
    `metadata` json DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `owner_citizenid` (`owner_citizenid`),
    KEY `album_id` (`album_id`),
    KEY `privacy` (`privacy`),
    KEY `created_at` (`created_at`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gallery_albums` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `owner_citizenid` varchar(50) NOT NULL,
    `owner_name` varchar(100) NOT NULL,
    `name` varchar(50) NOT NULL,
    `description` text DEFAULT NULL,
    `cover_photo_id` int(11) DEFAULT NULL,
    `privacy` enum('public', 'private') NOT NULL DEFAULT 'private',
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `owner_citizenid` (`owner_citizenid`),
    KEY `privacy` (`privacy`),
    KEY `created_at` (`created_at`),
    FOREIGN KEY (`cover_photo_id`) REFERENCES `gallery_photos` (`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Add foreign key for photos to albums
ALTER TABLE `gallery_photos`
ADD FOREIGN KEY (`album_id`) REFERENCES `gallery_albums` (`id`) ON DELETE SET NULL;