CREATE TABLE IF NOT EXISTS `nd_property` (
    `property_id` VARCHAR(60) DEFAULT NULL,
    `property_groups` LONGTEXT DEFAULT ('[]'),
    `reset_groups_time` INT(11) DEFAULT NULL
);
