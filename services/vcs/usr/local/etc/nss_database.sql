#
# $Id: sample_database.sql,v 1.3 2004/07/21 17:53:32 cinergi Exp $
#
#                THIS DATABASE IS INTENDED FOR FreeBSD
#
# Use 'mysql -u root -p < sample_database.sql' to load this example into your
# MySQL server.
# This example will:
#   1) create a database called 'auth'
#   2) add three tables: 'users', 'groups' and 'grouplist'
#   3) add some data to each table
#   4) create two MySQL users ('nss-user' and 'nss-root') with appropriate
#      SELECT privs.
#
# With a properly-functioning libnss-mysql, you should be able to log into
# the system as 'cinergi' with a password of 'cinergi'.  'cinergi' should be
# a member of the group 'foobaz' as well.
#
# This is intended as an *example* and is perhaps not the best use of
# datatypes, space/size, data normalization, etc.
#

create database auth;
use auth;

# The tables ...

CREATE TABLE users (
  username varchar(16) NOT NULL,
  password varchar(34) NOT NULL default 'x',
  PRIMARY KEY  (username),
  KEY username (username)
) TYPE=InnoDB;
# or BDB, we need transaction here


# The permissions ...
GRANT USAGE ON *.* TO `nss-root`@`localhost` IDENTIFIED BY 'rootpass';
GRANT USAGE ON *.* TO `nss-user`@`localhost` IDENTIFIED BY 'userpass';

GRANT Select (`username`)
             ON `auth`.`users`
             TO 'nss-user'@'localhost';
GRANT Select (`username`, `password`)
             ON `auth`.`users`
             TO 'nss-root'@'localhost';
