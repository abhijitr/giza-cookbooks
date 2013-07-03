## Notes
### Doing a direct database import with Solr

- Have access to a Pickie Postgres database
- Add the Postgres Java JDBC driver to Solr
  - Download `http://jdbc.postgresql.org/download/postgresql-9.2-1002.jdbc4.jar`
  - Copy it to `/opt/solr/pickie/lib/ext` (create the `ext` folder if it does not exist)
- Update `/opt/solr/pickie/solr/collection1/conf/data-import-config.xml`
  - Update `url`, `user`, and `password` attributes
- Start Solr
- Do the import
  - Navigate to [http://localhost:8983/solr/dataimport?command=full-import](http://localhost:8983/solr/dataimport?command=full-import)
  - For status, go to [http://localhost:8983/solr/dataimport](http://localhost:8983/solr/dataimport)
- More info
  - [http://wiki.apache.org/solr/DIHQuickStart](http://wiki.apache.org/solr/DIHQuickStart)
  - [http://wiki.apache.org/solr/DataImportHandler](http://wiki.apache.org/solr/DataImportHandler)
