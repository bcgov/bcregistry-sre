password = cfg.DB_PASSWORD_COLIN_MIGR
ora_password = cfg.DB_PASSWORD_COLIN_ORACLE
engine = connect(password=app.config["BTR_DB_PASSWORD"], user=user)
password = pm.environment.get("password");
if (typeof password === 'string') password = Buffer.from(password)
