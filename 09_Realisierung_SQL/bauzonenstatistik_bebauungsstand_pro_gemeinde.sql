SELECT
  ol.bfs_nr,
  ol.gemeindename,
  ol.grundnutzung_typ_kt,
  (SELECT SUM(flaeche) FROM arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_mit_zonen_ohne_lsgrenzen WHERE bfs_nr = ol.bfs_nr AND bebauungsstand = 'bebaut' AND grundnutzung_typ_kt = ol.grundnutzung_typ_kt) AS bebaut_mit_zonen_ohne_lsgrenzen,
  (SELECT SUM(flaeche) FROM arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_mit_zonen_ohne_lsgrenzen WHERE bfs_nr = ol.bfs_nr AND bebauungsstand = 'unbebaut' AND grundnutzung_typ_kt = ol.grundnutzung_typ_kt) AS unbebaut_mit_zonen_ohne_lsgrenzen,
  (SELECT SUM(flaeche) FROM arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_mit_zonen_und_lsgrenzen WHERE bfs_nr = ol.bfs_nr AND bebauungsstand = 'bebaut' AND grundnutzung_typ_kt = ol.grundnutzung_typ_kt) AS bebaut_mit_zonen_und_lsgrenzen,
  (SELECT SUM(flaeche) FROM arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_mit_zonen_und_lsgrenzen WHERE bfs_nr = ol.bfs_nr AND bebauungsstand = 'unbebaut' AND grundnutzung_typ_kt = ol.grundnutzung_typ_kt) AS unbebaut_mit_zonen_und_lsgrenzen
FROM arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_mit_zonen_ohne_lsgrenzen ol
GROUP BY ol.bfs_nr, ol.gemeindename, ol.grundnutzung_typ_kt
ORDER BY ol.bfs_nr, ol.grundnutzung_typ_kt
;
