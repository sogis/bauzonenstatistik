java -jar /opt/ili2pg/ili2pg-4.3.1/ili2pg.jar \
--dbschema arp_auswertung_nutzungsplanung_pub --models SO_ARP_Auswertungen_Nutzungsplanung_Publikation_20210126 --modeldir '/home/bjsvwneu/sogis/bauzonenstatistik/07_Datenmodell/;https://models.geo.admin.ch;http://geo.so.ch/models/' \
--defaultSrsCode 2056 --strokeArcs --createGeomIdx --createFk --createFkIdx --createEnumTabs --createEnumTabsWithId --beautifyEnumDispName --createMetaInfo --createUnique \
--createNumChecks --coalesceMultiSurface --nameByTopic \
--createscript arp_auswertung_nutzungsplanung_pub.sql
