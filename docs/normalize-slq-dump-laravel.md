




```sh
ssh -i ~/.ssh/id_rsa -L 5433:127.0.0.1:5432 ploi@165.22.183.51 -N
# Si tu private key está en otra ruta, cambia ~/.ssh/id_rsa por la ruta correcta.
ssh -i ~/.ssh/id_rsa ploi@165.22.183.51 "psql -U ploi -d goroam_staging" < dump.sql



```

Importat dump desde local sin password (porque es no seguro )
ssh -i ~/.ssh/id_rsa ploi@IP_SERVIDOR "psql -U USER -d DATABASE" < dump.sql



el dump normalizarlo para la nueva base 
para evitar el permission denied for table users 

El dump trajo tablas con un owner distinto al usuario que Laravel usa para conectarse (definido en .env como DB_USERNAME).

cat /home/ploi/PROYECTO/.env | grep DB_

```sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO db_user;
GRANT USAGE ON SCHEMA public TO db_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO db_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO db_user;
```



## resumend de este pedo 

ssh -i ~/.ssh/KEY USER@HOST "psql -U DBUSER -d DBNAME" < dump.sql

> puedo hacer un script quer normalize el dump.sql para evitar que tenga pedos 
a donde la voy a llevar? 


GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO DBUSER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO DBUSER;


### cambiar owner de tablas en sql
```psql
DO $$ DECLARE r RECORD;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' OWNER TO goroam_staging';
  END LOOP;
END $$;
```



Permiso	Sirve para
GRANT SELECT/INSERT/UPDATE/DELETE
Operaciones DML (datos)
OWNER
Operaciones DDL (ALTER, DROP, RENAME)



