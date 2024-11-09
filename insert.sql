CREATE TABLE `community_services` (
    `identifier` varchar(48) NOT NULL PRIMARY KEY,
    `tasksCount` tinyint(4) NOT NULL DEFAULT 1,
    `normalClothes` json NOT NULL DEFAULT '[]',
    `pedItems` json NOT NULL DEFAULT '[]'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
