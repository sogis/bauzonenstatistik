-- zuerst Tabelle leeren
DELETE FROM
  arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_liegenschaft_nach_bebauungsstand
 WHERE bfs_nr = 2457;
-- wieder befüllen
INSERT INTO
  arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_liegenschaft_nach_bebauungsstand
WITH
-- Nutzungszonen
nutzzon AS (
  SELECT
    geometrie,
    typ_kt,
    bfs_nr
  FROM arp_npl_pub.nutzungsplanung_grundnutzung
    WHERE
      typ_code_kommunal < 2000
      AND typ_kt NOT IN ('N160_Gruen_und_Freihaltezone_innerhalb_Bauzone','N161_kommunale_Uferschutzzone_innerhalb_Bauzone','N169_weitere_eingeschraenkte_Bauzonen','N180_Verkehrszone_Stras-se','N181_Verkehrszone_Bahnareal','N182_Verkehrszone_Flugplatzareal','N189_weitere_Verkehrszonen')
),
-- unbebaute Flächen
unbeb_fl AS (
  SELECT
    t_id,
    geometrie
  FROM
    arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_mit_zonen_ohne_lsgrenzen
   WHERE
    bebauungsstand = 'unbebaut'
),
-- Liegenschaften
gr_tmp AS (
  SELECT
   gru.t_id,
   gru.t_ili_tid,
   gru.egrid AS egris_egrid,
   gru.nummer,
   gru.bfs_nr,
   gem.gemeindename,
   array_to_string(array_agg(DISTINCT nutzzon.typ_kt ORDER BY nutzzon.typ_kt),',') AS grundnutzung_typ_kt,
   gru.flaechenmass AS flaeche,
   ST_Multi(ST_CollectionExtract(ST_Intersection(gru.geometrie,ST_Union(nutzzon.geometrie,0.001),0.001),3)) AS geometrie
  FROM agi_mopublic_pub.mopublic_grundstueck gru
   LEFT JOIN nutzzon ON ST_Intersects(gru.geometrie, nutzzon.geometrie)
   LEFT JOIN agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze gem ON gru.bfs_nr = gem.bfs_gemeindenummer
    WHERE
     gru.bfs_nr = 2457 AND
     gru.art_txt = 'Liegenschaft'
     AND nutzzon.typ_kt IS NOT NULL
    GROUP BY gru.t_id, gru.t_ili_tid, gru.egrid, gru.nummer, gru.bfs_nr, gru.flaechenmass, gru.geometrie, gem.gemeindename
),
gr AS (
  SELECT
    gr.*,
    SUM(COALESCE(ST_Area(ST_Intersection(gr.geometrie,unbeb_fl.geometrie,0.001)),0))::NUMERIC AS flaeche_unbebaut,
    CASE
      WHEN flaeche - Round(ST_Area(gr.geometrie)) > 1 THEN 'beschnitten'
      ELSE 'original'
    END AS geometrieart_liegenschaft,
    Round(ST_Area(gr.geometrie)) AS flaeche_beschnitten
   FROM gr_tmp gr
     LEFT JOIN unbeb_fl ON ST_Intersects(gr.geometrie, unbeb_fl.geometrie)
    GROUP BY gr.t_id, gr.t_ili_tid, gr.egris_egrid, gr.nummer, gr.bfs_nr, gr.grundnutzung_typ_kt, gr.flaeche, gr.geometrie, gr.gemeindename
)
SELECT
   t_id,
   t_ili_tid,
   egris_egrid,
   nummer,
   bfs_nr,
   gemeindename,
   grundnutzung_typ_kt,
   flaeche,
   CASE
     WHEN flaeche_unbebaut = 0 THEN 'bebaut'
     ELSE
       CASE
         WHEN flaeche_unbebaut / flaeche_beschnitten >= 0.55 AND flaeche_unbebaut >= 180 THEN 'unbebaut'
         ELSE
           CASE
             WHEN flaeche_unbebaut / flaeche_beschnitten < 0.55 AND flaeche_unbebaut / flaeche_beschnitten > 0.10 AND flaeche_unbebaut >= 180 THEN 'teilweise_bebaut'
             ELSE 'bebaut'
           END
       END
   END AS bebauungsstand,
   geometrie,
   geometrieart_liegenschaft,
   flaeche_beschnitten,
   flaeche_unbebaut
 FROM gr
   -- um Artefakte wegzufiltern
   WHERE flaeche_beschnitten > 10
;
