CREATE DATABASE IF NOT EXISTS vulncorp_prod;
CREATE DATABASE IF NOT EXISTS vulncorp_hr;
CREATE DATABASE IF NOT EXISTS vulncorp_auth;

USE vulncorp_prod;
CREATE TABLE IF NOT EXISTS employees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50), full_name VARCHAR(100),
  email VARCHAR(100), department VARCHAR(50),
  salary DECIMAL(10,2), ssn VARCHAR(20)
);
INSERT IGNORE INTO employees VALUES
(1,'john.doe','John Doe','john.doe@vulncorp.local','IT',95000.00,'123-45-6789'),
(2,'jane.smith','Jane Smith','jane.smith@vulncorp.local','Dev',88000.00,'234-56-7890'),
(3,'admin','Admin User','admin@vulncorp.local','IT',110000.00,'345-67-8901'),
(4,'sysadmin','Sys Admin','sysadmin@vulncorp.local','IT',120000.00,'456-78-9012');

CREATE TABLE IF NOT EXISTS internal_credentials (
  id INT AUTO_INCREMENT PRIMARY KEY,
  service VARCHAR(50), host VARCHAR(50),
  username VARCHAR(50), password VARCHAR(100)
);
INSERT IGNORE INTO internal_credentials VALUES
(1,'SSH','192.168.1.10','john.doe','Corp@Admin2024'),
(2,'RDP','192.168.1.10','Administrator','Corp@Admin2024'),
(3,'MSSQL','192.168.1.20','sa','sa'),
(4,'SSH','192.168.1.30','jenkins','jenkins123'),
(5,'Rsync','192.168.1.50','backupadmin','backup123'),
(6,'GitLab','192.168.1.30','root','gitlab_root_pass');

CREATE TABLE IF NOT EXISTS secret_flags (id INT AUTO_INCREMENT PRIMARY KEY, flag VARCHAR(100));
INSERT IGNORE INTO secret_flags VALUES
(1,'VULN{mysql_d3fault_cr3ds}'),
(2,'VULN{pii_d4t4_3xfil}');
FLUSH PRIVILEGES;
