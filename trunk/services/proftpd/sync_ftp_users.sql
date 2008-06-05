CREATE DATABASE IF NOT EXISTS ftp_users;
use ftp_users;
DROP TABLE IF EXISTS tmp_groups, tmp_users;

CREATE TABLE IF NOT EXISTS `groups` (
  `groupname` varchar(30) NOT NULL,
  `gid` int(11) NOT NULL,
  `members` varchar(255) default NULL,
  UNIQUE KEY `unique_row` (`gid`,`members`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `users` (
  `userid` varchar(30) NOT NULL,
  `passwd` varchar(80) NOT NULL,
  `uid` int(11) default NULL,
  `gid` int(11) default NULL,
  `homedir` varchar(255) default NULL,
  `shell` varchar(255) default NULL,
  UNIQUE KEY `userid` (`userid`),
  UNIQUE KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE `tmp_groups` (
  `groupname` varchar(30) NOT NULL,
  `gid` int(11) NOT NULL,
  `members` varchar(255) default NULL,
  UNIQUE KEY `unique_row` (`gid`,`members`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `tmp_users` (
  `userid` varchar(30) NOT NULL,
  `passwd` varchar(80) NOT NULL,
  `uid` int(11) default NULL,
  `gid` int(11) default NULL,
  `homedir` varchar(255) default NULL,
  `shell` varchar(255) default NULL,
  UNIQUE KEY `userid` (`userid`),
  UNIQUE KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


INSERT tmp_users (userid, passwd, uid, homedir, shell) SELECT login, salted_password, id, '%%FTP_HOME%%', '/usr/bin/nologin' FROM `of_development`.users;
INSERT IGNORE tmp_groups SELECT t6.name, t6.id, t4.login FROM `of_development`.functions t1 LEFT JOIN `of_development`.`roles_functions` t2 ON t1.id=t2.function_id LEFT JOIN `of_development`.roles_users t3 ON t2.role_id=t3.role_id LEFT JOIN `of_development`.users t4 ON t3.user_id=t4.id LEFT JOIN `of_development`.roles t5 ON t2.role_id=t5.id LEFT JOIN `of_development`.projects t6 ON t5.authorizable_id=t6.id  WHERE t1.name='ftp_login' ORDER BY t6.name, t4.login;

DROP TABLE IF EXISTS old_groups, old_users;

ALTER TABLE groups RENAME AS old_groups;
ALTER TABLE users RENAME AS old_users;

ALTER TABLE tmp_groups RENAME AS groups;
ALTER TABLE tmp_users RENAME AS users;
