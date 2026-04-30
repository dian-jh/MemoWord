/*
Target Server: MySQL 5.7+ / 8.0
Description: AppleReader API V2-RK 冻结版数据库
*/


-- 须要先创立数据库后再执行SQL语句, 数据库名为ebook
-- 须要先创立数据库后再执行SQL语句，数据库名为ebook
-- 须要先创立数据库后再执行SQL语句，数据库名为ebook

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- 1. 用户模块
-- ----------------------------
CREATE TABLE IF NOT EXISTS `User` (
  `Id` CHAR(36) NOT NULL COMMENT '用户主键',
  `Username` VARCHAR(64) NOT NULL COMMENT '用户名',
  `Account` VARCHAR(64) NOT NULL COMMENT '登录账号（手机号/邮箱）',
  `PasswordHash` VARCHAR(256) NOT NULL COMMENT '密码哈希',
  `AvatarUrl` TEXT COMMENT '头像URL',
  `CreateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UK_Account` (`Account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户基础信息表';

-- ----------------------------
-- 2. 阅读目标与统计模块
-- ----------------------------
CREATE TABLE IF NOT EXISTS `ReadingTimeDaily` (
  `Id` CHAR(36) NOT NULL,
  `UserId` CHAR(36) NOT NULL,
  `Date` DATE NOT NULL COMMENT '统计日期（北京时间）',
  `Duration` INT NOT NULL DEFAULT '0' COMMENT '当日阅读时长（秒）',
  `TargetDuration` INT NOT NULL DEFAULT '300' COMMENT '当日目标时长（秒）',
  `IsAchieved` TINYINT(1) NOT NULL DEFAULT '0' COMMENT '是否达成目标',
  `CreateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UpdateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UK_User_Date` (`UserId`,`Date`),
  CONSTRAINT `FK_ReadingTime_User` FOREIGN KEY (`UserId`) REFERENCES `User` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='每日阅读时长统计';

CREATE TABLE IF NOT EXISTS `UserReadingStats` (
  `Id` CHAR(36) NOT NULL,
  `UserId` CHAR(36) NOT NULL,
  `CurrentStreakCount` INT NOT NULL DEFAULT '0' COMMENT '当前连续打卡天数',
  `LongestStreakCount` INT NOT NULL DEFAULT '0' COMMENT '最长连续打卡天数',
  `LastAchieveDate` DATE DEFAULT NULL COMMENT '最后一次达成目标日期',
  `UpdateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UK_UserId` (`UserId`),
  CONSTRAINT `FK_Stats_User` FOREIGN KEY (`UserId`) REFERENCES `User` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户阅读打卡统计';

-- ----------------------------
-- 3. 云端书库模块 (Reader Kit 版)
-- ----------------------------
CREATE TABLE IF NOT EXISTS `Books` (
  `Id` CHAR(36) NOT NULL COMMENT '图书主键',
  `UserId` CHAR(36) NOT NULL COMMENT '所属用户ID',
  `Title` VARCHAR(500) NOT NULL COMMENT '书名',
  `FileHash` VARCHAR(64) DEFAULT NULL COMMENT '文件MD5/SHA256(秒传用)',
  `FileUrl` VARCHAR(512) DEFAULT NULL COMMENT '云端书籍绝对地址',
  `Author` VARCHAR(256) DEFAULT NULL COMMENT '作者',
  `CoverUrl` TEXT COMMENT '封面URL',
  `Intro` TEXT COMMENT '简介',
  `Format` VARCHAR(16) NOT NULL COMMENT 'EPUB/TXT等',
  `ReaderBookKey` VARCHAR(128) NOT NULL COMMENT '客户端书籍唯一键',
  `FileName` VARCHAR(255) NOT NULL COMMENT '原文件名',
  `FileSize` BIGINT NOT NULL COMMENT '文件大小(字节)',
  `TotalCatalogCount` INT DEFAULT '0' COMMENT '目录项总数',
  `LastReadAt` DATETIME DEFAULT NULL COMMENT '最近阅读时间',
  `CreateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UpdateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `DeletedAt` DATETIME DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`Id`),
  UNIQUE KEY `UK_User_ReaderKey` (`UserId`,`ReaderBookKey`),
  KEY `IDX_LastRead` (`UserId`,`LastReadAt`),
  CONSTRAINT `FK_Books_User` FOREIGN KEY (`UserId`) REFERENCES `User` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书元信息表';

CREATE TABLE IF NOT EXISTS `BookCatalogs` (
  `Id` CHAR(36) NOT NULL,
  `BookId` CHAR(36) NOT NULL,
  `ParentId` CHAR(36) DEFAULT NULL,
  `Title` VARCHAR(500) NOT NULL,
  `OrderNum` INT NOT NULL,
  `DepthLevel` INT NOT NULL DEFAULT '0',
  `Href` VARCHAR(500) DEFAULT NULL COMMENT 'Reader Kit定位符',
  `Locator` VARCHAR(1000) DEFAULT NULL COMMENT '客户端恢复定位值',
  `CreateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  KEY `IDX_Book_Order` (`BookId`,`OrderNum`),
  CONSTRAINT `FK_Catalogs_Book` FOREIGN KEY (`BookId`) REFERENCES `Books` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='图书目录快照表';

-- ----------------------------
-- 4. 阅读进度模块
-- ----------------------------
CREATE TABLE IF NOT EXISTS `ReadingProgress` (
  `UserId` CHAR(36) NOT NULL,
  `BookId` CHAR(36) NOT NULL,
  `LocatorType` VARCHAR(32) NOT NULL COMMENT 'CFI/DOM_POS/PAGE_INDEX',
  `LocatorValue` VARCHAR(1000) NOT NULL COMMENT '定位值',
  `CatalogId` CHAR(36) DEFAULT NULL COMMENT '关联BookCatalogs.Id',
  `ProgressRatio` DECIMAL(5,4) NOT NULL DEFAULT '0.0000' COMMENT '进度0~1',
  `Version` INT NOT NULL DEFAULT '0' COMMENT '乐观锁版本',
  `UpdateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`UserId`,`BookId`),
  CONSTRAINT `FK_Progress_User` FOREIGN KEY (`UserId`) REFERENCES `User` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `FK_Progress_Book` FOREIGN KEY (`BookId`) REFERENCES `Books` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='阅读进度表';

-- ----------------------------
-- 5. 藏书夹模块
-- ----------------------------
CREATE TABLE IF NOT EXISTS `UserCollections` (
  `Id` CHAR(36) NOT NULL,
  `UserId` CHAR(36) NOT NULL,
  `Name` VARCHAR(128) NOT NULL,
  `SortOrder` INT NOT NULL DEFAULT '0',
  `CreateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  KEY `IDX_User_Sort` (`UserId`,`SortOrder`),
  CONSTRAINT `FK_Collections_User` FOREIGN KEY (`UserId`) REFERENCES `User` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='藏书夹表';

CREATE TABLE IF NOT EXISTS `BookCollectionMapping` (
  `CollectionId` CHAR(36) NOT NULL,
  `BookId` CHAR(36) NOT NULL,
  `UserId` CHAR(36) NOT NULL,
  `AddTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`CollectionId`,`BookId`),
  KEY `IDX_User_Book` (`UserId`,`BookId`),
  CONSTRAINT `FK_Mapping_Collection` FOREIGN KEY (`CollectionId`) REFERENCES `UserCollections` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `FK_Mapping_Book` FOREIGN KEY (`BookId`) REFERENCES `Books` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='藏书夹关联表';

-- ----------------------------
-- 6. 标注同步模块
-- ----------------------------
CREATE TABLE IF NOT EXISTS `Annotations` (
  `Id` CHAR(36) NOT NULL,
  `UserId` CHAR(36) NOT NULL,
  `BookId` CHAR(36) NOT NULL,
  `CatalogId` CHAR(36) DEFAULT NULL,
  `Locator` JSON NOT NULL COMMENT '存储start和end的CFI',
  `QuoteText` TEXT COMMENT '划线内容',
  `NoteContent` TEXT COMMENT '笔记内容',
  `Style` VARCHAR(32) DEFAULT 'YELLOW',
  `Type` VARCHAR(32) NOT NULL COMMENT 'HIGHLIGHT/NOTE/BOOKMARK',
  `Status` VARCHAR(32) DEFAULT 'ACTIVE' COMMENT 'ACTIVE/DELETED',
  `UpdatedAt` DATETIME NOT NULL COMMENT '客户端最后更新时间',
  `CreateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UpdateTime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  KEY `IDX_Query` (`UserId`,`BookId`,`UpdatedAt`),
  CONSTRAINT `FK_Anno_User` FOREIGN KEY (`UserId`) REFERENCES `User` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `FK_Anno_Book` FOREIGN KEY (`BookId`) REFERENCES `Books` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户标注表';

SET FOREIGN_KEY_CHECKS = 1;