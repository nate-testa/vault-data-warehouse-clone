--Create User with AD Login

USE vault_edw;

 -- GRANT CONTROL ON SCHEMA::ROLE TO [User];   --Grants full access on schema except create table

--Yunus
CREATE USER [Yunus.Mohammed@Vault.Insurance] FROM EXTERNAL PROVIDER;

ALTER ROLE db_datareader ADD MEMBER [Yunus.Mohammed@Vault.Insurance]; 
ALTER ROLE db_datawriter ADD MEMBER [Yunus.Mohammed@Vault.Insurance]; 
ALTER ROLE db_ddladmin ADD MEMBER [Yunus.Mohammed@Vault.Insurance]; 

GRANT EXECUTE ON SCHEMA::edw_core TO [Yunus.mohammed@vault.insurance];
GRANT EXECUTE ON SCHEMA::edw_integration TO [Yunus.mohammed@vault.insurance];

GRANT SHOWPLAN TO [Yunus.Mohammed@Vault.Insurance];

-- Rushin
CREATE USER [Rushin.Shah@vault.insurance] FROM EXTERNAL PROVIDER;


ALTER ROLE db_datareader ADD MEMBER [Rushin.Shah@vault.insurance]; 
ALTER ROLE db_datawriter ADD MEMBER [Rushin.Shah@vault.insurance]; 
ALTER ROLE db_ddladmin ADD MEMBER [Rushin.Shah@vault.insurance]; 

GRANT EXECUTE ON SCHEMA::edw_core TO [Rushin.Shah@vault.insurance];
GRANT EXECUTE ON SCHEMA::edw_integration TO [Rushin.Shah@vault.insurance];

-- Hernando

CREATE USER [Hernando.Gonzalez.Garcia@Vault.Insurance] FROM EXTERNAL PROVIDER;


ALTER ROLE db_datareader ADD MEMBER [Hernando.Gonzalez.Garcia@Vault.Insurance]; 
ALTER ROLE db_datawriter ADD MEMBER [Hernando.Gonzalez.Garcia@Vault.Insurance]; 
ALTER ROLE db_ddladmin ADD MEMBER [Hernando.Gonzalez.Garcia@Vault.Insurance]; 

GRANT EXECUTE ON SCHEMA::edw_core TO [Hernando.Gonzalez.Garcia@Vault.Insurance];
GRANT EXECUTE ON SCHEMA::edw_integration TO [Hernando.Gonzalez.Garcia@Vault.Insurance];


-- Architha

CREATE USER [Architha.Gudimalla@Vault.Insurance] FROM EXTERNAL PROVIDER;


ALTER ROLE db_datareader ADD MEMBER [Architha.Gudimalla@Vault.Insurance]; 
ALTER ROLE db_datawriter ADD MEMBER [Architha.Gudimalla@Vault.Insurance]; 
ALTER ROLE db_ddladmin ADD MEMBER [Architha.Gudimalla@Vault.Insurance]; 

GRANT EXECUTE ON SCHEMA::edw_core TO [Architha.Gudimalla@Vault.Insurance];
GRANT EXECUTE ON SCHEMA::edw_integration TO [Architha.Gudimalla@Vault.Insurance];

--Alberto


CREATE USER [alberto.valbuena@vault.insurance] FROM EXTERNAL PROVIDER;


ALTER ROLE db_datareader ADD MEMBER [alberto.valbuena@vault.insurance]; 
ALTER ROLE db_datawriter ADD MEMBER [alberto.valbuena@vault.insurance]; 
ALTER ROLE db_ddladmin ADD MEMBER [alberto.valbuena@vault.insurance]; 

GRANT EXECUTE ON SCHEMA::edw_core TO [alberto.valbuena@vault.insurance];
GRANT EXECUTE ON SCHEMA::edw_integration TO [alberto.valbuena@vault.insurance];


-- Tuba

CREATE USER [Tuba.Mohsin@Vault.Insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [Tuba.Mohsin@Vault.Insurance]; 
ALTER ROLE db_datawriter ADD MEMBER [Tuba.Mohsin@Vault.Insurance]; 
ALTER ROLE db_ddladmin ADD MEMBER [Tuba.Mohsin@Vault.Insurance]; 

GRANT EXECUTE ON SCHEMA::edw_core TO [Tuba.Mohsin@Vault.Insurance];
GRANT EXECUTE ON SCHEMA::edw_integration TO [Tuba.Mohsin@Vault.Insurance];


-- Create READ ONLY Role


CREATE ROLE db_edwread;
-- ALTER ROLE db_edwread WITH DEFAULT_SCHEMA = edw_core; not working; works for user only

GRANT SELECT ON SCHEMA::edw_core TO db_edwread;


CREATE ROLE db_edw_integration_read;
-- ALTER ROLE db_edw_integration_read WITH DEFAULT_SCHEMA = edw_integration;

GRANT SELECT ON SCHEMA::edw_integration TO db_edw_integration_read;

CREATE ROLE db_edw_cat_model_read;
-- ALTER ROLE db_edw_integration_read WITH DEFAULT_SCHEMA = edw_integration;

GRANT SELECT ON SCHEMA::edw_cat_model TO db_edw_cat_model_read;

-- Analysts


CREATE USER [omar.rodriguez@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [omar.rodriguez@vault.insurance];
ALTER ROLE db_edw_cat_model_read ADD MEMBER [omar.rodriguez@vault.insurance];

CREATE USER [olivia.layton@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [olivia.layton@vault.insurance];
ALTER ROLE db_edw_cat_model_read ADD MEMBER [olivia.layton@vault.insurance];

CREATE USER [tiffany.terlizzi@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [tiffany.terlizzi@vault.insurance];

CREATE USER [tyler.martin@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [tyler.martin@vault.insurance];

CREATE USER [casandra.lane@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [casandra.lane@vault.insurance];
ALTER ROLE db_edw_cat_model_read ADD MEMBER [casandra.lane@vault.insurance];

CREATE USER [ryan.knight@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [ryan.knight@vault.insurance];
ALTER ROLE db_edw_cat_model_read ADD MEMBER [ryan.knight@vault.insurance];

CREATE USER [carlota.cabral@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [carlota.cabral@vault.insurance];

CREATE USER [collette.naddeo@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [collette.naddeo@vault.insurance];

GRANT ALTER,EXECUTE,SELECT,INSERT,UPDATE,DELETE ON SCHEMA::edw_cat_model TO [collette.naddeo@vault.insurance];
GRANT CREATE TABLE TO [collette.naddeo@vault.insurance];

CREATE USER [andrew.chan@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [andrew.chan@vault.insurance];
ALTER ROLE db_edw_cat_model_read ADD MEMBER [andrew.chan@vault.insurance];

CREATE USER [abraham.garcia@Vault.Insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [abraham.garcia@Vault.Insurance];
GRANT ALTER,EXECUTE,SELECT,INSERT,UPDATE,DELETE ON SCHEMA::edw_cat_model TO [abraham.garcia@Vault.Insurance];

CREATE USER [Diego.Robledo@Vault.Insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [Diego.Robledo@Vault.Insurance];
GRANT ALTER,EXECUTE,SELECT,INSERT,UPDATE,DELETE ON SCHEMA::edw_cat_model TO [Diego.Robledo@Vault.Insurance];

CREATE USER [zach.suter@vault.insurance] FROM EXTERNAL PROVIDER;
ALTER ROLE db_edwread ADD MEMBER [zach.suter@vault.insurance];


-- Create Service Users

-- Airflow user
USE MASTER;
-- Create a login for the user
CREATE LOGIN svc_airflow WITH PASSWORD = 'V@ult22$';

-- Create a user mapped to the login
CREATE USER svc_airflow FOR LOGIN svc_airflow;

ALTER ROLE db_datareader ADD MEMBER [svc_airflow]; 
ALTER ROLE db_datawriter ADD MEMBER [svc_airflow]; 
ALTER ROLE db_ddladmin ADD MEMBER [svc_airflow]; 

GRANT EXECUTE ON SCHEMA::edw_core TO [svc_airflow];
GRANT EXECUTE ON SCHEMA::edw_integration TO [svc_airflow];

-- Azure Git user

USE MASTER;
-- Create a login for the user
CREATE LOGIN svc_azuregit WITH PASSWORD = 'V@ult22$';

-- Create a user mapped to the login
CREATE USER svc_azuregit FOR LOGIN svc_azuregit;
ALTER ROLE db_datareader ADD MEMBER [svc_azuregit]; 
ALTER ROLE db_datawriter ADD MEMBER [svc_azuregit]; 
ALTER ROLE db_ddladmin ADD MEMBER [svc_azuregit]; 

GRANT EXECUTE ON SCHEMA::edw_core TO [svc_azuregit];
GRANT EXECUTE ON SCHEMA::edw_integration TO [svc_azuregit];

--Create VSP User

CREATE LOGIN svc_vsp WITH PASSWORD = 'V@ult23$';

CREATE USER svc_vsp FOR LOGIN svc_vsp;
ALTER ROLE db_edw_integration_read ADD MEMBER [svc_vsp];
GRANT EXECUTE ON SCHEMA::edw_integration TO svc_vsp;

--Create Tableau User

CREATE LOGIN svc_tableau WITH PASSWORD = 'V@ult23$';

CREATE USER svc_tableau FOR LOGIN svc_tableau;
ALTER ROLE db_edwread ADD MEMBER [svc_tableau];




