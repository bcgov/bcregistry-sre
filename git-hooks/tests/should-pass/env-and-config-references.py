APP_DB_PASSWORD = os.getenv("DATABASE_PASSWORD", "")
DB_PASSWORD = os.environ.get("DATABASE_PASSWORD")
engine = create_engine(user=config.DB_USER, password=config.APP_DB_PASSWORD)
connect(password=DB_PASSWORD)
self.password = settings.SFTP_PASSWORD
